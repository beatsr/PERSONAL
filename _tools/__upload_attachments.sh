#!/bin/bash

ROOT_DIR="Journal"
S3_BUCKET="aws-image-hosting"
S3_PREFIX="uploads"
S3_DOMAIN="https://d2dgt7odtnxylw.cloudfront.net"
SED_CMD="gsed"
MAX_FILE_SIZE_KB=1024

# Check required commands
for cmd in fd rg md5sum aws; do
    if ! command -v $cmd &>/dev/null; then
        echo "ERROR: Please install $cmd" >&2
        exit 1
    fi
done

# Find all markdown files with attachments
FILES=$(fd -e md -t f -p "$ROOT_DIR" -x rg -l "\!\[\[.*\]\]" {} \;)
if [ -z "$FILES" ]; then
    exit 0
fi

# Process each file
while IFS= read -r FILE; do
    # Validate file path format
    if ! [[ $FILE =~ $ROOT_DIR/[0-9]{4}/[0-9]{2}/[0-9]{2}/.*\.md$ ]]; then
        continue
    fi

    # Extract year/month for S3 path
    YEAR=$(echo "$FILE" | grep -o "[0-9]\{4\}" | head -1)
    MONTH=$(echo "$FILE" | grep -o "/[0-9]\{2\}/" | head -1 | tr -d "/")
    FILE_DIR=$(dirname "$FILE")

    # Get all attachment references - updated regex to capture everything inside [[]]
    rg -o "\!\[\[([^]]+)\]\]" "$FILE" | while IFS= read -r MATCH; do
        # Extract content between [[ ]]
        CONTENT=$(echo "$MATCH" | $SED_CMD -E 's/\!\[\[([^]]+)\]\]/\1/')
        
        # Split by first | to get filename and optional parameters
        ATTACHMENT=$(echo "$CONTENT" | cut -d'|' -f1)
        PARAMS=$(echo "$CONTENT" | $SED_CMD -E 's/^[^|]*(\|.*)?$/\1/')
        
        # Build attachment path based on actual content
        if [[ $ATTACHMENT == _attachments/* ]]; then
            # If already includes _attachments/, use relative to note directory
            ATTACHMENT_PATH="${FILE_DIR}/${ATTACHMENT}"
        else
            # If just filename, look in _attachments subdirectory
            ATTACHMENT_PATH="${FILE_DIR}/_attachments/${ATTACHMENT}"
        fi

        # Check if attachment exists
        if [ ! -f "$ATTACHMENT_PATH" ]; then
            echo "ERROR: Attachment not found: $ATTACHMENT_PATH" >&2
            exit 1
        fi

        # Check file size
        FILE_SIZE_BYTES=$(stat -f%z "$ATTACHMENT_PATH" 2>/dev/null || stat -c%s "$ATTACHMENT_PATH" 2>/dev/null)
        FILE_SIZE_KB=$((FILE_SIZE_BYTES / 1024))
        
        if [ $FILE_SIZE_KB -gt $MAX_FILE_SIZE_KB ]; then
            echo "WARNING: File size ${FILE_SIZE_KB}KB exceeds limit ${MAX_FILE_SIZE_KB}KB, skipping: $ATTACHMENT" >&2
            continue
        fi

        # Get file extension and create hash
        EXT="${ATTACHMENT##*.}"
        MD5_HASH=$(md5sum "$ATTACHMENT_PATH" | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]' | cut -c1-8)
        S3_PATH="${S3_PREFIX}/${YEAR}/${MONTH}/${MD5_HASH}.${EXT}"
        S3_FULL_URL="${S3_DOMAIN}/${S3_PATH}"

        # Upload to S3
        echo "Uploading: $ATTACHMENT → s3://${S3_BUCKET}/${S3_PATH}"
        aws s3 cp "$ATTACHMENT_PATH" "s3://${S3_BUCKET}/${S3_PATH}" --quiet || {
            echo "ERROR: Failed to upload: $ATTACHMENT_PATH" >&2
            exit 1
        }

        # Prepare replacement based on file type and parameters
        if [[ $EXT == "mp3" ]]; then
            NEW_REFERENCE="<audio controls><source src=\"${S3_FULL_URL}\" type=\"audio/mpeg\"></audio>"
            echo "Updating: ![[${CONTENT}]] → <audio controls><source src=\"${S3_FULL_URL}\" type=\"audio/mpeg\"></audio>"
        elif [ -n "$PARAMS" ]; then
            NEW_REFERENCE="![${PARAMS}](${S3_FULL_URL})"
            echo "Updating: ![[${CONTENT}]] → ![${PARAMS}](${S3_FULL_URL})"
        else
            NEW_REFERENCE="![](${S3_FULL_URL})"
            echo "Updating: ![[${CONTENT}]] → ![](${S3_FULL_URL})"
        fi

        # Escape special characters for sed
        ESCAPED_CONTENT=$(echo "$CONTENT" | $SED_CMD 's/[\/&]/\\&/g')
        OLD_REFERENCE="!\[\[${ESCAPED_CONTENT}\]\]"
        
        # Replace reference in markdown using # as delimiter to avoid | conflicts
        $SED_CMD -i "s#${OLD_REFERENCE}#${NEW_REFERENCE}#g" "$FILE" || {
            echo "ERROR: Failed to update reference in: $FILE" >&2
            exit 1
        }
    done
done <<<"$FILES"

# Clean up attachment directories
# fd -p "/_attachments/" -I -t f -x rm {}
