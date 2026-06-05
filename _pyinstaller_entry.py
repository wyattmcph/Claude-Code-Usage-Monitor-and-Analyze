"""PyInstaller entry point for claude-monitor.

Uses absolute imports instead of the relative imports in __main__.py,
which fail when PyInstaller runs the script outside of a package context.
This file is only used by the build — normal `python -m claude_monitor`
continues to use __main__.py as usual.
"""

import sys
from claude_monitor.cli.main import main

sys.exit(main() or 0)
