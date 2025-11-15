import json
import logging
import os
import platform
import subprocess
import stat
import threading
import zipfile
import notebook
import tempfile
import hashlib
from urllib.request import urlopen, urlretrieve
from urllib.error import HTTPError
from ._version import __version__

if platform.system() == "Windows":
    try:
        from colorama import init
        init(convert=True)
    except ImportError:
        logging.getLogger(__name__).warning(
            "colorama is not installed, please install it for colored logs on Windows."
        )

# It's better to let the application (Jupyter) configure logging.
# We'll just get the logger for this module.
logger = logging.getLogger(__name__)

_NEOAI_SERVER_URL = "https://update.neoai.com/bundles"
_NEOAI_EXECUTABLE = "NeoAi"


class Neoai:
    """
    A class to manage the NeoAi binary, including downloading, running,
    and communicating with it.
    """

    def __init__(self):
        self.name = "neoai"
        self._proc = None
        self._install_dir = os.path.dirname(os.path.realpath(__file__))
        self._binary_dir = os.path.join(self._install_dir, "binaries")
        logger.info(f"Neoai install dir: {self._install_dir}")
        self.download_if_needed()

    def request(self, data):
        """
        Sends a request to the NeoAi binary and returns the response.
        """
        proc = self._get_running_neoai()
        if proc is None:
            return None

        try:
            proc.stdin.write((data + "\n").encode("utf8"))
            proc.stdin.flush()
        except BrokenPipeError:
            logger.warning("Broken pipe, restarting Neoai process.")
            self._restart()
            return None

        output = proc.stdout.readline().decode("utf8")
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            logger.debug(f"Neoai output is corrupted: {output}")
            return None

    def _restart(self):
        """
        Restarts the NeoAi binary process.
        """
        if self._proc is not None:
            self._proc.terminate()
            self._proc = None

        path = get_neoai_path(self._binary_dir)
        if path is None:
            logger.error("No Neoai binary found.")
            return

        logger.info(f"Starting Neoai binary at: {path}")
        self._proc = subprocess.Popen(
            [
                path,
                "--client",
                "jupyter",
                "--log-file-path",
                os.path.join(self._install_dir, "neoai.log"),
                "--client-metadata",
                f"pluginVersion={__version__}",
                f"clientVersion={notebook.__version__}",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )

    def _get_running_neoai(self):
        """
        Returns a running instance of the NeoAi process, starting it if necessary.
        """
        if self._proc is None:
            self._restart()

        if self._proc is not None and self._proc.poll() is not None:
            logger.error(f"Neoai exited with code {self._proc.returncode}")
            self._restart()

        return self._proc

    def download_if_needed(self):
        """
        Checks if the NeoAi binary exists and downloads it if not.
        """
        neoai_path = get_neoai_path(self._binary_dir)
        if neoai_path and os.path.isfile(neoai_path):
            add_execute_permission(neoai_path)
            logger.info(f"Neoai binary already exists in {neoai_path}, skipping download.")
            self._sem_complete_on()
            return

        logger.info("Neoai binary not found, starting download.")
        self._download()

    def _download(self):
        """
        Downloads and extracts the NeoAi binary in a separate thread.
        """
        version = get_neoai_version()
        if not version:
            logger.error("Could not retrieve latest Neoai version.")
            return

        distro = get_distribution_name()
        download_url = f"{_NEOAI_SERVER_URL}/{version}/{distro}/{_NEOAI_EXECUTABLE}.zip"
        output_dir = os.path.join(self._binary_dir, version, distro)

        downloader = threading.Thread(
            target=self._download_and_extract, args=(download_url, output_dir)
        )
        downloader.start()

    def _download_and_extract(self, download_url, output_dir):
        """
        The actual download and extraction logic.
        """
        try:
            logger.info(f"Begin to download Neoai Binary from {download_url}")
            if not os.path.isdir(output_dir):
                os.makedirs(output_dir)

            # 1. Download checksum
            checksum_url = download_url + ".sha256"
            try:
                with urlopen(checksum_url) as response:
                    expected_checksum = response.read().decode("UTF-8").strip()
            except HTTPError as e:
                logger.warning(f"Could not download checksum file ({e}), proceeding without verification.")
                expected_checksum = None

            # 2. Download binary zip
            with tempfile.NamedTemporaryFile(delete=False) as tmp_zip:
                urlretrieve(download_url, tmp_zip.name)
                zip_path = tmp_zip.name

            # 3. Verify checksum
            if expected_checksum:
                sha256 = hashlib.sha256()
                with open(zip_path, "rb") as f:
                    for chunk in iter(lambda: f.read(4096), b""):
                        sha256.update(chunk)
                actual_checksum = sha256.hexdigest()

                if actual_checksum.lower() != expected_checksum.lower():
                    raise SecurityException(
                        f"Checksum mismatch for {download_url}. "
                        f"Expected {expected_checksum}, got {actual_checksum}."
                    )
                logger.info("Checksum verified.")

            # 4. Extract
            with zipfile.ZipFile(zip_path, "r") as zf:
                for member in zf.infolist():
                    # Prevent path traversal attacks
                    target_path = os.path.realpath(os.path.join(output_dir, member.filename))
                    if os.path.commonprefix([os.path.realpath(output_dir), target_path]) != os.path.realpath(output_dir):
                        raise SecurityException(f"Attempted path traversal in zip file: {member.filename}")

                    zf.extract(member, output_dir)
                    target_file = os.path.join(output_dir, member.filename)
                    add_execute_permission(target_file)

            logger.info(f"Finished downloading Neoai Binary to {output_dir}")
            self._sem_complete_on()
        except HTTPError as e:
            logger.error(f"Download failed: {e}")
        except (IOError, zipfile.BadZipFile) as e:
            logger.error(f"Failed to save or extract zip file: {e}")
        except SecurityException as e:
            logger.error(f"Security error: {e}")
        except Exception as e:
            logger.error(f"An unexpected error occurred during download: {e}")
        finally:
            if 'zip_path' in locals() and os.path.exists(zip_path):
                os.remove(zip_path)


    def _sem_complete_on(self):
        """
        Sends a semantic completion request to Neoai to warm it up.
        """
        sem_on_req_data = {
            "version": "1.0.7",
            "request": {
                "Autocomplete": {
                    "filename": "test.py",
                    "before": "neoai::sem",
                    "after": "",
                    "region_includes_beginning": True,
                    "region_includes_end": True,
                    "max_num_results": 10,
                }
            },
        }
        res = self.request(json.dumps(sem_on_req_data))
        try:
            if res and res.get("results"):
                logger.info(
                    f'{res["results"][0]["new_prefix"]}{res["results"][0]["new_suffix"]}'
                )
            else:
                logger.warning("Could not turn on semantic completion, response was empty or invalid.")
        except (IndexError, KeyError):
            logger.warning("Wrong response structure when turning on semantic completion.")


# --- Utility Functions ---

def get_neoai_version():
    """
    Fetches the latest Neoai version string from the update server.
    """
    version_url = f"{_NEOAI_SERVER_URL}/version"
    try:
        with urlopen(version_url) as response:
            return response.read().decode("UTF-8").strip()
    except HTTPError as e:
        logger.error(f"Failed to fetch Neoai version: {e}")
        return None


def get_distribution_name():
    """
    Determines the distribution name based on the OS and architecture.
    """
    arch_translations = {
        "arm64": "aarch64",
        "AMD64": "x86_64",
    }
    sysinfo = platform.uname()
    sys_architecture = arch_translations.get(sysinfo.machine, sysinfo.machine)

    system = sysinfo.system
    if system == "Windows":
        sys_platform = "pc-windows-gnu"
    elif system == "Darwin":
        sys_platform = "apple-darwin"
    elif system == "Linux":
        sys_platform = "unknown-linux-musl"
    elif system == "FreeBSD":
        sys_platform = "unknown-freebsd"
    else:
        raise RuntimeError(
            f"Platform '{system}' was not recognized as any of Windows, macOS, Linux, FreeBSD"
        )

    return f"{sys_architecture}-{sys_platform}"


def get_neoai_path(binary_dir):
    """
    Finds the path to the NeoAi executable in the binary directory.
    It searches for the latest version available.
    """
    if not os.path.isdir(binary_dir):
        return None

    distro = get_distribution_name()
    try:
        versions = [d for d in os.listdir(binary_dir) if os.path.isdir(os.path.join(binary_dir, d))]
    except OSError:
        return None

    versions.sort(key=parse_semver, reverse=True)

    for version in versions:
        path = os.path.join(
            binary_dir, version, distro, executable_name(_NEOAI_EXECUTABLE)
        )
        if os.path.isfile(path):
            return path
    return None


def parse_semver(s):
    """
    Parses a semantic version string into a list of integers for sorting.
    """
    try:
        return [int(x) for x in s.split(".")]
    except (ValueError, AttributeError):
        return []


def add_execute_permission(path):
    """
    Adds execute permission to a file.
    """
    try:
        st = os.stat(path)
        new_mode = st.st_mode | stat.S_IEXEC
        if new_mode != st.st_mode:
            os.chmod(path, new_mode)
    except OSError as e:
        logger.warning(f"Could not set execute permission on {path}: {e}")


def executable_name(name):
    """
    Returns the executable name with a '.exe' suffix on Windows.
    """
    if platform.system() == "Windows":
        return f"{name}.exe"
    return name

class SecurityException(Exception):
    """Custom exception for security-related errors."""
    pass
