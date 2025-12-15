#!/bin/bash
set -e

echo "Starting image digest vendoring process..."

# Check dependencies
echo "Checking dependencies..."
command -v kustomize >/dev/null 2>&1 || { echo >&2 "Error: kustomize is required but not installed. Aborting."; exit 1; }
command -v skopeo >/dev/null 2>&1 || { echo >&2 "Error: skopeo is required but not installed. Aborting."; exit 1; }
echo "Dependencies found."

# Default to overlays/okd if not specified
OVERLAY=${1:-overlays/okd}
echo "Target overlay: $OVERLAY"

if [ ! -d "$OVERLAY" ]; then
    echo "Error: Overlay directory '$OVERLAY' not found."
    echo "Usage: $0 [overlay-path]"
    exit 1
fi

echo "Extracting images from rendered manifests..."
images=$(kustomize build "$OVERLAY" | grep "image: " | awk '{for(i=1;i<=NF;i++) if($i=="image:") print $(i+1)}' | sort -u)

if [ -z "$images" ]; then
    echo "No images found in manifests."
    exit 0
fi

echo "Found images:"
echo "$images" | sed 's/^/  - /'

for image in $images; do
    echo "--------------------------------------------------"
    echo "Processing: $image"

    # Skip if already a digest
    if [[ "$image" == *"@sha256"* ]]; then
        echo "  Skipping: Already uses digest."
        continue
    fi

    # Handle docker.io prefix for skopeo lookup if missing
    lookup_image="$image"
    if [[ "$image" != *.*/* ]]; then
        lookup_image="docker.io/$image"
        echo "  Added registry prefix: $lookup_image"
    fi

    echo "  Resolving digest via skopeo..."
    # Use skopeo to get the digest (requires skopeo installed)
    digest=$(skopeo inspect "docker://$lookup_image" --format '{{.Digest}}')

    if [ -n "$digest" ]; then
        echo "  Digest found: $digest"

        # Strip the tag (everything after the last colon)
        # Use lookup_image to ensure registry prefix (e.g. docker.io) is included
        repo=${lookup_image%:*}
        new_image="${repo}@${digest}"
        echo "  Updating manifests: $image -> $new_image"

        # Replace in base yaml files
        find base -name "*.yaml" -exec sed -i "s|image: $image|image: $new_image|g" {} +
        echo "  Replacement complete."
    else
        echo "  Error: Failed to resolve digest for $image"
    fi
done

echo "--------------------------------------------------"
echo "Image vendoring complete."
