use image::ImageFormat;
use once_cell::sync::Lazy;
use std::path::PathBuf;
use wry::application::window::Icon;

pub static APP_ICON: Lazy<Option<Icon>> = Lazy::new(|| {
    // Try to load icon from file first
    if let Ok(icon_bytes) = std::fs::read(PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("icon.png")) {
        if let Ok(imagebuffer) = image::load_from_memory_with_format(&icon_bytes, ImageFormat::Png) {
            let rgba = imagebuffer.into_rgba8();
            let (width, height) = rgba.dimensions();
            if let Ok(icon) = Icon::from_rgba(rgba.into_raw(), width, height) {
                return Some(icon);
            }
        }
    }
    
    // Fallback: generate a simple colored icon
    generate_fallback_icon()
});

fn generate_fallback_icon() -> Option<Icon> {
    // Create a simple 32x32 purple icon as fallback
    let size = 32;
    let mut rgba = vec![0u8; (size * size * 4) as usize];
    
    for y in 0..size {
        for x in 0..size {
            let idx = ((y * size + x) * 4) as usize;
            // Purple color with some transparency
            rgba[idx] = 147;     // R
            rgba[idx + 1] = 51;  // G  
            rgba[idx + 2] = 255; // B
            rgba[idx + 3] = 200; // A
        }
    }
    
    Icon::from_rgba(rgba, size, size).ok()
}
