# MiniMORPH: Infant Brain Segmentation for HPC

## Overview

MiniMORPH is a robust infant brain segmentation pipeline designed for low-field MRI data. This containerized version provides age-matched brain segmentation for infants aged 3-24 months using Apptainer/Singularity containers optimized for HPC environments with SLURM integration.

**Key Features:**
- 🧠 **Age-specific templates** (3M, 6M, 12M, 18M, 24M) bundled in container
- 🖧 **HPC-ready** with SLURM job submission scripts  
- 📦 **Self-contained** - no external dependencies or atlas downloads required
- ⚡ **Optimized** ANTs registration and Bayesian segmentation pipeline
- 📊 **Comprehensive outputs** - segmentation, volumes, and quality control images

## Quick Start

### 1. Build the Container

```bash
# Clone the repository
git clone <repository-url>
cd nan-minimorph

# Build the container (requires Apptainer/Singularity)
./build_singularity.sh
```

### 2. Validate Installation

```bash
# Test that everything works correctly
./sample-build/validate_installation.sh
```

### 3. Process Data

**Interactive processing:**
```bash
apptainer exec --bind /data:/data --bind /results:/results minimorph.sif \
  python3 /opt/minimorph/minimorph_cli.py \
    --input /data/subject_T2w.nii.gz \
    --age 6M \
    --output /results \
    --verbose
```

**SLURM job submission:**
```bash
# Edit run_minimorph_slurm.sh to set your paths and parameters
sbatch run_minimorph_slurm.sh
```

## Installation Requirements

- **Container Runtime:** Apptainer or Singularity  
- **Base Dependencies:** Included in container (ANTs, FSL, FreeSurfer)
- **Memory:** 24GB RAM recommended (configurable in SLURM script)
- **Storage:** ~2GB for container image + temporary work space

## Usage

### Command Line Interface

```bash
python3 /opt/minimorph/minimorph_cli.py --help
```

**Required Arguments:**
- `--input` (`-i`): T2-weighted NIfTI image (`.nii` or `.nii.gz`)
- `--age` (`-a`): Age template - must be one of: `3M`, `6M`, `12M`, `18M`, `24M`  
- `--output` (`-o`): Output directory for results

**Optional Arguments:**  
- `--work-dir` (`-w`): Working directory (default: temporary)
- `--subject-id` (`-s`): Subject ID for output naming (default: derived from filename)
- `--verbose` (`-v`): Enable detailed logging

### Age Template Selection

| Age Range | Template | Recommended Use |
|-----------|----------|-----------------|
| 0-5 months | `3M` | Newborns, very young infants |
| 5-10 months | `6M` | Young infants |  
| 10-16 months | `12M` | Older infants |
| 16-22 months | `18M` | Young toddlers |
| 22+ months | `24M` | Older toddlers |

### SLURM Integration

Edit `run_minimorph_slurm.sh` to configure:

```bash
# Required modifications
MINIMORPH_IMAGE="./minimorph.sif"           # Path to built container
INPUT_DIR="/data/bids_dataset"              # Input data directory  
OUTPUT_DIR="/results/minimorph_output"      # Output directory
AGE_TEMPLATE="6M"                           # Age template to use
INPUT_FILE="${INPUT_DIR}/subject_T2w.nii.gz"  # Specific input file
```

Submit with: `sbatch run_minimorph_slurm.sh`

## Input Requirements

**Image Format:** NIfTI (`.nii` or `.nii.gz`)  
**Image Type:** T2-weighted, isotropic resolution preferred  
**Preprocessing:** Brain extraction recommended but not required (pipeline includes mri_synthstrip)
**Quality:** Images should be motion-free with good tissue contrast

## Outputs

For each processed subject, MiniMORPH generates:

| File | Description | 
|------|-------------|
| `*_segmentation.nii.gz` | **Multi-label atlas** with 16+ tissue types in native space |  
| `*_volumes.csv` | **Volume estimates** for each tissue type + ICV calculation |
| `*_QC-montage.png` | **Quality control** axial slice overlay for visual inspection |

**Segmentation Labels:**
- Supratentorial tissue (WM+GM), CSF, Ventricles  
- Left/right subcortical GM, Cerebellum, Brainstem
- Corpus callosum segments (5 sub-regions)

## Algorithm Overview

The MiniMORPH pipeline performs:

1. **Preprocessing:** Denoising, bias correction, brain extraction (mri_synthstrip)
2. **Registration:** ANTs SyN registration to age-matched template  
3. **Prior Transform:** Move tissue priors and anatomical masks to native space
4. **Segmentation:** Bayesian segmentation (antsAtroposN4) using transformed priors
5. **Refinement:** Anatomical mask application for ventricles, subcortical structures
6. **Atlas Building:** Multi-label atlas construction with volume calculation

## Scientific Background

**Templates & Priors:**
- *Age-specific templates:* High-quality UCT-Khula study datasets  
- *Tissue priors:* Baby Connectome Project (BCP) atlas registration
- *Anatomical masks:* Manual delineation + Penn-CHOP Infant Brain Atlas

**Citation:**    
MiniMORPH: A Morphometry Pipeline for Low-Field MRI in Infants
Chiara Casella, Aksel Leknes, Niall J. Bourke, Ayo Zahra, Daniel Cromb, Dora Barnes, Alejandra Martin Segura, Flora Silvester, Vanessa Kyriakopoulou, Daniel Elijah Scheiene, Simone R. Williams, Layla E. Bradford, Joanitta Murungi, Steven C. R. Williams, Sean C. L. Deoni, Victoria Nankabirwa, Kirsten A. Donald, Muriel M. K. Bruchhage, Jonathan O’Muircheartaigh
medRxiv 2025.07.01.25330469; doi: https://doi.org/10.1101/2025.07.01.25330469

## Troubleshooting

**Container build fails:**
- Ensure Apptainer/Singularity is installed and in PATH
- Check that all template files are present in `app/templates/`
- Try building with `sudo` if fakeroot fails

**Processing errors:**
- Verify input file exists and is valid NIfTI format
- Check age template selection (must be exact: 3M, 6M, 12M, 18M, 24M)
- Ensure sufficient memory allocation (24GB recommended)  
- Review logs with `--verbose` flag for detailed diagnostics

**SLURM submission issues:**
- Verify container image path in script
- Check input/output directory permissions and paths
- Ensure Singularity module is loaded correctly

## Support & Development

**Repository:** https://github.com/Nialljb/MiniMORPH  
**License:** MIT License  
**Authors:** Chiara Casella, Niall Bourke, Johnny O Muircheartaigh  

For issues and feature requests, please use the GitHub issue tracker.