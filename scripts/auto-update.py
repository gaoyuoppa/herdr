#!/usr/bin/env python3
"""Deprecated compatibility entry point for safe upstream synchronization.

Deployment is intentionally separate from source synchronization. This wrapper
keeps old invocations working without storing credentials or automatically
stashing/dropping local changes.
"""

from __future__ import annotations

import runpy
from pathlib import Path


if __name__ == "__main__":
    runpy.run_path(
        str(Path(__file__).with_name("sync-upstream.py")),
        run_name="__main__",
    )
