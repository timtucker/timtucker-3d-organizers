#!/usr/bin/env python3
"""
MakerWorld Single-File SCAD Build Script
========================================
Compiles all OpenSCAD models in the parent directory (excluding makerworld/)
into standalone single-file scripts under makerworld/dist/, preserving the
exact directory hierarchy.

Uses OpenSCAD's `-o` export function (--export-format csg) to inline all
includes, modules, and dependencies into self-contained .scad files ready
for upload to MakerWorld's Parametric Model Maker.
"""

import argparse
import os
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


def find_openscad(custom_path=None):
    """Locate the OpenSCAD executable across common installation paths."""
    if custom_path:
        p = Path(custom_path)
        if p.is_file():
            return str(p)
        raise FileNotFoundError(f"Specified OpenSCAD path does not exist: {custom_path}")

    # Check OPENSCAD environment variable
    env_path = os.environ.get("OPENSCAD")
    if env_path and Path(env_path).is_file():
        return env_path

    # Check system PATH
    which_scad = shutil.which("openscad") or shutil.which("openscad.com") or shutil.which("openscad.exe")
    if which_scad:
        return which_scad

    # Windows candidate paths (prefer .com CLI wrappers over .exe for proper stdout/stderr)
    windows_candidates = [
        r"C:\Program Files\OpenSCAD (Nightly)\openscad.com",
        r"C:\Program Files\OpenSCAD\openscad.com",
        r"C:\Program Files (x86)\OpenSCAD\openscad.com",
        r"C:\Program Files\OpenSCAD (Nightly)\openscad.exe",
        r"C:\Program Files\OpenSCAD\openscad.exe",
        r"C:\Program Files (x86)\OpenSCAD\openscad.exe",
        os.path.expandvars(r"%LOCALAPPDATA%\Programs\OpenSCAD\openscad.com"),
        os.path.expandvars(r"%LOCALAPPDATA%\Programs\OpenSCAD\openscad.exe"),
    ]
    for cand in windows_candidates:
        if Path(cand).is_file():
            return cand

    # macOS candidates
    mac_candidates = [
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
        os.path.expanduser("~/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"),
    ]
    for cand in mac_candidates:
        if Path(cand).is_file():
            return cand

    # Linux candidates
    linux_candidates = [
        "/usr/bin/openscad",
        "/usr/local/bin/openscad",
        "/var/lib/flatpak/exports/bin/org.openscad.OpenSCAD",
        os.path.expanduser("~/.local/share/flatpak/exports/bin/org.openscad.OpenSCAD"),
        "/snap/bin/openscad",
    ]
    for cand in linux_candidates:
        if Path(cand).is_file():
            return cand

    return None


def get_default_paths():
    """Derive default source (parent) and destination (makerworld/dist) directories."""
    script_dir = Path(__file__).resolve().parent
    # If this script is in makerworld/, parent is the repo root
    if script_dir.name.lower() == "makerworld":
        parent_dir = script_dir.parent
        dist_dir = script_dir / "dist"
    else:
        # Fallback if script is at repo root
        parent_dir = script_dir
        dist_dir = script_dir / "makerworld" / "dist"

    return parent_dir, dist_dir


def discover_scad_files(src_dir, exclude_dirs=None):
    """Find all .scad files in src_dir, excluding specified directories and hidden folders."""
    if exclude_dirs is None:
        exclude_dirs = {"makerworld", ".git", "dist", ".vscode", ".idea", "__pycache__", "lib"}
    else:
        exclude_dirs = {d.lower() for d in exclude_dirs}

    src_path = Path(src_dir).resolve()
    scad_files = []

    for root, dirs, files in os.walk(src_path):
        root_path = Path(root).resolve()

        # Prune excluded directories in-place so os.walk does not descend into them
        dirs[:] = [
            d for d in dirs
            if d.lower() not in exclude_dirs
            and not d.startswith(".")
            and (root_path / d) != src_path / "makerworld"
            and (root_path / d) != src_path / "dist"
        ]

        for file in sorted(files):
            if file.lower().endswith(".scad"):
                file_full = root_path / file
                rel_path = file_full.relative_to(src_path)
                scad_files.append((file_full, rel_path))

    scad_files.sort(key=lambda item: str(item[1]).lower())
    return scad_files


def compile_single_file(openscad_exe, src_file, dest_file, env, timeout=300):
    """
    Invokes OpenSCAD's -o export function to produce a standalone single-file script.
    Tries direct --export-format csg -o dest.scad first, with a fallback to
    exporting .csg and copying to destination.
    """
    dest_file = Path(dest_file)
    dest_file.parent.mkdir(parents=True, exist_ok=True)

    t0 = time.time()

    # Primary method: Direct export using --export-format csg
    cmd = [
        openscad_exe,
        "--export-format", "csg",
        "-o", str(dest_file),
        str(src_file)
    ]

    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
            timeout=timeout
        )
        elapsed = time.time() - t0

        if proc.returncode == 0 and dest_file.is_file() and dest_file.stat().st_size > 0:
            return True, dest_file.stat().st_size, elapsed, proc.stdout + proc.stderr

        # Fallback method: Export to a temporary .csg and rename/copy to .scad
        temp_csg = dest_file.with_suffix(".temp.csg")
        cmd_fallback = [
            openscad_exe,
            "-o", str(temp_csg),
            str(src_file)
        ]

        proc_fallback = subprocess.run(
            cmd_fallback,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
            timeout=timeout
        )
        elapsed = time.time() - t0

        if proc_fallback.returncode == 0 and temp_csg.is_file():
            shutil.move(str(temp_csg), str(dest_file))
            return True, dest_file.stat().st_size, elapsed, proc_fallback.stdout + proc_fallback.stderr
        else:
            if temp_csg.is_file():
                temp_csg.unlink()
            err_msg = (proc.stderr or proc.stdout or proc_fallback.stderr or proc_fallback.stdout).strip()
            return False, 0, elapsed, err_msg

    except subprocess.TimeoutExpired:
        return False, 0, timeout, f"Build timed out after {timeout} seconds"
    except Exception as e:
        return False, 0, time.time() - t0, str(e)


