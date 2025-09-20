# ``SwiftCursesKit``

Create immersive terminal user interfaces using modern Swift APIs layered on top of ncurses.

## Overview

SwiftCursesKit provides resource-safe wrappers around ncurses concepts like screens and windows. Use ``TerminalApp`` to bootstrap the runtime, coordinate your main loop with ``AppContext``, and compose views backed by RAII-aware ``Window`` instances.
