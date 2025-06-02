#!/bin/bash
# correct_and_preview.sh - Adjusted for better color vibrancy

# Global variable for skip preview mode
SKIP_PREVIEW=false
# Global variable for skip print mode
SKIP_PRINT=false
# Global variable for remove source files mode
RM_SOURCE=false
# Global variable for transparent PNG mode
TRANSPARENT=false
# Array to track successfully processed files
PROCESSED_FILES=()

# Function to process a single image
process_image() {
  local INPUT="$1"
  local BASE="${INPUT%.*}"
  local EXT="jpg"
  
  # Use PNG extension if transparent mode is enabled
  if [ "$TRANSPARENT" = true ]; then
    EXT="png"
  fi
  
  echo "Processing: $INPUT"
  
  # Step 1: Create corrected image (preserve purples and warm tones)
  if [ "$TRANSPARENT" = true ]; then
    # For transparent mode, apply color corrections only to non-transparent pixels
    magick "$INPUT" \
      \( +clone -alpha extract \) \
      \( -clone 0 -alpha off \
         -channel G -evaluate multiply 0.80 +channel \
         -channel R -evaluate multiply 1.01 +channel \
         -channel B -evaluate multiply 0.97 +channel \
         -modulate 98,94,104 \
         -brightness-contrast -3x-11 \
         -level 0%,101%,1.04 \) \
      -delete 0 \
      -swap 0,1 \
      -compose Copy_Opacity -composite \
      -define png:color-type=6 \
      "${BASE}_FOR_PRINTING.${EXT}"
  else
    # Standard JPEG output
    magick "$INPUT" \
      -channel G -evaluate multiply 0.80 +channel \
      -channel R -evaluate multiply 1.01 +channel \
      -channel B -evaluate multiply 0.97 +channel \
      -modulate 98,94,104 \
      -brightness-contrast -3x-11 \
      -level 0%,101%,1.04 \
      "${BASE}_FOR_PRINTING.${EXT}"
  fi
  
  # Check if the first magick command was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create corrected image for $INPUT"
    return 1
  fi
  
  if [ "$SKIP_PREVIEW" = false ]; then
    # Step 2: Simulate how the corrected image will print
    if [ "$TRANSPARENT" = true ]; then
      # For transparent mode, apply preview corrections only to non-transparent pixels
      magick "${BASE}_FOR_PRINTING.${EXT}" \
        \( +clone -alpha extract \) \
        \( -clone 0 -alpha off \
           -channel G -evaluate multiply 1.215 +channel \
           -channel R -evaluate multiply 0.945 +channel \
           -channel B -evaluate multiply 1.08 +channel \
           -modulate 101,116,93 \
           -brightness-contrast 2x12 \
           -level 0%,96%,0.94 \) \
        -delete 0 \
        -swap 0,1 \
        -compose Copy_Opacity -composite \
        -define png:color-type=6 \
        "${BASE}_PREVIEW_AFTER_CORRECTION.${EXT}"
    else
      # Standard JPEG preview
      magick "${BASE}_FOR_PRINTING.${EXT}" \
        -channel G -evaluate multiply 1.215 +channel \
        -channel R -evaluate multiply 0.945 +channel \
        -channel B -evaluate multiply 1.08 +channel \
        -modulate 101,116,93 \
        -brightness-contrast 2x12 \
        -level 0%,96%,0.94 \
        "${BASE}_PREVIEW_AFTER_CORRECTION.${EXT}"
    fi
    
    # Check if the second magick command was successful
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create preview image for $INPUT"
      return 1
    fi
    
    echo "Created:"
    echo "  ${BASE}_FOR_PRINTING.${EXT} - Send THIS to your printer"
    echo "  ${BASE}_PREVIEW_AFTER_CORRECTION.${EXT} - Preview of final print"
  else
    echo "Created:"
    echo "  ${BASE}_FOR_PRINTING.${EXT} - Send THIS to your printer"
  fi
  echo ""
  
  # If we got here, processing was successful
  PROCESSED_FILES+=("$INPUT")
  return 0
}


# Check if arguments are provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 [options] <image_file> or $0 [options] --<extension> [--<extension>...]"
  echo "Options:"
  echo "  --skip-preview  Skip preview generation, only create print files"
  echo "  --skip-print    Skip print generation, only create preview files"
  echo "  -R, --rm-src    Remove source files after successful processing"
  echo "  --transparent   Generate PNG output with alpha channel (only works with PNG input)"
  echo "Examples:"
  echo "  $0 image.jpg"
  echo "  $0 --skip-preview image.jpg"
  echo "  $0 -R image.jpg"
  echo "  $0 --png --jpg --jpeg"
  echo "  $0 --skip-preview --rm-src --png --jpg"
  echo "  $0 --transparent image.png"
  echo "  $0 --transparent --png"
  exit 1
fi

# Parse options and arguments
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --skip-preview)
      SKIP_PREVIEW=true
      ;;
    --skip-print)
      SKIP_PRINT=true
      ;;
    -R|--rm-src)
      RM_SOURCE=true
      ;;
    --transparent)
      TRANSPARENT=true
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

