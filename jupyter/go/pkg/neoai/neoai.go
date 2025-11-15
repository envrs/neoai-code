package neoai

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"

	"github.com/coreos/go-semver/semver"
)

type NeoAi struct {
	baseDir       string
	cmd           *exec.Cmd
	outReader     *bufio.Reader
	mux           sync.Mutex
	inPipeWriter  *io.PipeWriter
	outPipeWriter *io.PipeWriter
	inPipeReader  *io.PipeReader
	outPipeReader *io.PipeReader
	completeRes   *AutocompleteResult
	emptyRes      []byte
}

type AutocompleteResult struct {
	OldPrefix   string         `json:"old_prefix"`
	Results     []*ResultEntry `json:"results"`
	UserMessage []string       `json:"user_message"`
}

type ResultEntry struct {
	NewPrefix string `json:"new_prefix"`
	OldSuffix string `json:"old_suffix"`
	NewSuffix string `json:"new_suffix"`
	Details   string `json:"detail"`
}

const (
	updateUrlBase = "https://update.neoai.com"
)

var systemMap = map[string]string{
	"darwin":  "apple-darwin",
	"linux":   "unknown-linux-gnu",
	"windows": "pc-windows-gnu",
}

func NewNeoAi(baseDir string) (*NeoAi, error) {
	empty := AutocompleteResult{}
	emptyRes, _ := json.Marshal(empty)
	neoai := &NeoAi{
		baseDir:     baseDir,
		completeRes: &empty,
		emptyRes:    emptyRes,
	}
	err := neoai.init()
	return neoai, err
}

func (t *NeoAi) init() (err error) {
	log.Println("NeoAi Initializing")
	// download if needed
	var binaryPath string
	var wg sync.WaitGroup
	wg.Add(1)
	go func(wg *sync.WaitGroup) {
		defer wg.Done()
		binaryPath, err = t.getBinaryPath()
	}(&wg)
	t.inPipeReader, t.inPipeWriter = io.Pipe()
	t.outPipeReader, t.outPipeWriter = io.Pipe()
	wg.Wait()
	if err == nil {
		t.cmd = exec.Command(binaryPath, "--client=jupyter-server")
		t.cmd.Stdin = t.inPipeReader
		t.cmd.Stdout = t.outPipeWriter
		t.outReader = bufio.NewReader(t.outPipeReader)
		err = t.cmd.Start()
	}
	log.Println("NeoAi Initialized")
	return
}

func (t *NeoAi) downloadAndVerifyBinary(url, binaryPath string) (err error) {
	// Create directory if it doesn't exist
	binaryDir := filepath.Dir(binaryPath)
	if err = os.MkdirAll(binaryDir, os.ModePerm); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", binaryDir, err)
	}

	// 1. Download checksum
	checksumUrl := url + ".sha256"
	var expectedChecksum string
	resp, err := http.Get(checksumUrl)
	if err != nil {
		log.Printf("Could not download checksum from %s: %v. Proceeding without verification.", checksumUrl, err)
	} else {
		defer resp.Body.Close()
		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			body, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				log.Printf("Could not read checksum body: %v. Proceeding without verification.", err)
			} else {
				expectedChecksum = strings.TrimSpace(string(body))
			}
		}
	}

	// 2. Download binary to a temp file
	resp, err = http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to download binary from %s: %w", url, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return fmt.Errorf("download request failed with status: %s", resp.Status)
	}

	tmpFile, err := ioutil.TempFile("", "neoai-binary-")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tmpFile.Name())

	hasher := sha256.New()
	// Download and write to file, while also calculating the hash
	if _, err := io.Copy(io.MultiWriter(tmpFile, hasher), resp.Body); err != nil {
		tmpFile.Close()
		return fmt.Errorf("failed to write to temp file: %w", err)
	}
	tmpFile.Close()

	// 3. Verify checksum
	if expectedChecksum != "" {
		actualChecksum := hex.EncodeToString(hasher.Sum(nil))
		if !strings.EqualFold(actualChecksum, expectedChecksum) {
			return fmt.Errorf("checksum mismatch for %s. Expected %s, got %s", url, expectedChecksum, actualChecksum)
		}
		log.Println("Checksum verified.")
	}

	// 4. Move temp file to final destination
	if err := os.Rename(tmpFile.Name(), binaryPath); err != nil {
		return fmt.Errorf("failed to move binary to destination: %w", err)
	}

	return os.Chmod(binaryPath, 0755)
}

