#!/bin/bash
#
# Build script for MiniMORPH Apptainer image
#

set -e

IMAGE_NAME="minimorph.sif"
DEF_FILE="minimorph.def"

echo "Building MiniMORPH Apptainer image..."
echo "Definition file: $DEF_FILE"
echo "Output image: $IMAGE_NAME"

# Check if Singularity/Apptainer is available
if command -v apptainer &> /dev/null; then
    BUILD_CMD="apptainer"
elif command -v singularity &> /dev/null; then
    BUILD_CMD="singularity"
else
    echo "Error: Neither Apptainer nor Singularity is installed or in PATH"
    exit 1
fi

echo "Using build command: $BUILD_CMD"

# Check if definition file exists
if [[ ! -f "$DEF_FILE" ]]; then
    echo "Error: Definition file '$DEF_FILE' not found"
    echo "Please create $DEF_FILE before running this script"
    exit 1
fi

# Check if templates directory exists
if [[ ! -d "app/templates" ]]; then
    echo "Error: Templates directory 'app/templates' not found"
    echo "Please ensure you're running this script from the minimorph root directory"
    exit 1
fi

# Verify template completeness
echo "Verifying template completeness..."
for age in 3M 6M 12M 18M 24M; do
    template_dir="app/templates/${age}"
    if [[ ! -d "$template_dir" ]]; then
        echo "Error: Template directory missing: $template_dir"
        exit 1
    fi
    
    # Check for key files
    template_file="${template_dir}/template_${age}_degibbs_padded.nii.gz"
    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template file missing: $template_file"
        exit 1
    fi
done
echo "All templates verified"

# Remove existing image if it exists
if [[ -f "$IMAGE_NAME" ]]; then
    echo "Removing existing image: $IMAGE_NAME"
    rm "$IMAGE_NAME"
fi

# Build the image
echo "Building Apptainer image (this may take a while)..."
echo "This will bundle all age templates into the container..."

# Try with fakeroot first, fall back to sudo if needed  
if ! $BUILD_CMD build --fakeroot "$IMAGE_NAME" "$DEF_FILE" 2>/dev/null; then
    echo "Fakeroot build failed, trying with sudo..."
    sudo $BUILD_CMD build "$IMAGE_NAME" "$DEF_FILE"
fi

if [[ $? -eq 0 ]]; then
    echo "Successfully built: $IMAGE_NAME"
    echo "Image size: $(du -h "$IMAGE_NAME" | cut -f1)"
    
    echo ""
    echo "Testing the image..."
    $BUILD_CMD test "$IMAGE_NAME"
    
    if [[ $? -eq 0 ]]; then
        echo "Image test passed!"
        echo ""
        echo "You can now use the image with:"
        echo "  $BUILD_CMD exec $IMAGE_NAME minimorph --help"
        echo ""
        echo "Example usage:"
        echo "  $BUILD_CMD exec --bind /data:/data --bind /results:/results ${IMAGE_NAME} \\"
        echo "    minimorph --input /data/subject_T2w.nii.gz --age 6M --output /results"
    else
        echo "Warning: Image test failed"
        exit 1
    fi
else
    echo "Error: Failed to build Apptainer image"
    exit 1
fi

echo ""
echo "Build completed successfully!"
echo "Image location: $(pwd)/$IMAGE_NAME"