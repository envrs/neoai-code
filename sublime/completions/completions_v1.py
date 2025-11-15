import sublime
import sublime_plugin
import time
import threading
from typing import List, Dict, Any, Optional

from ..lib.settings import (
    get_language_setting, is_language_enabled, get_trigger_delay,
    get_debounce_delay, get_max_completions, is_auto_trigger_enabled,
    get_trigger_characters, log
)
from ..lib.requests import NeoaiAIClient


class NeoaiCompletionProvider:
    """Base completion provider for all languages"""
    
    def __init__(self, view):
        self.view = view
        self.client = NeoaiAIClient()
        self.last_request_time = 0
        self.completion_cache = {}
        
    def get_completions(self, prefix, locations):
        """Get completions for the current context"""
        if not locations:
            return []
            
        cursor_pos = locations[0]
        language = self._detect_language(cursor_pos)
        
        if not is_language_enabled(language):
            log(f"Language {language} is disabled", "info")
            return []
            
        # Check debounce
        current_time = time.time()
        if current_time - self.last_request_time < get_debounce_delay():
            return []
            
        self.last_request_time = current_time
        
        # Get context
        context = self._get_context(cursor_pos, language, prefix)
        
        # Get completions from AI service
        completions = self.client.get_completions(context)
        
        # Convert to Sublime format
        return self._convert_completions(completions, language)
        
    def _detect_language(self, cursor_pos):
        """Detect programming language from Sublime scope"""
        scope_name = self.view.scope_name(cursor_pos)
        
        language_mapping = {
            'source.python': 'python',
            'source.js': 'javascript',
            'source.ts': 'typescript',
            'source.tsx': 'typescript',
            'source.jsx': 'javascript',
            'source.php': 'php',
            'source.c': 'c',
            'source.c++': 'cpp',
            'source.cpp': 'cpp',
            'source.go': 'go',
            'source.java': 'java',
            'source.ruby': 'ruby',
            'source.cs': 'csharp',
            'source.rust': 'rust',
            'source.sql': 'sql',
            'source.shell': 'bash',
            'source.kotlin': 'kotlin',
            'source.julia': 'julia',
            'source.lua': 'lua',
            'source.ocaml': 'ocaml',
            'source.perl': 'perl',
            'source.haskell': 'haskell',
            'text.html.basic': 'html',
            'source.css': 'css',
            'text.html.scss': 'scss',
            'text.html.sass': 'sass',
            'text.xml': 'xml',
            'source.json': 'json'
        }
        
        for scope, lang in language_mapping.items():
            if scope in scope_name:
                return lang
                
        # Check for React/JSX specifically
        if 'jsx' in scope_name or 'react' in scope_name:
            return 'react'
                
        return 'text'
        
    def _get_context(self, cursor_pos, language, prefix):
        """Get context around the cursor"""
        # Get text before and after cursor
        prefix_text = self.view.substr(sublime.Region(0, cursor_pos))
        suffix = self.view.substr(sublime.Region(cursor_pos, self.view.size()))
        
        # Get current line
        line_region = self.view.line(cursor_pos)
        current_line = self.view.substr(line_region)
        
        # Get previous lines for context
        prev_lines = []
        for i in range(1, 10):  # Get up to 9 previous lines
            prev_line_region = self.view.line(line_region.begin() - i)
            if prev_line_region.begin() < 0:
                break
            prev_lines.insert(0, self.view.substr(prev_line_region))
            
        # Get next lines for context
        next_lines = []
        for i in range(1, 3):  # Get up to 2 next lines
            next_line_region = self.view.line(line_region.end() + i)
            if next_line_region.end() > self.view.size():
                break
            next_lines.append(self.view.substr(next_line_region))
            
        return {
            'language': language,
            'prefix': prefix_text,
            'suffix': suffix,
            'current_line': current_line,
            'previous_lines': prev_lines,
            'next_lines': next_lines,
            'file_path': self.view.file_name() or '',
            'cursor_position': cursor_pos,
            'trigger_prefix': prefix
        }
        
    def _convert_completions(self, completions, language):
        """Convert AI completions to Sublime format"""
        sublime_completions = []
        max_comps = get_max_completions()
        
        for i, comp in enumerate(completions[:max_comps]):
            completion_text = comp.get('completion', '')
            description = comp.get('description', '')
            confidence = comp.get('confidence', 0.0)
            
            if not completion_text:
                continue
                
            # Extract trigger text
            trigger = self._extract_trigger(completion_text, language)
            
            # Create completion item
            completion_item = sublime.CompletionItem(
                trigger=trigger,
                annotation=description[:50] if description else "",
                completion=completion_text,
                completion_format=sublime.COMPLETION_FORMAT_TEXT,
                kind=self._get_completion_kind(completion_text, language),
                details=description
            )
            
            sublime_completions.append(completion_item)
            
        return sublime_completions
        
    def _extract_trigger(self, completion, language):
        """Extract trigger text from completion"""
        # Simple extraction - take first word or first line
        lines = completion.split('\n')
        if lines:
            first_line = lines[0].strip()
            words = first_line.split()
            if words:
                return words[0]
                
        return completion[:20]
        
    def _get_completion_kind(self, completion, language):
        """Get completion kind based on content and language"""
        completion_lower = completion.lower()
        
        if 'function' in completion_lower or 'def ' in completion_lower or 'fn ' in completion_lower:
            return sublime.KIND_FUNCTION
        elif 'class' in completion_lower:
            return sublime.KIND_TYPE
        elif 'import' in completion_lower or 'include' in completion_lower:
            return sublime.KIND_NAMESPACE
        elif 'var ' in completion_lower or 'let ' in completion_lower or 'const ' in completion_lower:
            return sublime.KIND_VARIABLE
        else:
            return sublime.KIND_VARIABLE