func (t *NeoAi) getBinaryPath() (string, error) {
	binaryDir := filepath.Join(t.baseDir, "binaries")
	if err := os.MkdirAll(binaryDir, os.ModePerm); err != nil {
		return "", fmt.Errorf("failed to create binary directory: %w", err)
	}

	dirs, err := ioutil.ReadDir(binaryDir)
	if err != nil {
		return "", fmt.Errorf("failed to read binary directory: %w", err)
	}

	var versions []*semver.Version
	for _, d := range dirs {
		if d.IsDir() {
			versions = append(versions, semver.New(d.Name()))
		}
	}
	semver.Sort(versions)

	arch := parseArch(runtime.GOARCH)
	sys := systemMap[strings.ToLower(runtime.GOOS)]
	exeName := "NeoAi"
	if strings.ToLower(runtime.GOOS) == "windows" {
		exeName += ".exe"
	}
	triple := fmt.Sprintf("%s-%s", arch, sys)

	// Check for existing binaries
	for i := len(versions) - 1; i >= 0; i-- {
		v := versions[i]
		binaryPath := filepath.Join(binaryDir, v.String(), triple, exeName)
		if isFile(binaryPath) {
			os.Chmod(binaryPath, 0755)
			return binaryPath, nil
		}
	}

	// Download if not found
	log.Println("Binary not found, starting download.")
	versionUrl := fmt.Sprintf("%s/bundles/version", updateUrlBase)
	resp, err := http.Get(versionUrl)
	if err != nil {
		return "", fmt.Errorf("failed to get latest version: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return "", fmt.Errorf("version request failed with status: %s", resp.Status)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read version response: %w", err)
	}

	latestVersion := strings.TrimSpace(string(body))
	log.Printf("Latest version: %s\n", latestVersion)

	subPath := filepath.Join(latestVersion, triple, exeName)
	binaryPath := filepath.Join(binaryDir, subPath)
	downloadUrl := fmt.Sprintf("%s/bundles/%s", updateUrlBase, subPath)

	log.Printf("Download url: %s, Binary path: %s", downloadUrl, binaryPath)
	if err := t.downloadAndVerifyBinary(downloadUrl, binaryPath); err != nil {
		return "", fmt.Errorf("download failed: %w", err)
	}

	log.Println("Download finished.")
	return binaryPath, nil
}

func (t *NeoAi) Request(data []byte) (res []byte) {
	t.mux.Lock()
	defer t.mux.Unlock()
	t.inPipeWriter.Write(data)
	t.inPipeWriter.Write([]byte("\n"))
	bytes, err := t.outReader.ReadBytes('\n')
	if err != nil {
		res = t.emptyRes
		return
	}
	// remove useless fields
	err = json.Unmarshal(bytes, t.completeRes)
	if err != nil {
		res = t.emptyRes
		return
	}
	res, err = json.Marshal(t.completeRes)
	return
}

func (t *NeoAi) Close() {
	log.Println("neoai closing... cleaning up...")
	if t.cmd != nil && t.cmd.Process != nil {
		t.cmd.Process.Kill()
	}
	t.inPipeWriter.Close()
	t.outPipeWriter.Close()
	t.inPipeReader.Close()
	t.outPipeReader.Close()
}

func isFile(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return !info.IsDir()
}

func parseArch(arch string) string {
	if strings.ToLower(arch) == "amd64" {
		return "x86_64"
	}
	return arch
}
