# Assets Directory

This directory contains source and built assets for the NeoAI Chat application.

## Structure

- `src/` - Source HTML/CSS/JS files
- `dist/` - Built/bundled production files
- `icon.png` - Application icon (32x32 PNG)

## Build Process

1. Develop in `src/` directory with separate HTML/CSS/JS files
2. Build/bundle to `dist/` directory using your preferred build tool
3. Copy `dist/index.html` to root `index.html` for the Rust application

## Icon Generation

To convert the SVG to PNG:
```bash
# Using ImageMagick (if available)
convert icon.svg icon.png

# Using rsvg-convert (librsvg)
rsvg-convert icon.svg -o icon.png

# Or use any online SVG to PNG converter
```

The fallback icon in `src/icon.rs` will be used if `icon.png` is not found.
