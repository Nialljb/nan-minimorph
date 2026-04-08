#!/usr/bin/env python3
"""Standalone CLI entry point for MiniMORPH."""

import os
import sys
import logging
import tempfile
import shutil

# Add the minimorph directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils.parser_standalone import parse_config, setup_logging
from utils.command_line import exec_command

# Remove Flywheel-specific imports that aren't needed
# from utils.join_data import housekeeping  
# from utils.Inspect_segmentations import SegQC

log = logging.getLogger(__name__)

def main():
    """Main entry point for standalone MiniMORPH."""
    
    # Parse command line arguments
    try:
        input_path, age, output_dir, work_dir, subject_id = parse_config()
    except SystemExit as e:
        # argparse exits on error or help, let it pass through
        sys.exit(e.code)
    
    # Setup logging
    setup_logging(verbose='-v' in sys.argv or '--verbose' in sys.argv)
    
    log.info("Starting MiniMORPH processing...")
    log.info(f"Input: {input_path}")
    log.info(f"Age template: {age}")
    log.info(f"Output directory: {output_dir}")
    log.info(f"Work directory: {work_dir}")
    log.info(f"Subject ID: {subject_id}")
    
    # Determine if we're running in container or standalone
    if os.path.exists('/opt/minimorph'):
        # Running in container
        minimorph_base = '/opt/minimorph'
        log.info("Running in Apptainer/Singularity container")
    else:
        # Running standalone (development)
        minimorph_base = os.path.dirname(os.path.abspath(__file__))
        log.info("Running in development mode")
    
    # Set environment variables for the main script
    os.environ['MINIMORPH_BASE'] = minimorph_base
    os.environ['OUTPUT_DIR'] = output_dir
    os.environ['WORK_DIR'] = work_dir
    os.environ['SUBJECT_ID'] = subject_id
    
    try:
        # Call the main processing script
        main_script = os.path.join(minimorph_base, 'app', 'main.sh')
        if not os.path.exists(main_script):
            log.error(f"Main processing script not found: {main_script}")
            sys.exit(1)
        
        log.info("Starting main processing pipeline...")
        
        # Build the command with proper arguments
        command = f"bash {main_script} {input_path} {age}"
        
        # Execute the main processing
        exec_command(command, shell=True, cont_output=True)
        
        log.info("Main processing completed successfully")
        
        # TODO: Add back housekeeping and QC when adapted for standalone use
        # housekeeping(demographics)  # Need to adapt this
        # SegQC(input_path, subject_id)  # Need to adapt this
        
        log.info("MiniMORPH processing completed successfully!")
        
        # List output files
        log.info("Output files generated:")
        for file in os.listdir(output_dir):
            log.info(f"  {file}")
            
    except Exception as e:
        log.error(f"Processing failed: {str(e)}")
        sys.exit(1)
    
    finally:
        # Clean up temporary work directory if we created it
        if work_dir.startswith(tempfile.gettempdir()) and 'minimorph_' in work_dir:
            log.info(f"Cleaning up temporary work directory: {work_dir}")
            try:
                shutil.rmtree(work_dir)
            except Exception as e:
                log.warning(f"Could not clean up work directory: {e}")


if __name__ == "__main__":
    main()