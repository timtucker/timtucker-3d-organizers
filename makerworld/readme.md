# MakerWorld Single-File SCAD Builds

This directory contains automated build scripts to compile all OpenSCAD models from the parent repository into standalone, single-file `.scad` scripts under `dist/` ready for upload to [MakerWorld's Parametric Model Maker](https://makerworld.com/makerlab/parametricModelMaker).

## Why This Is Needed

MakerWorld requires customizable models to be uploaded as a single, self-contained `.scad` file without external local library files or relative `use <...>` / `include <...>` dependencies.

The build scripts use OpenSCAD's `-o` export functionality (`--export-format csg`) to compile and inline all geometry, module calls, and math into self-contained scripts while preserving the exact directory hierarchy.

---

## Directory Structure

```text
timtucker-3d-organizers/
├── cabinetKeepoutSpacer.scad
├── hexGrid.scad
├── multiconnect/
│   ├── multiconnectCornerBrackets.scad
│   └── ...
├── pipeMount/
│   ├── basketPipeMount.scad
│   └── ...
└── makerworld/
    ├── build.py          <- Python multi-threaded build script
    ├── build.ps1         <- Native PowerShell build script
    ├── readme.md
    └── dist/             <- Mirrored output directory
        ├── cabinetKeepoutSpacer.scad
        ├── multiconnect/
        │   └── multiconnectCornerBrackets.scad
        └── pipeMount/
            └── basketPipeMount.scad
```

---

## Usage

You can use either the **Python** script or the native **PowerShell** script.

### 1. Python Build Script (`build.py`)

Works on Windows, macOS, and Linux. Supports multi-threaded parallel compilation.

```bash
# From within makerworld/
python build.py

# Or from repository root
python makerworld/build.py

# Preview the planned mirror structure without building
python build.py --dry-run

# Build only matching files
python build.py --filter basketPipeMount

# Clean the dist/ directory before building
python build.py --clean

# Specify number of parallel workers (default: up to 4)
python build.py --workers 8

# Specify custom OpenSCAD executable path
python build.py --openscad "C:\Program Files\OpenSCAD\openscad.com"
```

### 2. PowerShell Build Script (`build.ps1`)

Native to Windows PowerShell / pwsh:

```powershell
# From within makerworld/
.\build.ps1

# Dry run preview
.\build.ps1 -DryRun

# Build only matching files
.\build.ps1 -Filter "multiconnect"

# Clean dist directory before building
.\build.ps1 -Clean

# Custom OpenSCAD executable
.\build.ps1 -OpenSCAD "C:\Program Files\OpenSCAD (Nightly)\openscad.com"
```

---

## Features

- **Automatic OpenSCAD Detection**: Automatically finds OpenSCAD on Windows (Nightly, release, Program Files, LocalAppData), macOS, and Linux.
- **Includes and Dependency Resolution**: Automatically configures `OPENSCADPATH` so relative includes (e.g., `use <hexGrid.scad>`, `<BOSL2/std.scad>`) are resolved during compilation.
- **Hierarchical Mirroring**: Replicates the exact relative folder structure under `dist/`.
- **Exclusion Rules**: Automatically ignores `makerworld/`, `dist/`, `.git/`, and other non-model folders.
- **Fallback Compatibility**: Tries direct `--export-format csg -o dest.scad` first, falling back to `-o temp.csg` conversion if running on older OpenSCAD versions.
