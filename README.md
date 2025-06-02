# Printer Color Correction Script

A bash script to preview and adjust photos before printing, compensating for common printer color shifts.

## Overview

This script helps photographers and designers prepare images for printing by:
- Applying color corrections to compensate for typical printer behavior
- Generating preview images that simulate how the corrected images will appear when printed
- Supporting batch processing of multiple image files

## Usage

```bash
# Process a single image
./correct_and_preview.sh image.jpg

# Process multiple images by extension
./correct_and_preview.sh --png --jpg --jpeg

# Skip preview generation (only create print files)
./correct_and_preview.sh --skip-preview image.jpg
./correct_and_preview.sh --skip-preview --png --jpg

# Skip print file generation (only create preview files)
./correct_and_preview.sh --skip-print image.jpg
./correct_and_preview.sh --skip-print --png --jpg

# Remove source files after successful processing
./correct_and_preview.sh -R image.jpg
./correct_and_preview.sh --rm-src --png --jpg

# Process PNG files with transparency preservation
./correct_and_preview.sh --transparent image.png
./correct_and_preview.sh --transparent --png

# Combine options
./correct_and_preview.sh --skip-preview -R --png --jpg --jpeg
```

## Options

- `--skip-preview`: Skip preview generation, only create print files
- `--skip-print`: Skip print file generation, only create preview files
- `-R, --rm-src`: Remove source files after successful processing (only if all operations succeed)
- `--transparent`: Generate PNG output with alpha channel preservation (only works with PNG input files)

## Output

For each input image, the script creates:
- `{filename}_FOR_PRINTING.jpg`: The color-corrected version to send to your printer (unless `--skip-print` is used)
- `{filename}_PREVIEW_AFTER_CORRECTION.jpg`: A preview of how the print will look (unless `--skip-preview` is used)

When using `--transparent` with PNG files:
- `{filename}_FOR_PRINTING.png`: The color-corrected PNG with preserved alpha channel
- `{filename}_PREVIEW_AFTER_CORRECTION.png`: A preview PNG with preserved transparency

## Requirements

- ImageMagick (`magick` command)
- Bash shell

## License

MIT License - see LICENSE file for details