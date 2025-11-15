import sublime
import json
import os
import threading
import time
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from .settings import log, get_ai_service_config


class NeoaiAIClient:
    """Client for communicating with Neoai AI service"""
    
    def __init__(self):
        self.config = get_ai_service_config()
        self.endpoint = self.config.get("endpoint", "https://api.neoai.com/v1/complete")
        self.api_key = self.config.get("api_key", "")
        self.model = self.config.get("model", "neoai-code-complete")
        self.max_tokens = self.config.get("max_tokens", 100)
        self.temperature = self.config.get("temperature", 0.1)
        self.timeout = self.config.get("timeout", 5.0)
        
    def get_completions(self, context, callback=None):
        """Get completions from AI service"""
        if not self.api_key:
            log("No API key configured for Neoai AI service", "warning")
            return []
            
        # Prepare request payload
        payload = {
            "model": self.model,
            "prompt": self._build_prompt(context),
            "max_tokens": self.max_tokens,
            "temperature": self.temperature,
            "language": context.get("language", ""),
            "context": context
        }
        
        if callback:
            # Async request
            threading.Thread(
                target=self._make_request_async,
                args=(payload, callback),
                daemon=True
            ).start()
        else:
            # Sync request
            return self._make_request_sync(payload)
            
    def _build_prompt(self, context):
        """Build prompt from context"""
        prefix = context.get("prefix", "")
        suffix = context.get("suffix", "")
        language = context.get("language", "")
        current_line = context.get("current_line", "")
        
        # Build context-aware prompt
        prompt_parts = []
        
        if language:
            prompt_parts.append(f"Language: {language}")
            
        if context.get("previous_lines"):
            prompt_parts.extend(context["previous_lines"])
            
        prompt_parts.append(current_line)
        
        return "\n".join(prompt_parts)
        
    def _make_request_async(self, payload, callback):
        """Make async request to AI service"""
        try:
            completions = self._make_request_sync(payload)
            # Run callback on main thread
            sublime.set_timeout(lambda: callback(completions), 0)
        except Exception as e:
            log(f"Async request failed: {str(e)}", "error")
            sublime.set_timeout(lambda: callback([]), 0)
            
    def _make_request_sync(self, payload):
        """Make sync request to AI service"""
        try:
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}",
                "User-Agent": "NeoAI-Sublime/1.0"
            }
            
            data = json.dumps(payload).encode("utf-8")
            request = Request(self.endpoint, data=data, headers=headers, method="POST")
            
            log(f"Making request to {self.endpoint}")
            
            with urlopen(request, timeout=self.timeout) as response:
                if response.status == 200:
                    response_data = json.loads(response.read().decode("utf-8"))
                    return self._parse_response(response_data)
                else:
                    log(f"Request failed with status {response.status}", "error")
                    return []
                    
        except (URLError, HTTPError) as e:
            log(f"Network error: {str(e)}", "error")
            return []
        except json.JSONDecodeError as e:
            log(f"JSON decode error: {str(e)}", "error")
            return []
        except Exception as e:
            log(f"Unexpected error: {str(e)}", "error")
            return []
            
    def _parse_response(self, response_data):
        """Parse AI service response"""
        completions = []
        
        # Handle different response formats
        if "completions" in response_data:
            for comp in response_data["completions"]:
                completions.append({
                    "completion": comp.get("text", ""),
                    "description": comp.get("description", ""),
                    "confidence": comp.get("confidence", 0.0)
                })
        elif "choices" in response_data:
            # OpenAI-like format
            for choice in response_data["choices"]:
                text = choice.get("text", "")
                if text:
                    completions.append({
                        "completion": text,
                        "description": "",
                        "confidence": 0.0
                    })
        elif isinstance(response_data, list):
            # Direct list format
            for item in response_data:
                if isinstance(item, str):
                    completions.append({
                        "completion": item,
                        "description": "",
                        "confidence": 0.0
                    })
                elif isinstance(item, dict):
                    completions.append({
                        "completion": item.get("completion", item.get("text", "")),
                        "description": item.get("description", ""),
                        "confidence": item.get("confidence", 0.0)
                    })
                    
        return completions


def get_capabilities():
    """Get plugin capabilities"""
    return {
        "enabled_features": [
            "sublime.new-experience",
            "inline-completions",
            "multi-language-support"
        ],
        "supported_languages": [
            "javascript", "python", "typescript", "php", "c", "cpp",
            "html", "css", "go", "java", "ruby", "csharp", "rust",
            "sql", "bash", "kotlin", "julia", "lua", "ocaml", "perl",
            "haskell", "react"
        ],
        "version": "1.0.0"
    }


def set_state(state_data):
    """Set plugin state"""
    # This would communicate with the Neoai backend
    log(f"Setting state: {state_data}")
    pass


def open_config():
    """Open configuration file"""
    config_path = os.path.join(sublime.packages_path(), "User", "NeoAi.sublime-settings")
    sublime.active_window().open_file(config_path)
