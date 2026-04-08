#!/bin/bash
#SBATCH --job-name=minimorph_processing
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=03:00:00
#SBATCH --output=minimorph_%j.out
#SBATCH --error=minimorph_%j.err
#
# Example SLURM submission script for MiniMORPH processing
#
# Usage: sbatch run_minimorph_slurm.sh
#
# Make sure to modify the paths and parameters below for your specific use case
#

# Load Singularity module (adjust for your HPC environment)
# module load singularity

# Detect container runtime
if command -v apptainer &> /dev/null; then
    CONTAINER_CMD="apptainer"
elif command -v singularity &> /dev/null; then
    CONTAINER_CMD="singularity"
else
    echo "Error: Neither Apptainer nor Singularity found in PATH"
    exit 1
fi
echo "Using container runtime: $CONTAINER_CMD"

# Define paths - MODIFY THESE FOR YOUR ENVIRONMENT
MINIMORPH_IMAGE="/data/project/pipeline/cortex/repos/nan-minimorph/sample-build/minimorph.sif"
INPUT_DIR="$HOME/mini-test"
OUTPUT_DIR="$HOME/mini-test/output"
WORK_DIR="$HOME/mini-test" #"/tmp/minimorph_work_${SLURM_JOB_ID}"

# Subject and session information - MODIFY FOR YOUR DATA
# SUBJECT="01"
# SESSION="01"
# Age template - REQUIRED FOR MINIMORPH (3M, 6M, 12M, 18M, 24M)
AGE_TEMPLATE="24M"

# Input file path (adjust pattern as needed)
# INPUT_FILE="${INPUT_DIR}/sub-${SUBJECT}/ses-${SESSION}/anat/sub-${SUBJECT}_ses-${SESSION}_T2w.nii.gz"
INPUT_FILE="${INPUT_DIR}/sub-UNITE_SLAM_001_ses-unknown_rec-mrr_T2.nii.gz"

# Derive subject ID from filename for output naming
INPUT_BASENAME=$(basename "$INPUT_FILE")
SUBJECT_ID="${INPUT_BASENAME%.nii.gz}"


# Create output directory
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${WORK_DIR}"

echo "Starting MiniMORPH processing..."
echo "Job ID: ${SLURM_JOB_ID}"
echo "Subject ID: ${SUBJECT_ID}"
echo "Age template: ${AGE_TEMPLATE}"
echo "Input: ${INPUT_FILE}"
echo "Output: ${OUTPUT_DIR}"
echo "Work directory: ${WORK_DIR}"
echo "Container: ${CONTAINER_CMD}"

# Check if input file exists
if [[ ! -f "${INPUT_FILE}" ]]; then
    echo "Error: Input file not found: ${INPUT_FILE}"
    exit 1
fi

# Run MiniMORPH processing
$CONTAINER_CMD exec \
    --bind "${INPUT_DIR}:/input:ro" \
    --bind "${OUTPUT_DIR}:/output:rw" \
    --bind "${WORK_DIR}:/tmp/minimorph_work:rw" \
    "${MINIMORPH_IMAGE}" \
    python3 /opt/minimorph/minimorph_cli.py \
        --input "/input/$(basename "$INPUT_FILE")" \
        --age "${AGE_TEMPLATE}" \
        --output /output \
        --work-dir /tmp/minimorph_work \
        --subject-id "${SUBJECT_ID}" \
        --verbose

# Check if processing was successful
if [[ $? -eq 0 ]]; then
    echo "MiniMORPH processing completed successfully!"
    echo "Output files:"
    ls -la "${OUTPUT_DIR}/"
else
    echo "Error: MiniMORPH processing failed"
    exit 1
fi

# Only clean up work directory if it's a temporary one
if [[ "$WORK_DIR" == *"tmp"* ]] && [[ "$WORK_DIR" == *"minimorph_work"* ]]; then
    echo "Cleaning up temporary work directory: ${WORK_DIR}"
    rm -rf "${WORK_DIR}"
fi

echo "Job completed!"