#!/bin/bash
# correct_and_preview.sh - Adjusted for better color vibrancy

# Global variable for skip preview mode
SKIP_PREVIEW=false
# Global variable for remove source files mode
RM_SOURCE=false
# Array to track successfully processed files
PROCESSED_FILES=()

# Function to process a single image
process_image() {
  local INPUT="$1"
  local BASE="${INPUT%.*}"
  
  echo "Processing: $INPUT"
  
  # Step 1: Create corrected image (preserve purples and warm tones)
  magick "$INPUT" \
    -channel G -evaluate multiply 0.80 +channel \
    -channel R -evaluate multiply 1.01 +channel \
    -channel B -evaluate multiply 0.97 +channel \
    -modulate 98,94,104 \
    -brightness-contrast -3x-11 \
    -level 0%,101%,1.04 \
    "${BASE}_FOR_PRINTING.jpg"
  
  # Check if the first magick command was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create corrected image for $INPUT"
    return 1
  fi
  
  if [ "$SKIP_PREVIEW" = false ]; then
    # Step 2: Simulate how the corrected image will print (unchanged)
    magick "${BASE}_FOR_PRINTING.jpg" \
      -channel G -evaluate multiply 1.215 +channel \
      -channel R -evaluate multiply 0.945 +channel \
      -channel B -evaluate multiply 1.08 +channel \
      -modulate 101,116,93 \
      -brightness-contrast 2x12 \
      -level 0%,96%,0.94 \
      "${BASE}_PREVIEW_AFTER_CORRECTION.jpg"
    
    # Check if the second magick command was successful
    if [ $? -ne 0 ]; then
      echo "Error: Failed to create preview image for $INPUT"
      return 1
    fi
    
    echo "Created:"
    echo "  ${BASE}_FOR_PRINTING.jpg - Send THIS to your printer"
    echo "  ${BASE}_PREVIEW_AFTER_CORRECTION.jpg - Preview of final print"
  else
    echo "Created:"
    echo "  ${BASE}_FOR_PRINTING.jpg - Send THIS to your printer"
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
  echo "  -S, --skip    Skip preview generation, only create print files"
  echo "  -R, --rm-src  Remove source files after successful processing"
  echo "Examples:"
  echo "  $0 image.jpg"
  echo "  $0 -S image.jpg"
  echo "  $0 -R image.jpg"
  echo "  $0 --png --jpg --jpeg"
  echo "  $0 --skip --rm-src --png --jpg"
  exit 1
fi

# Parse options and arguments
ARGS=()
for arg in "$@"; do
  case "$arg" in
    -S|--skip)
      SKIP_PREVIEW=true
      ;;
    -R|--rm-src)
      RM_SOURCE=true
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
  if [ "$RM_SOURCE" = true ]; then
    echo "Remove source files: ENABLED (only after successful processing)"
  fi
  echo ""
  
  # Process each file
  FAILED=false
  for file in "${FILES[@]}"; do
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
fi