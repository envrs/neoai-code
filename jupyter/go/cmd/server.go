package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/neopilot-ai/neoai-code/jupyter/go/pkg/neoai"
)

func main() {
	var libBaseDir string

	var port int

	flag.StringVar(&libBaseDir, "libBaseDir", "./", "base directory of neoai binaries")
	flag.IntVar(&port, "port", 9999, "Server port")
	flag.Parse()

	tn, err := neoai.NewNeoAi(libBaseDir)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/neoai", func(w http.ResponseWriter, r *http.Request) {
		// fix cross-domain request problem
		w.Header().Set("Access-Control-Allow-Origin", "*")
		urlStr, _ := url.QueryUnescape(r.URL.String())
		index := strings.Index(urlStr, "=")
		data := []byte(urlStr[index+1:])
		_, err = w.Write(tn.Request(data))
	})

	numSignals := 3
	ch := make(chan os.Signal, numSignals)

	signal.Notify(ch, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	go func() {
		signalType := <-ch
		signal.Stop(ch)
		tn.Close()
		log.Printf("Signal Type: %s\n", signalType)
		os.Exit(0)
	}()
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
}
