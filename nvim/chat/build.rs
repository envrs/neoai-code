use std::env;
use std::fs;
use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=src/");
    println!("cargo:rerun-if-changed=assets/");
    println!("cargo:rerun-if-changed=index.html");
    
    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("build_info.rs");
    
    // Create build info
    let build_info = format!(
        r#"
/// Build timestamp
pub const BUILD_TIMESTAMP: &str = "{}";

/// Git commit hash (if available)
pub const GIT_HASH: &str = "{}";

/// Build profile (debug/release)
pub const BUILD_PROFILE: &str = "{}";
"#,
        chrono::Utc::now().to_rfc3339(),
        get_git_hash().unwrap_or_else(|| "unknown".to_string()),
        env::var("PROFILE").unwrap_or_else(|_| "unknown".to_string())
    );
    
    fs::write(&dest_path, build_info).unwrap();
    
    // Copy assets if they exist
    copy_assets();
    
    // Validate required files
    validate_files();
}

fn get_git_hash() -> Option<String> {
    use std::process::Command;
    Command::new("git")
        .args(&["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .and_then(|output| String::from_utf8(output.stdout).ok())
        .map(|s| s.trim().to_string())
}

fn copy_assets() {
    let assets_dir = Path::new("assets");
    let out_dir = Path::new(&env::var("OUT_DIR").unwrap());
    
    if assets_dir.exists() {
        println!("Copying assets from {:?}", assets_dir);
        // Copy all files from assets directory to output
        if let Ok(entries) = fs::read_dir(assets_dir) {
            for entry in entries.flatten() {
                let src_path = entry.path();
                let dest_path = out_dir.join(entry.file_name());
                if let Err(e) = fs::copy(&src_path, &dest_path) {
                    eprintln!("Warning: Failed to copy {:?}: {}", src_path, e);
                }
            }
        }
    }
}

fn validate_files() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let manifest_path = Path::new(&manifest_dir);
    
    // Check for icon.png
    let icon_path = manifest_path.join("icon.png");
    if !icon_path.exists() {
        println!("Warning: icon.png not found, will use fallback icon");
    }
    
    // Check for index.html
    let html_path = manifest_path.join("index.html");
    if !html_path.exists() {
        panic!("index.html is required but not found");
    }
    
    // Check for assets directory
    let assets_path = manifest_path.join("assets");
    if !assets_path.exists() {
        println!("Warning: assets directory not found, creating it");
        let _ = fs::create_dir_all(&assets_path);
    }
}
