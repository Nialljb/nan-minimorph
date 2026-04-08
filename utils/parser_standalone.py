"""Parser module for standalone MiniMORPH CLI."""

import argparse
import sys
import os
import logging

log = logging.getLogger(__name__)

def parse_config(args=None):
    """Parse the config and options for standalone MiniMORPH.
    
    Args:
        args: Command line arguments (if None, will parse from sys.argv)
    
    Returns:
        Tuple of (input_path, age_template, output_dir, work_dir, subject_id)
    """
    
    parser = argparse.ArgumentParser(
        description='MiniMORPH: Infant brain segmentation for low-field MRI',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s --input subject_T2w.nii.gz --age 6M --output ./results
  %(prog)s --input /data/T2w.nii.gz --age 12M --output /results --work-dir /tmp/work
  
Age templates available: 3M, 6M, 12M, 18M, 24M

The algorithm performs:
1. Brain extraction and bias correction  
2. Registration to age-matched template
3. Transform tissue priors to native space
4. Bayesian segmentation (ANTs Atropos)
5. Anatomical refinement using age-specific masks

Outputs:
- *_segmentation.nii.gz: Multi-label atlas (16+ tissue types)
- *_volumes.csv: Volume estimates + ICV
- *_QC-montage.png: Visual quality control overlay
        ''')
    
    parser.add_argument('--input', '-i', 
                       required=True,
                       help='Input T2-weighted NIfTI image (brain-extracted preferred)')
    
    parser.add_argument('--age', '-a',
                       required=True, 
                       choices=['3M', '6M', '12M', '18M', '24M'],
                       help='Age template to use (3M, 6M, 12M, 18M, or 24M)')
    
    parser.add_argument('--output', '-o',
                       required=True,
                       help='Output directory for results')
    
    parser.add_argument('--work-dir', '-w',
                       default=None,
                       help='Working directory for intermediate files (default: temp directory)')
    
    parser.add_argument('--subject-id', '-s',
                       default=None,
                       help='Subject identifier for output naming (default: derived from input filename)')
    
    parser.add_argument('--verbose', '-v',
                       action='store_true',
                       help='Enable verbose logging')
    
    parser.add_argument('--version',
                       action='version',
                       version='MiniMORPH v1.0.0')
    
    if args is None:
        args = parser.parse_args()
    else:
        args = parser.parse_args(args)
    
    # Validate inputs
    if not os.path.isfile(args.input):
        parser.error(f"Input file does not exist: {args.input}")
    
    # Create output directory if it doesn't exist
    os.makedirs(args.output, exist_ok=True)
    
    # Set up work directory
    if args.work_dir is None:
        import tempfile
        args.work_dir = tempfile.mkdtemp(prefix='minimorph_')
        log.info(f"Using temporary work directory: {args.work_dir}")
    else:
        os.makedirs(args.work_dir, exist_ok=True)
    
    # Derive subject ID from filename if not provided
    if args.subject_id is None:
        basename = os.path.basename(args.input)
        # Remove common suffixes
        for suffix in ['.nii.gz', '.nii', '_T2w', '_t2w']:
            if basename.endswith(suffix):
                basename = basename[:-len(suffix)]
        args.subject_id = basename
        log.info(f"Using derived subject ID: {args.subject_id}")
    
    log.info(f"Configuration:")
    log.info(f"  Input: {args.input}")
    log.info(f"  Age template: {args.age}")
    log.info(f"  Output directory: {args.output}")
    log.info(f"  Work directory: {args.work_dir}")
    log.info(f"  Subject ID: {args.subject_id}")
    
    # Return the parsed configuration
    return args.input, args.age, args.output, args.work_dir, args.subject_id


def setup_logging(verbose=False):
    """Setup logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )


if __name__ == "__main__":
    # Test the parser
    try:
        config = parse_config()
        print("Parser test successful")
        print(f"Config: {config}")
    except SystemExit:
        # argparse calls sys.exit on error, which is expected during testing
        pass