import sublime
import json
import os


def get_settings():
    """Get Neoai settings"""
    return sublime.load_settings("NeoAi.sublime-settings")


def is_native_auto_complete():
    """Check if native auto complete is enabled"""
    settings = get_settings()
    return settings.get("native_auto_complete", False)


def get_language_setting(language, key, default=None):
    """Get language-specific setting"""
    settings = get_settings()
    languages = settings.get("languages", {})
    lang_config = languages.get(language, {})
    return lang_config.get(key, default)


def is_language_enabled(language):
    """Check if language is enabled"""
    return get_language_setting(language, "enabled", True)


def get_trigger_delay():
    """Get trigger delay setting"""
    settings = get_settings()
    return settings.get("trigger_delay", 1.0)


def get_debounce_delay():
    """Get debounce delay setting"""
    settings = get_settings()
    return settings.get("debounce_delay", 0.5)


def get_max_completions():
    """Get max completions setting"""
    settings = get_settings()
    return settings.get("max_completions", 10)


def is_auto_trigger_enabled():
    """Check if auto trigger is enabled"""
    settings = get_settings()
    return settings.get("auto_trigger", True)


def get_trigger_characters():
    """Get trigger characters"""
    settings = get_settings()
    return settings.get("trigger_characters", [" ", ".", "(", "[", "{", "\n"])


def get_ai_service_config():
    """Get AI service configuration"""
    settings = get_settings()
    return settings.get("ai_service", {})


def is_debug_enabled():
    """Check if debug is enabled"""
    settings = get_settings()
    debug = settings.get("debug", {})
    return debug.get("enabled", False)


def get_log_level():
    """Get log level"""
    settings = get_settings()
    debug = settings.get("debug", {})
    return debug.get("log_level", "info")


def log(message, level="info"):
    """Log message if debug is enabled"""
    if is_debug_enabled():
        print(f"[NeoAI] {level.upper()}: {message}")
