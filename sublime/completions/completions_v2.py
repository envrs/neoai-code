import sublime
import sublime_plugin
import time
from typing import List, Dict, Any, Optional

from ..lib.settings import (
    get_language_setting, is_language_enabled, get_trigger_delay,
    get_debounce_delay, get_max_completions, is_auto_trigger_enabled,
    get_trigger_characters, log
)
from ..lib.requests import NeoaiAIClient


class NeoaiInlineCompletionProvider(sublime_plugin.InlineCompletionItemProvider):
    """Inline completion provider for Sublime Text 4118+"""
    
    def __init__(self):
        self.client = NeoaiAIClient()
        self.last_request_time = 0
        self.completion_cache = {}
        
    def on_query_inline_completions(self, view, position):
        """Handle inline completion queries"""
        if not is_auto_trigger_enabled():
            return []
            
        # Check debounce
        current_time = time.time()
        if current_time - self.last_request_time < get_debounce_delay():
            return []
            
        self.last_request_time = current_time
        
        # Detect language
        language = self._detect_language(view, position)
        
        if not is_language_enabled(language):
            log(f"Language {language} is disabled", "info")
            return []
            
        # Get context
        context = self._get_context(view, position, language)
        
        # Get completions from AI service
        completions = self.client.get_completions(context)
        
        # Convert to inline completion format
        return self._convert_inline_completions(completions, view, position)
        
    def _detect_language(self, view, position):
        """Detect programming language from Sublime scope"""
        scope_name = view.scope_name(position)
        
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
        
    def _get_context(self, view, position, language):
        """Get context around the cursor"""
        # Get text before and after cursor
        prefix = view.substr(sublime.Region(0, position))
        suffix = view.substr(sublime.Region(position, view.size()))
        
        # Get current line
        line_region = view.line(position)
        current_line = view.substr(line_region)
        
        # Get previous lines for context
        prev_lines = []
        for i in range(1, 10):  # Get up to 9 previous lines
            prev_line_region = view.line(line_region.begin() - i)
            if prev_line_region.begin() < 0:
                break
            prev_lines.insert(0, view.substr(prev_line_region))
            
        # Get next lines for context
        next_lines = []
        for i in range(1, 3):  # Get up to 2 next lines
            next_line_region = view.line(line_region.end() + i)
            if next_line_region.end() > view.size():
                break
            next_lines.append(view.substr(next_line_region))
            
        return {
            'language': language,
            'prefix': prefix,
            'suffix': suffix,
            'current_line': current_line,
            'previous_lines': prev_lines,
            'next_lines': next_lines,
            'file_path': view.file_name() or '',
            'cursor_position': position
        }
        
    def _convert_inline_completions(self, completions, view, position):
        """Convert AI completions to inline completion format"""
        inline_completions = []
        max_comps = get_max_completions()
        
        for i, comp in enumerate(completions[:max_comps]):
            completion_text = comp.get('completion', '')
            description = comp.get('description', '')
            
            if not completion_text:
                continue
                
            # Create inline completion item
            inline_item = sublime.InlineCompletionItem(
                completion=completion_text,
                annotation=description[:50] if description else "",
                kind=self._get_completion_kind(completion_text),
                details=description
            )
            
            inline_completions.append(inline_item)
            
        return inline_completions
        
    def _get_completion_kind(self, completion):
        """Get completion kind based on content"""
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


class NeoaiCompletionCommand(sublime_plugin.TextCommand):
    """Command to manually trigger Neoai completions"""
    
    def run(self, edit):
        """Trigger completion manually"""
        view = self.view
        position = view.sel()[0].begin()
        
        # Trigger inline completion
        if hasattr(view, 'show_inline_completions'):
            provider = NeoaiInlineCompletionProvider()
            completions = provider.on_query_inline_completions(view, position)
            if completions:
                view.show_inline_completions(completions)
        else:
            # Fallback to regular completion
            view.run_command('auto_complete')


class NeoaiEventListener(sublime_plugin.EventListener):
    """Event listener for Sublime Text v2 experience"""
    
    def __init__(self):
        self.last_trigger_time = 0
        self.trigger_delay = get_trigger_delay()
        self.inline_provider = NeoaiInlineCompletionProvider()
        
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
            sublime.set_timeout(lambda: self._trigger_inline_completion(view), 100)
            
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
        
    def _trigger_inline_completion(self, view):
        """Trigger inline completion"""
        if hasattr(view, 'show_inline_completions'):
            position = view.sel()[0].begin()
            completions = self.inline_provider.on_query_inline_completions(view, position)
            if completions:
                view.show_inline_completions(completions)
        else:
            # Fallback to regular completion
            view.run_command('auto_complete')


# Register the inline completion provider
def plugin_loaded():
    """Register inline completion provider when plugin loads"""
    if hasattr(sublime, 'register_inline_completion_item_provider'):
        provider = NeoaiInlineCompletionProvider()
        sublime.register_inline_completion_item_provider(provider, priority=1)
        log("Registered inline completion provider")
