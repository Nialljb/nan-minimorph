#!/bin/bash
#
# Validation script for MiniMORPH installation
# Tests that the container is built correctly and can access templates
#

set -e

IMAGE_NAME="minimorph.sif"

echo "=== MiniMORPH Installation Validation ==="
echo ""

# Check if image exists
if [[ ! -f "$IMAGE_NAME" ]]; then
    echo "ERROR: MiniMORPH image not found: $IMAGE_NAME"
    echo "Please build the image first using: ./build_singularity.sh"
    exit 1
fi

echo "✓ Found MiniMORPH image: $IMAGE_NAME"

# Detect container runtime
if command -v apptainer &> /dev/null; then
    EXEC_CMD="apptainer"
elif command -v singularity &> /dev/null; then
    EXEC_CMD="singularity"
else
    echo "ERROR: Neither Apptainer nor Singularity found in PATH"
    exit 1
fi

echo "✓ Using container runtime: $EXEC_CMD"

# Test basic help
echo ""
echo "Testing basic CLI help..."
$EXEC_CMD exec "$IMAGE_NAME" minimorph --help > /dev/null
echo "✓ CLI help works"

# Test template access
echo ""
echo "Testing template accessibility..."
for age in 3M 6M 12M 18M 24M; do
    echo "  Checking $age template..."
    $EXEC_CMD exec "$IMAGE_NAME" ls -la /opt/minimorph/app/templates/${age}/template_${age}_degibbs_padded.nii.gz > /dev/null
    echo "    ✓ $age template accessible"
done

# Test tool availability  
echo ""
echo "Testing core tools..."
$EXEC_CMD exec "$IMAGE_NAME" which antsRegistration > /dev/null
echo "  ✓ ANTs available"

$EXEC_CMD exec "$IMAGE_NAME" which fslmaths > /dev/null  
echo "  ✓ FSL available"

$EXEC_CMD exec "$IMAGE_NAME" which mri_synthstrip > /dev/null
echo "  ✓ FreeSurfer available"

# Test Python imports
echo ""
echo "Testing Python dependencies..."
$EXEC_CMD exec "$IMAGE_NAME" python3 -c "import nibabel, pandas, matplotlib; print('Python dependencies OK')" > /dev/null
echo "  ✓ Python dependencies available"

echo ""
echo "=== All validation tests passed! ==="
echo ""  
echo "Your MiniMORPH installation is ready to use."
echo ""
echo "Example usage:"
echo "  # Process a single subject"
echo "  $EXEC_CMD exec --bind /data:/data --bind /results:/results $IMAGE_NAME \\"
echo "    minimorph --input /data/subject_T2w.nii.gz --age 6M --output /results"
echo ""
echo "  # Use with SLURM"
echo "  sbatch run_minimorph_slurm.sh"