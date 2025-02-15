#!/usr/bin/env python3

from setuptools import find_packages, setup

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

with open("requirements.txt", "r", encoding="utf-8") as f:
    requirements = [
        line.strip() for line in f if line.strip() and not line.startswith("#")
    ]

with open("VERSION", "r", encoding="utf-8") as f:
    version = f.read().strip()

setup(
    name="unixpi",
    version=version,
    author="GhostSec",
    author_email="ghost_sec@icloud.com",
    description="A comprehensive IoT and network security framework for Raspberry Pi",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Anon23261/UnixPi",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Information Technology",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Topic :: Security",
        "Topic :: System :: Hardware",
        "Topic :: System :: Systems Administration",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "unixpi=unixpi.cli:main",
            "unixpi-scan=unixpi.security.scanner:main",
            "unixpi-monitor=unixpi.security.monitor:main",
            "unixpi-config=unixpi.config.manager:main",
        ],
    },
    include_package_data=True,
    zip_safe=False,
)
