from notebook.utils import url_path_join as ujoin
from .handler import NeoaiHandler
from .neoai import Neoai

# Jupyter Extension points
def _jupyter_server_extension_paths():
    return [{"module": "jupyter_neoai",}]


def _jupyter_nbextension_paths():
    return [
        {
            "section": "notebook",
            "dest": "jupyter_neoai",
            "src": "static",
            "require": "jupyter_neoai/main",
        }
    ]


def load_jupyter_server_extension(nb_server_app):
    """
    Called when the extension is loaded.

    Args:
        nb_server_app (NotebookWebApplication): handle to the Notebook webserver instance.
    """
    web_app = nb_server_app.web_app
    host_pattern = ".*$"
    route_pattern = ujoin(web_app.settings["base_url"], "/neoai")
    neoai = Neoai()
    web_app.add_handlers(
        host_pattern, [(route_pattern, NeoaiHandler, {"neoai": neoai})]
    )
