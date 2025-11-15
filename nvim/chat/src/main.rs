mod icon;

use image::ImageFormat;
use once_cell::sync::Lazy;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::{
    env,
    fs::{canonicalize, read},
    io::{self, Write},
    path::PathBuf,
    thread,
};
use wry::application::window::{Icon, Window};
use wry::{
    application::{
        event::{Event, StartCause, WindowEvent},
        event_loop::{ControlFlow, EventLoop},
        window::WindowBuilder,
    },
    webview::WebViewBuilder,
};

#[derive(Deserialize, Serialize)]
#[serde(tag = "command", content = "data")]
enum Message {
    #[serde(rename = "focus")]
    Focus,
    #[serde(rename = "set_always_on_top")]
    SetOnTop(bool),
}

const WINDOW_TITLE: &str = "NeoAI Chat";

const BASE_URL: &str = "wry://localhost";

static INDEX_HTML: Lazy<String> = Lazy::new(|| {
    let manifest_dir = env!("CARGO_MANIFEST_DIR");
    let index_path = PathBuf::from(manifest_dir).join("index.html");
    
    match read(&index_path) {
        Ok(html_bytes) => {
            let html_string = String::from_utf8(html_bytes).unwrap_or_else(|_| {
                eprintln!("Warning: index.html is not valid UTF-8");
                "<html><body>Error: Invalid HTML encoding</body></html>".to_string()
            });
            
            Regex::new("(href|src)=\"/static")
                .unwrap_or_else(|_| {
                    eprintln!("Warning: Failed to create regex pattern");
                    Regex::new("").unwrap()
                })
                .replace_all(
                    &html_string,
                    format!("$1=\"{BASE_URL}/static"),
                )
                .to_string()
        }
        Err(e) => {
            eprintln!("Error: Failed to read index.html: {}", e);
            format!(
                r#"<html><body><h1>Error</h1><p>Failed to load index.html: {}</p></body></html>"#,
                e
            )
        }
    }
});

fn main() -> wry::Result<()> {
    // Enable devtools only in debug mode
    let enable_devtools = cfg!(debug_assertions);
    
    let event_loop = EventLoop::with_user_event();
    let window_builder = WindowBuilder::new()
        .with_title(WINDOW_TITLE)
        .with_window_icon(icon::APP_ICON.clone());
    
    let window = window_builder.build(&event_loop)?;
    let webview = WebViewBuilder::new(window)?
        .with_devtools(enable_devtools)
        .with_clipboard(true)
        .with_custom_protocol("wry".into(), |request| {
            let path = request.uri().path();
            
            // Security: Validate path to prevent directory traversal
            if path.contains("..") || path.contains('\0') {
                return wry::http::Response::builder()
                    .status(400)
                    .header(wry::http::header::CONTENT_TYPE, "text/plain")
                    .body("Bad Request".into())
                    .map_err(Into::into);
            }
            
            // Read the file content from file path
            let content = if path == "/" {
                INDEX_HTML.as_bytes().into()
            } else {
                let file_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                    .join(&path[1..]);
                
                match canonicalize(&file_path) {
                    Ok(canonical_path) if canonical_path.starts_with(env!("CARGO_MANIFEST_DIR")) => {
                        match read(&canonical_path) {
                            Ok(content_bytes) => content_bytes.into(),
                            Err(e) => {
                                eprintln!("Error reading file {:?}: {}", canonical_path, e);
                                return wry::http::Response::builder()
                                    .status(404)
                                    .header(wry::http::header::CONTENT_TYPE, "text/html")
                                    .body(format!("<h1>404</h1><p>File not found: {}</p>", e).into())
                                    .map_err(Into::into);
                            }
                        }
                    }
                    _ => {
                        return wry::http::Response::builder()
                            .status(403)
                            .header(wry::http::header::CONTENT_TYPE, "text/plain")
                            .body("Forbidden".into())
                            .map_err(Into::into);
                    }
                }
            };

            let mimetype = if path.ends_with(".html") || path == "/" {
                "text/html"
            } else if path.ends_with(".js") {
                "text/javascript"
            } else if path.ends_with(".css") {
                "text/css"
            } else if path.ends_with(".json") {
                "application/json"
            } else if path.ends_with(".png") {
                "image/png"
            } else if path.ends_with(".svg") {
                "image/svg+xml"
            } else {
                "application/octet-stream"
            };

            wry::http::Response::builder()
                .header(wry::http::header::CONTENT_TYPE, mimetype)
                .body(content)
                .map_err(Into::into)
        })
        .with_ipc_handler(move |_window: &Window, req: String| {
            let mut lock = io::stdout().lock();
            let _ = writeln!(lock, "{req}");
        })
        .with_url(BASE_URL)?
        .build()?;

    let proxy = event_loop.create_proxy();
    thread::spawn(move || loop {
        let mut buffer = String::new();
        io::stdin().read_line(&mut buffer).unwrap();
        let _ = proxy.send_event(buffer);
    });

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => (),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            Event::UserEvent(message) => match serde_json::from_str::<Message>(&message) {
                Ok(Message::Focus) => {
                    webview.window().set_focus();
                    if env::consts::OS == "linux" {
                        let _ = std::process::Command::new("wmctrl")
                            .args(["-a", WINDOW_TITLE])
                            .output();
                    }
                }
                Ok(Message::SetOnTop(on_top)) => {
                    webview.window().set_always_on_top(on_top);
                }
                _ => {
                    let _ =
                        webview.evaluate_script(&format!("window.postMessage({message},\"*\")"));
                }
            },
            _ => (),
        }
    });
}