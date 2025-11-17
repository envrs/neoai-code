import sublime
import sublime_plugin
import time
import re
from typing import List, Dict, Any, Optional, Tuple

from ..lib.settings import (
    get_language_setting, is_language_enabled, get_trigger_delay,
    get_debounce_delay, get_max_completions, is_auto_trigger_enabled,
    get_trigger_characters, log
)
from ..lib.requests import NeoaiAIClient


class NeoaiAdvancedCompletionProvider(sublime_plugin.AsyncCompletionProvider):
    """Advanced async completion provider with enhanced features"""
    
    def __init__(self):
        self.client = NeoaiAIClient()
        self.last_request_time = 0
        self.completion_cache = {}
        self.context_cache = {}
        
    def on_query_completions_async(self, view, prefix, locations, on_done):
        """Handle advanced async completion queries"""
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
        
        # Detect language with enhanced detection
        language = self._detect_language(view, position)
        
        if not is_language_enabled(language):
            log(f"Language {language} is disabled", "info")
            on_done([])
            return
            
        # Get enhanced context
        context = self._get_enhanced_context(view, position, language, prefix)
        
        # Get completions from AI service asynchronously
        self.client.get_completions(
            context,
            callback=lambda completions: on_done(self._convert_enhanced_completions(completions, language, view, position))
        )
        
    def _detect_language(self, view, position):
        """Enhanced language detection with multiple strategies"""
        scope_name = view.scope_name(position)
        file_name = view.file_name() or ""
        
        # Primary scope-based detection
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
            'source.json': 'json',
            'source.yaml': 'yaml',
            'source.toml': 'toml',
            'source.dockerfile': 'dockerfile',
            'source.cmake': 'cmake',
            'source.makefile': 'makefile'
        }
        
        for scope, lang in language_mapping.items():
            if scope in scope_name:
                return lang
                
        # Check for React/JSX specifically
        if 'jsx' in scope_name or 'react' in scope_name:
            return 'react'
            
        # File extension-based detection as fallback
        ext_mapping = {
            '.py': 'python',
            '.js': 'javascript',
            '.jsx': 'react',
            '.ts': 'typescript',
            '.tsx': 'typescript',
            '.php': 'php',
            '.c': 'c',
            '.cpp': 'cpp',
            '.cc': 'cpp',
            '.cxx': 'cpp',
            '.go': 'go',
            '.java': 'java',
            '.rb': 'ruby',
            '.cs': 'csharp',
            '.rs': 'rust',
            '.sql': 'sql',
            '.sh': 'bash',
            '.bash': 'bash',
            '.kt': 'kotlin',
            '.jl': 'julia',
            '.lua': 'lua',
            '.ml': 'ocaml',
            '.mli': 'ocaml',
            '.pl': 'perl',
            '.pm': 'perl',
            '.hs': 'haskell',
            '.lhs': 'haskell',
            '.html': 'html',
            '.htm': 'html',
            '.css': 'css',
            '.scss': 'scss',
            '.sass': 'sass',
            '.xml': 'xml',
            '.json': 'json',
            '.yaml': 'yaml',
            '.yml': 'yaml',
            '.toml': 'toml',
            '.dockerfile': 'dockerfile',
            'Dockerfile': 'dockerfile',
            'CMakeLists.txt': 'cmake',
            'Makefile': 'makefile'
        }
        
        for ext, lang in ext_mapping.items():
            if file_name.endswith(ext):
                return lang
                
        return 'text'
        
    def _get_enhanced_context(self, view, position, language, prefix):
        """Get enhanced context with more sophisticated analysis"""
        # Get text before and after cursor
        prefix_text = view.substr(sublime.Region(0, position))
        suffix = view.substr(sublime.Region(position, view.size()))
        
        # Get current line
        line_region = view.line(position)
        current_line = view.substr(line_region)
        
        # Get previous lines for context
        prev_lines = []
        for i in range(1, 20):  # Get up to 19 previous lines
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
            
        # Analyze code structure
        structure = self._analyze_code_structure(prev_lines + [current_line], language)
        
        return {
            'language': language,
            'prefix': prefix_text,
            'suffix': suffix,
            'current_line': current_line,
            'previous_lines': prev_lines,
            'next_lines': next_lines,
            'file_path': view.file_name() or '',
            'cursor_position': position,
            'trigger_prefix': prefix,
            'structure': structure,
            'indentation': self._get_indentation_level(current_line),
            'context_type': self._determine_context_type(current_line, language)
        }
        
    def _analyze_code_structure(self, lines, language):
        """Analyze code structure for better context"""
        structure = {
            'functions': [],
            'classes': [],
            'imports': [],
            'variables': [],
            'current_scope': 'global'
        }
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('//'):
                continue
                
            # Language-specific analysis
            if language == 'python':
                if line.startswith('def '):
                    structure['functions'].append(line[4:].split('(')[0].strip())
                elif line.startswith('class '):
                    structure['classes'].append(line[6:].split(':')[0].strip())
                elif line.startswith(('import ', 'from ')):
                    structure['imports'].append(line)
            elif language in ['javascript', 'typescript']:
                if 'function ' in line or '=> ' in line:
                    structure['functions'].append(self._extract_function_name(line))
                elif 'class ' in line:
                    structure['classes'].append(self._extract_class_name(line))
                elif line.startswith(('import ', 'const ', 'let ', 'var ')):
                    structure['imports'].append(line)
            elif language == 'java':
                if 'class ' in line:
                    structure['classes'].append(self._extract_class_name(line))
                elif 'public ' in line and ('(' in line and ')' in line):
                    structure['functions'].append(self._extract_function_name(line))
                    
        return structure
        
    def _extract_function_name(self, line):
        """Extract function name from line"""
        # Simple regex-based extraction
        match = re.search(r'(?:function\s+|(\w+)\s*=|(\w+)\s*\()', line)
        if match:
            for group in match.groups():
                if group:
                    return group.strip()
        return 'unknown'
        
    def _extract_class_name(self, line):
        """Extract class name from line"""
        match = re.search(r'class\s+(\w+)', line)
        if match:
            return match.group(1).strip()
        return 'unknown'
        
    def _get_indentation_level(self, line):
        """Get indentation level of current line"""
        leading_spaces = len(line) - len(line.lstrip())
        return leading_spaces
        
    def _determine_context_type(self, current_line, language):
        """Determine the type of context (function, class, etc.)"""
        line = current_line.strip()
        
        if language == 'python':
            if line.startswith('def '):
                return 'function_definition'
            elif line.startswith('class '):
                return 'class_definition'
            elif line.startswith(('import ', 'from ')):
                return 'import'
            elif '=' in line and not line.startswith('#'):
                return 'assignment'
        elif language in ['javascript', 'typescript']:
            if 'function ' in line:
                return 'function_definition'
            elif 'class ' in line:
                return 'class_definition'
            elif line.startswith(('import ', 'export ')):
                return 'import'
            elif '=' in line:
                return 'assignment'
                
        return 'general'
        
    def _convert_enhanced_completions(self, completions, language, view, position):
        """Convert AI completions to enhanced Sublime format"""
        sublime_completions = []
        max_comps = get_max_completions()
        
        for i, comp in enumerate(completions[:max_comps]):
            completion_text = comp.get('completion', '')
            description = comp.get('description', '')
            confidence = comp.get('confidence', 0.0)
            
            if not completion_text:
                continue
                
            # Enhanced trigger extraction
            trigger = self._extract_enhanced_trigger(completion_text, language)
            
            # Create enhanced completion item
            completion_item = sublime.CompletionItem(
                trigger=trigger,
                annotation=description[:30] if description else "",
                completion=completion_text,
                completion_format=sublime.COMPLETION_FORMAT_TEXT,
                kind=self._get_enhanced_completion_kind(completion_text, language),
                details=description,
                completion_type=self._get_completion_type(completion_text),
                priority=int(confidence * 100) if confidence else 50
            )
            
            sublime_completions.append(completion_item)
            
        return sublime_completions
        
    def _extract_enhanced_trigger(self, completion, language):
        """Enhanced trigger text extraction"""
        # Language-specific extraction with better patterns
        if language == 'python':
            patterns = [
                r'def\s+(\w+)\s*\(',
                r'class\s+(\w+)',
                r'import\s+(\w+)',
                r'from\s+\w+\s+import\s+(\w+)',
                r'(\w+)\s*=',
                r'self\.(\w+)'
            ]
        elif language in ['javascript', 'typescript']:
            patterns = [
                r'function\s+(\w+)\s*\(',
                r'const\s+(\w+)\s*=',
                r'let\s+(\w+)\s*=',
                r'var\s+(\w+)\s*=',
                r'class\s+(\w+)',
                r'import.*\s+from\s+.*?(\w+)',
                r'(\w+)\s*:'
            ]
        elif language == 'java':
            patterns = [
                r'class\s+(\w+)',
                r'public\s+\w+\s+(\w+)\s*\(',
                r'private\s+\w+\s+(\w+)\s*\(',
                r'(\w+)\s+\w+\s*=',
                r'(\w+)\s*\('
            ]
        else:
            patterns = [
                r'(\w+)\s*\(',
                r'(\w+)\s*=',
                r'(\w+)\s+',
                r'^(\w+)'
            ]
            
        for pattern in patterns:
            match = re.search(pattern, completion)
            if match:
                return match.group(1).strip()
                
        # Fallback extraction
        lines = completion.split('\n')
        if lines:
            first_line = lines[0].strip()
            words = first_line.split()
            if words:
                return words[0]
                
        return completion[:20]
        
    def _get_enhanced_completion_kind(self, completion, language):
        """Enhanced completion kind detection"""
        completion_lower = completion.lower()
        
        # Function detection with more patterns
        if any(keyword in completion_lower for keyword in [
            'function', 'def ', 'fn ', 'func ', 'method', 'constructor'
        ]):
            return sublime.KIND_FUNCTION
        
        # Class/Type detection
        elif any(keyword in completion_lower for keyword in [
            'class ', 'interface ', 'type ', 'struct ', 'enum ', 'trait '
        ]):
            return sublime.KIND_TYPE
            
        # Import/Module detection
        elif any(keyword in completion_lower for keyword in [
            'import ', 'include ', 'use ', 'require ', 'export '
        ]):
            return sublime.KIND_NAMESPACE
            
        # Variable detection
        elif any(keyword in completion_lower for keyword in [
            'var ', 'let ', 'const ', 'local ', 'static ', 'global '
        ]):
            return sublime.KIND_VARIABLE
            
        # Control flow
        elif any(keyword in completion_lower for keyword in [
            'if ', 'for ', 'while ', 'switch ', 'match ', 'case ', 'break ', 'continue '
        ]):
            return sublime.KIND_KEYWORD
            
        # Markup/Template
        elif any(keyword in completion_lower for keyword in [
            '<div', '<span', '<p>', '<h', '<section', '<article', '<nav'
        ]):
            return sublime.KIND_MARKUP
            
        # Snippet detection
        elif '$' in completion or '{' in completion and '}' in completion:
            return sublime.KIND_SNIPPET
            
        # Default
        else:
            return sublime.KIND_VARIABLE
            
    def _get_completion_type(self, completion):
        """Determine completion type based on content"""
        if '$' in completion or '${' in completion:
            return sublime.COMPLETION_TYPE_SNIPPET
        elif '\n' in completion:
            return sublime.COMPLETION_TYPE_TEXT
        else:
            return sublime.COMPLETION_TYPE_TEXT