def main():
    default_src, default_dist = get_default_paths()

    parser = argparse.ArgumentParser(
        description="Build single-file SCAD scripts for MakerWorld using OpenSCAD's -o export function."
    )
    parser.add_argument(
        "--src",
        type=str,
        default=str(default_src),
        help=f"Parent directory containing source files (default: {default_src})"
    )
    parser.add_argument(
        "--dist",
        type=str,
        default=str(default_dist),
        help=f"Target output directory (default: {default_dist})"
    )
    parser.add_argument(
        "--openscad",
        type=str,
        default=None,
        help="Path to openscad executable (autodetected if omitted)"
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Clean target dist directory before building"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List files that would be compiled without running OpenSCAD"
    )
    parser.add_argument(
        "--filter",
        type=str,
        default=None,
        help="Filter source files by substring or relative path pattern"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=min(4, os.cpu_count() or 1),
        help="Number of concurrent OpenSCAD processes (default: up to 4)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=300,
        help="Timeout in seconds per file (default: 300)"
    )

    args = parser.parse_args()

    src_dir = Path(args.src).resolve()
    dist_dir = Path(args.dist).resolve()

    print("=" * 72)
    print("MakerWorld OpenSCAD Single-File Builder")
    print("=" * 72)
    print(f"Source Directory:      {src_dir}")
    print(f"Output Directory:      {dist_dir}")

    # Discover SCAD files
    scad_files = discover_scad_files(src_dir)
    if args.filter:
        flt = args.filter.lower()
        scad_files = [item for item in scad_files if flt in str(item[1]).lower()]

    if not scad_files:
        print("\nNo matching .scad files found.")
        return 0

    print(f"Discovered Files:      {len(scad_files)} .scad file(s)")

    if args.dry_run:
        print("\n[Dry Run] Planned mirror output structure:")
        for src_file, rel_path in scad_files:
            target_path = dist_dir / rel_path
            print(f"  {rel_path} -> {target_path}")
        print("\nDry run completed.")
        return 0

    # Locate OpenSCAD executable
    openscad_exe = find_openscad(args.openscad)
    if not openscad_exe:
        print("\n[ERROR] OpenSCAD executable could not be found.")
        print("Please ensure OpenSCAD is installed, or pass the path via:")
        print("  python build.py --openscad <path_to_openscad>")
        print("or set the OPENSCAD environment variable.")
        return 1

    print(f"OpenSCAD Executable:   {openscad_exe}")
    print(f"Concurrent Workers:    {args.workers}")
    print("-" * 72)

    # Clean dist directory if requested
    if args.clean and dist_dir.exists():
        print(f"Cleaning {dist_dir} ...")
        shutil.rmtree(dist_dir)
    dist_dir.mkdir(parents=True, exist_ok=True)

    # Prepare environment with OPENSCADPATH
    env = os.environ.copy()
    lib_paths = [
        str(src_dir),
        str(Path.home() / "Documents" / "OpenSCAD" / "libraries"),
    ]
    existing_openpath = env.get("OPENSCADPATH", "")
    if existing_openpath:
        lib_paths.append(existing_openpath)
    env["OPENSCADPATH"] = os.pathsep.join(lib_paths)

    start_total_time = time.time()
    results = []

    def task(item):
        src_path, rel_path = item
        target_path = dist_dir / rel_path
        success, size_bytes, elapsed, logs = compile_single_file(
            openscad_exe, src_path, target_path, env, timeout=args.timeout
        )
        return rel_path, target_path, success, size_bytes, elapsed, logs

    total = len(scad_files)
    completed_count = 0
    success_count = 0
    fail_count = 0

    # Use ThreadPoolExecutor for concurrent building
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(task, item): item for item in scad_files}

        for future in as_completed(futures):
            completed_count += 1
            rel_path, target_path, success, size_bytes, elapsed, logs = future.result()
            results.append((rel_path, success, size_bytes, elapsed, logs))

            status_str = "OK" if success else "FAIL"
            size_str = f"{size_bytes / 1024:.1f} KB" if success else "0 KB"
            print(f"[{completed_count:>2}/{total}] [{status_str:>4}] {rel_path} ({elapsed:.1f}s, {size_str})")

            if success:
                success_count += 1
            else:
                fail_count += 1
                if logs:
                    # Print first few lines of error log indented
                    err_lines = logs.strip().splitlines()
                    for line in err_lines[:4]:
                        print(f"         ! {line}")

    total_time = time.time() - start_total_time

    print("=" * 72)
    print(f"Build Complete in {total_time:.2f} seconds")
    print(f"Total: {total} | Succeeded: {success_count} | Failed: {fail_count}")
    print(f"Dist Location: {dist_dir}")
    print("=" * 72)

    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