# Check if we have remaining arguments after parsing options
if [ ${#ARGS[@]} -eq 0 ]; then
  echo "Error: No file or extension specified."
  echo "Usage: $0 [options] <image_file> or $0 [options] --<extension> [--<extension>...]"
  exit 1
fi

# Check if both skip options are enabled
if [ "$SKIP_PREVIEW" = true ] && [ "$SKIP_PRINT" = true ]; then
  echo "Error: Cannot use both --skip-preview and --skip-print together."
  echo "Choose one or the other based on what you want to generate."
  exit 1
fi

# Validate transparent flag usage
if [ "$TRANSPARENT" = true ]; then
  # Check if processing by extension
  if [[ "${ARGS[0]}" == --* ]]; then
    # Check if --png is included
    has_png=false
    for arg in "${ARGS[@]}"; do
      if [[ "$arg" == "--png" ]]; then
        has_png=true
        break
      fi
    done
    if [ "$has_png" = false ]; then
      echo "Error: --transparent flag only works with PNG files."
      echo "Please use --png or specify a .png file directly."
      exit 1
    fi
  else
    # Check if single file is PNG
    if [[ ! "${ARGS[0]}" =~ \.[Pp][Nn][Gg]$ ]]; then
      echo "Error: --transparent flag only works with PNG files."
      echo "The input file must have a .png extension."
      exit 1
    fi
  fi
fi

# Process based on arguments
if [[ "${ARGS[0]}" == --* ]]; then
  # Process files by extension
  FILES=()
  
  # Build list of files based on extensions
  for arg in "${ARGS[@]}"; do
    if [[ "$arg" == --* ]]; then
      ext="${arg#--}"
      # Find files with this extension (case insensitive)
      while IFS= read -r -d '' file; do
        FILES+=("$file")
      done < <(find . -maxdepth 1 -type f -iname "*.${ext}" -print0 | sort -z)
    fi
  done
  
  # Check if any files were found
  if [ ${#FILES[@]} -eq 0 ]; then
    echo "No files found with the specified extensions."
    exit 1
  fi
  
  echo "Found ${#FILES[@]} file(s) to process:"
  printf '%s\n' "${FILES[@]}"
  if [ "$SKIP_PREVIEW" = true ]; then
    echo "Preview generation: SKIPPED"
  fi
  if [ "$SKIP_PRINT" = true ]; then
    echo "Skip print files: ENABLED (removed after successful processing)"
  fi
  if [ "$RM_SOURCE" = true ]; then
    echo "Remove source files: ENABLED (only after successful processing)"
  fi
  echo ""
  
  # Process each file
  FAILED=false
  for file in "${FILES[@]}"; do
    # Skip non-PNG files if transparent mode is enabled
    if [ "$TRANSPARENT" = true ] && [[ ! "$file" =~ \.[Pp][Nn][Gg]$ ]]; then
      echo "Skipping non-PNG file in transparent mode: $file"
      continue
    fi
    if ! process_image "$file"; then
      FAILED=true
    fi
  done
  
  # Delete source files only if all processing was successful and -R was specified
  if [ "$RM_SOURCE" = true ] && [ "$FAILED" = false ]; then
    echo "All processing successful. Removing source files..."
    for file in "${PROCESSED_FILES[@]}"; do
      rm -f "$file"
      echo "Removed: $file"
    done
  elif [ "$RM_SOURCE" = true ] && [ "$FAILED" = true ]; then
    echo "Warning: Some files failed to process. No source files were removed."
  fi

  # Delete print files if requested regardless of outcome
  if [ "$SKIP_PRINT" = true ]; then
    echo "Removing print files..."
    for file in "${PROCESSED_FILES[@]}"; do
      INPUT="$file"
      BASE="${INPUT%.*}"
      EXT="jpg"
      if [ "$TRANSPARENT" = true ]; then
        EXT="png"
      fi
      rm -f "${BASE}_FOR_PRINTING.${EXT}"
      echo "Removed: ${BASE}_FOR_PRINTING.${EXT}"
    done
  fi
  
else
  # Process single file
  if [ ! -f "${ARGS[0]}" ]; then
    echo "Error: File '${ARGS[0]}' not found."
    exit 1
  fi
  
  if process_image "${ARGS[0]}"; then
    # Delete source file only if processing was successful and -R was specified
    if [ "$RM_SOURCE" = true ]; then
      echo "Processing successful. Removing source file..."
      rm -f "${ARGS[0]}"
      echo "Removed: ${ARGS[0]}"
    fi
  else
    if [ "$RM_SOURCE" = true ]; then
      echo "Error: Processing failed. Source file was not removed."
    fi
    exit 1
  fi

  # Delete print file only if requested
  if [ "$SKIP_PRINT" = true ]; then
    echo "Removing print file..."
    INPUT="${ARGS[0]}"
    BASE="${INPUT%.*}"
    EXT="jpg"
    if [ "$TRANSPARENT" = true ]; then
      EXT="png"
    fi
    rm -f "${BASE}_FOR_PRINTING.${EXT}"
    echo "Removed: ${BASE}_FOR_PRINTING.${EXT}"
  fi
fi