class NeoaiAdvancedInlineProvider(sublime_plugin.InlineCompletionItemProvider):
    """Advanced inline completion provider with enhanced features"""
    
    def __init__(self):
        self.client = NeoaiAIClient()
        self.last_request_time = 0
        self.completion_cache = {}
        self.context_cache = {}
        
    def on_query_inline_completions(self, view, position):
        """Handle advanced inline completion queries"""
        if not is_auto_trigger_enabled():
            return []
            
        # Check debounce
        current_time = time.time()
        if current_time - self.last_request_time < get_debounce_delay():
            return []
            
        self.last_request_time = current_time
        
        # Detect language with enhanced detection
        language = self._detect_language(view, position)
        
        if not is_language_enabled(language):
            log(f"Language {language} is disabled", "info")
            return []
            
        # Get enhanced context
        context = self._get_enhanced_context(view, position, language)
        
        # Get completions from AI service
        completions = self.client.get_completions(context)
        
        # Convert to enhanced inline completion format
        return self._convert_enhanced_inline_completions(completions, view, position, language)
        
    def _detect_language(self, view, position):
        """Enhanced language detection (same as async provider)"""
        scope_name = view.scope_name(position)
        file_name = view.file_name() or ""
        
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
            'source.json': 'json',
            'source.yaml': 'yaml',
            'source.toml': 'toml',
            'source.dockerfile': 'dockerfile',
            'source.cmake': 'cmake',
            'source.makefile': 'makefile'
        }
        
        for scope, lang in language_mapping.items():
            if scope in scope_name:
                return lang
                
        if 'jsx' in scope_name or 'react' in scope_name:
            return 'react'
            
        # File extension-based detection
        ext_mapping = {
            '.py': 'python',
            '.js': 'javascript',
            '.jsx': 'react',
            '.ts': 'typescript',
            '.tsx': 'typescript',
            '.php': 'php',
            '.c': 'c',
            '.cpp': 'cpp',
            '.cc': 'cpp',
            '.cxx': 'cpp',
            '.go': 'go',
            '.java': 'java',
            '.rb': 'ruby',
            '.cs': 'csharp',
            '.rs': 'rust',
            '.sql': 'sql',
            '.sh': 'bash',
            '.bash': 'bash',
            '.kt': 'kotlin',
            '.jl': 'julia',
            '.lua': 'lua',
            '.ml': 'ocaml',
            '.mli': 'ocaml',
            '.pl': 'perl',
            '.pm': 'perl',
            '.hs': 'haskell',
            '.lhs': 'haskell',
            '.html': 'html',
            '.htm': 'html',
            '.css': 'css',
            '.scss': 'scss',
            '.sass': 'sass',
            '.xml': 'xml',
            '.json': 'json',
            '.yaml': 'yaml',
            '.yml': 'yaml',
            '.toml': 'toml',
            '.dockerfile': 'dockerfile',
            'Dockerfile': 'dockerfile',
            'CMakeLists.txt': 'cmake',
            'Makefile': 'makefile'
        }
        
        for ext, lang in ext_mapping.items():
            if file_name.endswith(ext):
                return lang
                
        return 'text'
        
    def _get_enhanced_context(self, view, position, language):
        """Get enhanced context (same as async provider)"""
        prefix_text = view.substr(sublime.Region(0, position))
        suffix = view.substr(sublime.Region(position, view.size()))
        
        line_region = view.line(position)
        current_line = view.substr(line_region)
        
        prev_lines = []
        for i in range(1, 20):
            prev_line_region = view.line(line_region.begin() - i)
            if prev_line_region.begin() < 0:
                break
            prev_lines.insert(0, view.substr(prev_line_region))
            
        next_lines = []
        for i in range(1, 5):
            next_line_region = view.line(line_region.end() + i)
            if next_line_region.end() > view.size():
                break
            next_lines.append(view.substr(next_line_region))
            
        structure = self._analyze_code_structure(prev_lines + [current_line], language)
        
        return {
            'language': language,
            'prefix': prefix_text,
            'suffix': suffix,
            'current_line': current_line,
            'previous_lines': prev_lines,
            'next_lines': next_lines,
            'file_path': view.file_name() or '',
            'cursor_position': position,
            'structure': structure,
            'indentation': self._get_indentation_level(current_line),
            'context_type': self._determine_context_type(current_line, language)
        }
        
    def _analyze_code_structure(self, lines, language):
        """Analyze code structure (same as async provider)"""
        structure = {
            'functions': [],
            'classes': [],
            'imports': [],
            'variables': [],
            'current_scope': 'global'
        }
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('//'):
                continue
                
            if language == 'python':
                if line.startswith('def '):
                    structure['functions'].append(line[4:].split('(')[0].strip())
                elif line.startswith('class '):
                    structure['classes'].append(line[6:].split(':')[0].strip())
                elif line.startswith(('import ', 'from ')):
                    structure['imports'].append(line)
            elif language in ['javascript', 'typescript']:
                if 'function ' in line or '=> ' in line:
                    structure['functions'].append(self._extract_function_name(line))
                elif 'class ' in line:
                    structure['classes'].append(self._extract_class_name(line))
                elif line.startswith(('import ', 'const ', 'let ', 'var ')):
                    structure['imports'].append(line)
            elif language == 'java':
                if 'class ' in line:
                    structure['classes'].append(self._extract_class_name(line))
                elif 'public ' in line and ('(' in line and ')' in line):
                    structure['functions'].append(self._extract_function_name(line))
                    
        return structure
        
    def _extract_function_name(self, line):
        """Extract function name from line"""
        match = re.search(r'(?:function\s+|(\w+)\s*=|(\w+)\s*\()', line)
        if match:
            for group in match.groups():
                if group:
                    return group.strip()
        return 'unknown'
        
    def _extract_class_name(self, line):
        """Extract class name from line"""
        match = re.search(r'class\s+(\w+)', line)
        if match:
            return match.group(1).strip()
        return 'unknown'
        
    def _get_indentation_level(self, line):
        """Get indentation level of current line"""
        leading_spaces = len(line) - len(line.lstrip())
        return leading_spaces
        
    def _determine_context_type(self, current_line, language):
        """Determine the type of context"""
        line = current_line.strip()
        
        if language == 'python':
            if line.startswith('def '):
                return 'function_definition'
            elif line.startswith('class '):
                return 'class_definition'
            elif line.startswith(('import ', 'from ')):
                return 'import'
            elif '=' in line and not line.startswith('#'):
                return 'assignment'
        elif language in ['javascript', 'typescript']:
            if 'function ' in line:
                return 'function_definition'
            elif 'class ' in line:
                return 'class_definition'
            elif line.startswith(('import ', 'export ')):
                return 'import'
            elif '=' in line:
                return 'assignment'
                
        return 'general'
        
    def _convert_enhanced_inline_completions(self, completions, view, position, language):
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
                kind=self._get_enhanced_completion_kind(completion_text, language),
                details=description,
                priority=int(confidence * 100) if confidence else 50
            )
            
            inline_completions.append(inline_item)
            
        return inline_completions
        
    def _get_enhanced_completion_kind(self, completion, language):
        """Enhanced completion kind detection (same as async provider)"""
        completion_lower = completion.lower()
        
        if any(keyword in completion_lower for keyword in [
            'function', 'def ', 'fn ', 'func ', 'method', 'constructor'
        ]):
            return sublime.KIND_FUNCTION
        elif any(keyword in completion_lower for keyword in [
            'class ', 'interface ', 'type ', 'struct ', 'enum ', 'trait '
        ]):
            return sublime.KIND_TYPE
        elif any(keyword in completion_lower for keyword in [
            'import ', 'include ', 'use ', 'require ', 'export '
        ]):
            return sublime.KIND_NAMESPACE
        elif any(keyword in completion_lower for keyword in [
            'var ', 'let ', 'const ', 'local ', 'static ', 'global '
        ]):
            return sublime.KIND_VARIABLE
        elif any(keyword in completion_lower for keyword in [
            'if ', 'for ', 'while ', 'switch ', 'match ', 'case ', 'break ', 'continue '
        ]):
            return sublime.KIND_KEYWORD
        elif any(keyword in completion_lower for keyword in [
            '<div', '<span', '<p>', '<h', '<section', '<article', '<nav'
        ]):
            return sublime.KIND_MARKUP
        elif '$' in completion or '{' in completion and '}' in completion:
            return sublime.KIND_SNIPPET
        else:
            return sublime.KIND_VARIABLE


