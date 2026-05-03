"""
Pipeline CLI orchestrator for the Florida Parcels ELT pipeline.

Usage:
    python -m src.pipeline --phase all        # Run full pipeline
    python -m src.pipeline --phase extract    # Run extraction only
    python -m src.pipeline --phase load       # Run load only
    python -m src.pipeline --phase transform  # Run transform only
    python -m src.pipeline --phase validate   # Run validation only
"""
import argparse
import json
import logging
import sys
import time

from src.config import PROJECT_ROOT


def _setup_logging() -> None:
    """Configure logging to console and file."""
    log_format = "%(asctime)s [%(levelname)-5s] %(name)s: %(message)s"
    log_file = PROJECT_ROOT / "pipeline.log"

    handlers = [
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(str(log_file), mode="a", encoding="utf-8"),
    ]

    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=handlers,
    )


def run_extract() -> dict:
    from src.extract import extract
    return extract()


def run_load() -> dict:
    from src.load import load
    return load()


def run_transform() -> dict:
    from src.transform import transform
    return transform()


def run_validate() -> dict:
    from src.validate import validate
    return validate()


PHASES = {
    "extract": run_extract,
    "load": run_load,
    "transform": run_transform,
    "validate": run_validate,
}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Florida Parcels ELT Pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--phase",
        choices=["extract", "load", "transform", "validate", "all"],
        default="all",
        help="Pipeline phase to run (default: all)",
    )
    args = parser.parse_args()

    _setup_logging()
    logger = logging.getLogger("pipeline")

    logger.info("=" * 60)
    logger.info("FLORIDA PARCELS ELT PIPELINE")
    logger.info("Phase: %s", args.phase)
    logger.info("=" * 60)

    pipeline_start = time.time()

    if args.phase == "all":
        phases_to_run = ["extract", "load", "transform", "validate"]
    else:
        phases_to_run = [args.phase]

    results = {}
    for phase_name in phases_to_run:
        logger.info("-" * 40)
        logger.info("STARTING PHASE: %s", phase_name.upper())
        logger.info("-" * 40)

        phase_start = time.time()
        try:
            result = PHASES[phase_name]()
            phase_elapsed = time.time() - phase_start
            results[phase_name] = result
            logger.info(
                "PHASE %s COMPLETED in %.1fs",
                phase_name.upper(),
                phase_elapsed,
            )
        except Exception as e:
            phase_elapsed = time.time() - phase_start
            logger.error(
                "PHASE %s FAILED after %.1fs: %s",
                phase_name.upper(),
                phase_elapsed,
                e,
                exc_info=True,
            )
            sys.exit(1)

    total_elapsed = time.time() - pipeline_start

    logger.info("=" * 60)
    logger.info("PIPELINE COMPLETE — Total time: %.1fs", total_elapsed)
    logger.info("Results: %s", json.dumps(results, indent=2, default=str))
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