class NeoaiEventListener(sublime_plugin.EventListener):
    """Event listener for triggering autocomplete"""
    
    def __init__(self):
        self.last_trigger_time = 0
        self.trigger_delay = get_trigger_delay()
        self.providers = {}
        
    def on_modified(self, view):
        """Trigger autocomplete when text is modified"""
        if not is_auto_trigger_enabled():
            return
            
        current_time = time.time()
        if current_time - self.last_trigger_time < self.trigger_delay:
            return
            
        self.last_trigger_time = current_time
        
        # Check if we should trigger completion
        if self._should_trigger_completion(view):
            # Trigger completion after a short delay
            sublime.set_timeout(lambda: self._trigger_completion(view), 100)
            
    def on_query_completions(self, view, prefix, locations):
        """Handle completion queries"""
        if not view or not locations:
            return []
            
        # Get or create provider for this view
        view_id = view.id()
        if view_id not in self.providers:
            self.providers[view_id] = NeoaiCompletionProvider(view)
            
        provider = self.providers[view_id]
        return provider.get_completions(prefix, locations)
        
    def _should_trigger_completion(self, view):
        """Determine if completion should be triggered"""
        # Get current character
        sel = view.sel()
        if not sel:
            return False
            
        cursor_pos = sel[0].begin()
        if cursor_pos == 0:
            return False
            
        # Get character before cursor
        prev_char = view.substr(cursor_pos - 1)
        
        # Check trigger characters
        trigger_chars = get_trigger_characters()
        return prev_char in trigger_chars
        
    def _trigger_completion(self, view):
        """Trigger completion manually"""
        view.run_command('auto_complete')


# Language-specific completion handlers
class PythonCompletionHandler(NeoaiCompletionProvider):
    """Python-specific completion handler"""
    
    def get_completions(self, prefix, locations):
        """Get Python-specific completions"""
        # Add Python-specific logic here
        return super().get_completions(prefix, locations)


class JavaScriptCompletionHandler(NeoaiCompletionProvider):
    """JavaScript-specific completion handler"""
    
    def get_completions(self, prefix, locations):
        """Get JavaScript-specific completions"""
        # Add JavaScript-specific logic here
        return super().get_completions(prefix, locations)


class TypeScriptCompletionHandler(NeoaiCompletionProvider):
    """TypeScript-specific completion handler"""
    
    def get_completions(self, prefix, locations):
        """Get TypeScript-specific completions"""
        # Add TypeScript-specific logic here
        return super().get_completions(prefix, locations)


# Register completion providers
def get_completion_handler(view):
    """Get appropriate completion handler for view"""
    cursor_pos = view.sel()[0].begin() if view.sel() else 0
    scope_name = view.scope_name(cursor_pos)
    
    if 'source.python' in scope_name:
        return PythonCompletionHandler(view)
    elif 'source.js' in scope_name:
        return JavaScriptCompletionHandler(view)
    elif 'source.ts' in scope_name:
        return TypeScriptCompletionHandler(view)
    else:
        return NeoaiCompletionProvider(view)