class NeoaiAdvancedEventListener(sublime_plugin.EventListener):
    """Advanced event listener with enhanced features"""
    
    def __init__(self):
        self.last_trigger_time = 0
        self.trigger_delay = get_trigger_delay()
        self.async_provider = NeoaiAdvancedCompletionProvider()
        self.inline_provider = NeoaiAdvancedInlineProvider()
        
    def on_modified(self, view):
        """Enhanced modification handling"""
        if not is_auto_trigger_enabled():
            return
            
        current_time = time.time()
        if current_time - self.last_trigger_time < self.trigger_delay:
            return
            
        self.last_trigger_time = current_time
        
        # Enhanced trigger detection
        if self._should_trigger_completion(view):
            sublime.set_timeout(lambda: self._trigger_completion(view), 100)
            
    def _should_trigger_completion(self, view):
        """Enhanced trigger detection"""
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
        if prev_char in trigger_chars:
            return True
            
        # Additional context-based triggers
        line_region = view.line(cursor_pos)
        current_line = view.substr(line_region)
        
        # Trigger after certain keywords
        trigger_patterns = [
            r'\.$',  # After dot
            r'->$',  # After arrow
            r'::$',  # After scope resolution
            r'\s+$',  # After space (in some contexts)
        ]
        
        for pattern in trigger_patterns:
            if re.search(pattern, current_line[:cursor_pos - line_region.begin()]):
                return True
                
        return False
        
    def _trigger_completion(self, view):
        """Trigger appropriate completion"""
        position = view.sel()[0].begin()
        
        # Try inline completion first
        if hasattr(view, 'show_inline_completions'):
            completions = self.inline_provider.on_query_inline_completions(view, position)
            if completions:
                view.show_inline_completions(completions)
                return
                
        # Fallback to regular completion
        view.run_command('auto_complete')


# Register advanced providers when plugin loads
def plugin_loaded():
    """Register advanced completion providers when plugin loads"""
    if hasattr(sublime, 'register_async_completion_provider'):
        provider = NeoaiAdvancedCompletionProvider()
        sublime.register_async_completion_provider(provider, priority=1)
        log("Registered advanced async completion provider")
        
    if hasattr(sublime, 'register_inline_completion_item_provider'):
        inline_provider = NeoaiAdvancedInlineProvider()
        sublime.register_inline_completion_item_provider(inline_provider, priority=1)
        log("Registered advanced inline completion provider")
