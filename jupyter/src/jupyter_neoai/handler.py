from tornado import web
from urllib.parse import unquote
from notebook.base.handlers import IPythonHandler


class NeoaiHandler(IPythonHandler):
    def initialize(self, neoai):
        self.neoai = neoai

    @web.authenticated
    async def get(self):
        url_params = self.request.uri
        request_data = unquote(url_params[url_params.index("=") + 1 :])
        response = self.neoai.request(request_data)
        if response:
            self.write(response)
