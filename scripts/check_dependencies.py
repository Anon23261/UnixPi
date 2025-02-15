#!/usr/bin/env python3
"""
UnixPi Dependency Checker
Validates all required dependencies and their versions
"""

import pkg_resources
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple


def check_python_version() -> bool:
    """Check if Python version meets requirements."""
    required_version = (3, 8)
    current_version = sys.version_info[:2]
    return current_version >= required_version


def get_installed_packages() -> Dict[str, str]:
    """Get all installed Python packages and their versions."""
    return {pkg.key: pkg.version for pkg in pkg_resources.working_set}


def read_requirements(file_path: str) -> List[Tuple[str, str]]:
    """Read requirements from file and return package name and version."""
    requirements = []
    with open(file_path, "r") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                if ">=" in line:
                    name, version = line.split(">=")
                    requirements.append((name.strip(), version.strip()))
                else:
                    requirements.append((line, ""))
    return requirements


def check_system_dependencies() -> List[str]:
    """Check system dependencies."""
    missing = []
    dependencies = [
        "git",
        "gcc",
        "make",
        "pkg-config",
        "bluez",
        "libpcap-dev",
        "libhidapi-dev",
    ]

    for dep in dependencies:
        try:
            subprocess.run(["which", dep], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            missing.append(dep)

    return missing


def main():
    """Main function to check all dependencies."""
    print("UnixPi Dependency Checker")
    print("========================")

    # Check Python version
    print("\nChecking Python version...")
    if check_python_version():
        print("✓ Python version OK")
    else:
        print("✗ Python version must be 3.8 or higher")
        sys.exit(1)

    # Check system dependencies
    print("\nChecking system dependencies...")
    missing_deps = check_system_dependencies()
    if missing_deps:
        print("✗ Missing system dependencies:")
        for dep in missing_deps:
            print(f"  - {dep}")
        print("\nInstall missing dependencies with:")
        print("sudo apt-get install " + " ".join(missing_deps))
        sys.exit(1)
    else:
        print("✓ System dependencies OK")

    # Check Python packages
    print("\nChecking Python packages...")
    installed_packages = get_installed_packages()

    # Check core requirements
    requirements_file = Path(__file__).parent.parent / "requirements.txt"
    if requirements_file.exists():
        requirements = read_requirements(str(requirements_file))
        missing_packages = []
        outdated_packages = []

        for package, required_version in requirements:
            if package not in installed_packages:
                missing_packages.append(package)
            elif required_version and pkg_resources.parse_version(
                installed_packages[package]
            ) < pkg_resources.parse_version(required_version):
                outdated_packages.append(
                    (package, required_version, installed_packages[package])
                )

        if missing_packages:
            print("✗ Missing packages:")
            for package in missing_packages:
                print(f"  - {package}")

        if outdated_packages:
            print("✗ Outdated packages:")
            for package, required, installed in outdated_packages:
                print(f"  - {package}: installed={installed}, required>={required}")

        if not (missing_packages or outdated_packages):
            print("✓ All required packages are installed and up to date")
    else:
        print("! requirements.txt not found")

    # Summary
    print("\nDependency Check Summary")
    print("======================")
    if missing_deps or (
        requirements_file.exists() and (missing_packages or outdated_packages)
    ):
        print("✗ Some dependencies are missing or outdated")
        print("\nTo fix:")
        print("1. Run: ./scripts/setup_environment.sh")
        print("2. Activate virtual environment: source venv/bin/activate")
        print("3. Install dependencies: pip install -r requirements.txt")
        sys.exit(1)
    else:
        print("✓ All dependencies are satisfied")
        sys.exit(0)


if __name__ == "__main__":
    main()
