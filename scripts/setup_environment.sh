#!/bin/bash
# UnixPi Environment Setup Script
# Configures development and runtime environments

set -e

# Configuration
VENV_DIR="venv"
PYTHON_VERSION="3.9"
LOG_FILE="setup.log"
SYSTEM_DEPS=(
    python3-dev
    python3-venv
    build-essential
    libssl-dev
    libffi-dev
    libpcap-dev
    libbluetooth-dev
    libhidapi-dev
    libusb-1.0-0-dev
    pkg-config
    git
)

# Initialize logging
setup_logging() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    echo "Starting setup at $(date)"
}

# Check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check Python version
    if ! command -v python$PYTHON_VERSION &> /dev/null; then
        echo "Python $PYTHON_VERSION not found. Installing..."
        sudo apt-get update
        sudo apt-get install -y python$PYTHON_VERSION python$PYTHON_VERSION-dev
    fi
    
    # Check system dependencies
    echo "Installing system dependencies..."
    sudo apt-get update
    sudo apt-get install -y "${SYSTEM_DEPS[@]}"
}

# Set up virtual environment
setup_venv() {
    echo "Setting up virtual environment..."
    
    # Create virtual environment
    python$PYTHON_VERSION -m venv $VENV_DIR
    
    # Activate virtual environment
    source $VENV_DIR/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip setuptools wheel
}

# Install dependencies
install_dependencies() {
    echo "Installing project dependencies..."
    
    # Install development dependencies
    pip install -r requirements-dev.txt
    
    # Install project in development mode
    pip install -e .
}

# Configure git hooks
setup_git_hooks() {
    echo "Configuring git hooks..."
    
    # Install pre-commit
    pre-commit install
    
    # Create pre-commit config if it doesn't exist
    if [ ! -f .pre-commit-config.yaml ]; then
        cat > .pre-commit-config.yaml << EOF
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files
-   repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
    -   id: black
-   repo: https://github.com/PyCQA/flake8
    rev: 6.1.0
    hooks:
    -   id: flake8
-   repo: https://github.com/PyCQA/isort
    rev: 5.12.0
    hooks:
    -   id: isort
-   repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.5.1
    hooks:
    -   id: mypy
        additional_dependencies: [types-all]
EOF
    fi
}

# Run tests
run_tests() {
    echo "Running tests..."
    pytest tests/ --cov=unixpi --cov-report=xml
}

# Set up documentation
setup_docs() {
    echo "Setting up documentation..."
    
    # Create docs directory if it doesn't exist
    mkdir -p docs/source
    
    # Initialize Sphinx documentation
    if [ ! -f docs/source/conf.py ]; then
        cd docs
        sphinx-quickstart -q -p UnixPi -a "GhostSec" -v $(cat ../VERSION) -r $(cat ../VERSION) -l en --ext-autodoc --ext-viewcode --makefile --batchfile
        cd ..
    fi
}

# Create development tools
create_dev_tools() {
    echo "Creating development tools..."
    
    # Create Makefile if it doesn't exist
    if [ ! -f Makefile ]; then
        cat > Makefile << EOF
.PHONY: install test lint format clean docs

install:
	./scripts/setup_environment.sh

test:
	pytest tests/ --cov=unixpi --cov-report=xml

lint:
	flake8 unixpi tests
	mypy unixpi tests
	black --check unixpi tests
	isort --check-only unixpi tests

format:
	black unixpi tests
	isort unixpi tests

clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info
	rm -rf .coverage
	rm -rf coverage.xml
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf docs/_build
	find . -type d -name __pycache__ -exec rm -rf {} +

docs:
	cd docs && make html
EOF
    fi
}

# Main setup sequence
main() {
    echo "Starting UnixPi environment setup..."
    
    setup_logging
    check_requirements
    setup_venv
    install_dependencies
    setup_git_hooks
    run_tests
    setup_docs
    create_dev_tools
    
    echo "Environment setup completed successfully!"
    echo "Activate the virtual environment with: source $VENV_DIR/bin/activate"
    return 0
}

# Execute main function
main "$@"
