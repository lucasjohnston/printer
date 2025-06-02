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
./correct_and_preview.sh -S image.jpg
./correct_and_preview.sh --skip --png --jpg

# Remove source files after successful processing
./correct_and_preview.sh -R image.jpg
./correct_and_preview.sh --rm-src --png --jpg

# Combine options
./correct_and_preview.sh -S -R --png --jpg --jpeg
```

## Options

- `-S, --skip`: Skip preview generation, only create print files
- `-R, --rm-src`: Remove source files after successful processing (only if all operations succeed)

## Output

For each input image, the script creates:
- `{filename}_FOR_PRINTING.jpg`: The color-corrected version to send to your printer
- `{filename}_PREVIEW_AFTER_CORRECTION.jpg`: A preview of how the print will look (unless `-S` is used)

## Requirements

- ImageMagick (`magick` command)
- Bash shell

## License

MIT License - see LICENSE file for details