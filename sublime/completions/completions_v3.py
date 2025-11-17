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


class NeoaiAsyncCompletionProvider(sublime_plugin.AsyncCompletionProvider):
    """Async completion provider for Sublime Text 4000+"""
    
    def __init__(self):
        self.client = NeoaiAIClient()
        self.last_request_time = 0
        self.completion_cache = {}
        
    def on_query_completions_async(self, view, prefix, locations, on_done):
        """Handle async completion queries"""
        if not locations:
            on_done([])
            return
            
        position = locations[0]
        
        # Check debounce
        current_time = time.time()
        if current_time - self.last_request_time < get_debounce_delay():
            on_done([])
            return
            
        self.last_request_time = current_time
        
        # Detect language
        language = self._detect_language(view, position)
        
        if not is_language_enabled(language):
            log(f"Language {language} is disabled", "info")
            on_done([])
            return
            
        # Get context
        context = self._get_context(view, position, language, prefix)
        
        # Get completions from AI service asynchronously
        self.client.get_completions(
            context,
            callback=lambda completions: on_done(self._convert_completions(completions, language))
        )
        
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
        
    def _get_context(self, view, position, language, prefix):
        """Get context around the cursor"""
        # Get text before and after cursor
        prefix_text = view.substr(sublime.Region(0, position))
        suffix = view.substr(sublime.Region(position, view.size()))
        
        # Get current line
        line_region = view.line(position)
        current_line = view.substr(line_region)
        
        # Get previous lines for context
        prev_lines = []
        for i in range(1, 15):  # Get up to 14 previous lines for better context
            prev_line_region = view.line(line_region.begin() - i)
            if prev_line_region.begin() < 0:
                break
            prev_lines.insert(0, view.substr(prev_line_region))
            
        # Get next lines for context
        next_lines = []
        for i in range(1, 5):  # Get up to 4 next lines
            next_line_region = view.line(line_region.end() + i)
            if next_line_region.end() > view.size():
                break
            next_lines.append(view.substr(next_line_region))
            
        return {
            'language': language,
            'prefix': prefix_text,
            'suffix': suffix,
            'current_line': current_line,
            'previous_lines': prev_lines,
            'next_lines': next_lines,
            'file_path': view.file_name() or '',
            'cursor_position': position,
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
            
            # Create completion item with enhanced features
            completion_item = sublime.CompletionItem(
                trigger=trigger,
                annotation=description[:30] if description else "",
                completion=completion_text,
                completion_format=sublime.COMPLETION_FORMAT_TEXT,
                kind=self._get_completion_kind(completion_text, language),
                details=description,
                completion_type=sublime.COMPLETION_TYPE_SNIPPET if '$' in completion_text else sublime.COMPLETION_TYPE_TEXT
            )
            
            sublime_completions.append(completion_item)
            
        return sublime_completions
        
    def _extract_trigger(self, completion, language):
        """Extract trigger text from completion"""
        # Language-specific extraction
        if language == 'python':
            if 'def ' in completion:
                return completion.split('def ')[1].split('(')[0]
            elif 'class ' in completion:
                return completion.split('class ')[1].split(':')[0].split('(')[0]
            elif 'import ' in completion:
                return completion.split('import ')[1].split()[0]
        elif language in ['javascript', 'typescript']:
            if 'function ' in completion:
                return completion.split('function ')[1].split('(')[0]
            elif 'const ' in completion:
                return completion.split('const ')[1].split('=')[0].strip()
            elif 'let ' in completion:
                return completion.split('let ')[1].split('=')[0].strip()
        elif language == 'java':
            if 'class ' in completion:
                return completion.split('class ')[1].split('{')[0].strip()
            elif 'public ' in completion and 'void' in completion:
                return completion.split('public ')[1].split('(')[0].split()[-1]
                
        # Default extraction
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
        
        # Function detection
        if any(keyword in completion_lower for keyword in ['function', 'def ', 'fn ', 'func ']):
            return sublime.KIND_FUNCTION
        
        # Class/Type detection
        elif any(keyword in completion_lower for keyword in ['class ', 'interface ', 'type ', 'struct ']):
            return sublime.KIND_TYPE
            
        # Import/Module detection
        elif any(keyword in completion_lower for keyword in ['import ', 'include ', 'use ', 'require ']):
            return sublime.KIND_NAMESPACE
            
        # Variable detection
        elif any(keyword in completion_lower for keyword in ['var ', 'let ', 'const ', 'local ']):
            return sublime.KIND_VARIABLE
            
        # Control flow
        elif any(keyword in completion_lower for keyword in ['if ', 'for ', 'while ', 'switch ', 'match ']):
            return sublime.KIND_KEYWORD
            
        # Default
        else:
            return sublime.KIND_VARIABLE


class NeoaiInlineCompletionProvider(sublime_plugin.InlineCompletionItemProvider):
    """Enhanced inline completion provider for Sublime Text 4000+"""
    
    def __init__(self):
        self.client = NeoaiAIClient()
        self.last_request_time = 0
        self.completion_cache = {}
        
    def on_query_inline_completions(self, view, position):
        """Handle enhanced inline completion queries"""
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
        
        # Convert to inline completion format with enhanced features
        return self._convert_inline_completions(completions, view, position, language)
        
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
        """Get enhanced context around the cursor"""
        # Get text before and after cursor
        prefix = view.substr(sublime.Region(0, position))
        suffix = view.substr(sublime.Region(position, view.size()))
        
        # Get current line
        line_region = view.line(position)
        current_line = view.substr(line_region)
        
        # Get previous lines for context
        prev_lines = []
        for i in range(1, 15):  # Get up to 14 previous lines
            prev_line_region = view.line(line_region.begin() - i)
            if prev_line_region.begin() < 0:
                break
            prev_lines.insert(0, view.substr(prev_line_region))
            
        # Get next lines for context
        next_lines = []
        for i in range(1, 5):  # Get up to 4 next lines
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
        
    def _convert_inline_completions(self, completions, view, position, language):
        """Convert AI completions to enhanced inline completion format"""
        inline_completions = []
        max_comps = get_max_completions()
        
        for i, comp in enumerate(completions[:max_comps]):
            completion_text = comp.get('completion', '')
            description = comp.get('description', '')
            confidence = comp.get('confidence', 0.0)
            
            if not completion_text:
                continue
                
            # Create enhanced inline completion item
            inline_item = sublime.InlineCompletionItem(
                completion=completion_text,
                annotation=description[:30] if description else "",
                kind=self._get_completion_kind(completion_text, language),
                details=description,
                priority=int(confidence * 100) if confidence else 50
            )
            
            inline_completions.append(inline_item)
            
        return inline_completions
        
    def _get_completion_kind(self, completion, language):
        """Get completion kind based on content and language"""
        completion_lower = completion.lower()
        
        # Function detection
        if any(keyword in completion_lower for keyword in ['function', 'def ', 'fn ', 'func ']):
            return sublime.KIND_FUNCTION
        
        # Class/Type detection
        elif any(keyword in completion_lower for keyword in ['class ', 'interface ', 'type ', 'struct ']):
            return sublime.KIND_TYPE
            
        # Import/Module detection
        elif any(keyword in completion_lower for keyword in ['import ', 'include ', 'use ', 'require ']):
            return sublime.KIND_NAMESPACE
            
        # Variable detection
        elif any(keyword in completion_lower for keyword in ['var ', 'let ', 'const ', 'local ']):
            return sublime.KIND_VARIABLE
            
        # Control flow
        elif any(keyword in completion_lower for keyword in ['if ', 'for ', 'while ', 'switch ', 'match ']):
            return sublime.KIND_KEYWORD
            
        # Default
        else:
            return sublime.KIND_VARIABLE


class NeoaiEventListener(sublime_plugin.EventListener):
    """Enhanced event listener for Sublime Text 4000+"""
    
    def __init__(self):
        self.last_trigger_time = 0
        self.trigger_delay = get_trigger_delay()
        self.async_provider = NeoaiAsyncCompletionProvider()
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
            sublime.set_timeout(lambda: self._trigger_completion(view), 100)
            
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
        """Trigger appropriate completion based on Sublime version"""
        position = view.sel()[0].begin()
        
        # Try inline completion first
        if hasattr(view, 'show_inline_completions'):
            completions = self.inline_provider.on_query_inline_completions(view, position)
            if completions:
                view.show_inline_completions(completions)
                return
                
        # Fallback to regular completion
        view.run_command('auto_complete')


# Register providers when plugin loads
def plugin_loaded():
    """Register completion providers when plugin loads"""
    if hasattr(sublime, 'register_async_completion_provider'):
        provider = NeoaiAsyncCompletionProvider()
        sublime.register_async_completion_provider(provider, priority=1)
        log("Registered async completion provider")
        
    if hasattr(sublime, 'register_inline_completion_item_provider'):
        inline_provider = NeoaiInlineCompletionProvider()
        sublime.register_inline_completion_item_provider(inline_provider, priority=1)
        log("Registered inline completion provider")
