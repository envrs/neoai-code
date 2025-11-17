Jupyter NeoAi
==========
This extension provides code auto-completion based on deep learning.

* Author: Md Sulaiman
* Repository: https://github.com/neopilot-ai/neoai-code/jupyter
* Email: dev.sulaiman@icloud.com

Options
-------

* `jupyterneoai.before_line_limit`:
   maximum number of lines before for context generation,
   too many lines will slow down the request. -1 means Infinity,
   thus the lines will equal to number of lines before current line.

* `jupyterneoai.after_line_limit`:
   maximum number of lines after for context generation,
   too many lines will slow down the request. -1 means Infinity,
   thus the lines will equal to number of lines after current line.

* `jupyterneoai.options_limit`:
   maximum number of options that will be shown

* `jupyterneoai.assist_active`:
   Enable continuous code auto-completion when notebook is first opened, or
   if false, only when selected from extensions menu.

* `jupyterneoai.assist_delay`:
   delay in milliseconds between keypress & completion request.

* `jupyter_neoai.remote_server_url`:
   remote server url, you may want to use a remote server to handle client request.
   This can spped up the request handling depending on the server configuration. Refer to https://github.com/neopilot-ai/neoai-code/jupyter to see how to deploy remote server.