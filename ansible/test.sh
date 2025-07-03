#!/bin/bash
# Test script for Jenkins Infrastructure Ansible migration

set -e

echo "Starting Ansible tests..."

# Change to the directory containing this script
cd "$(dirname "$0")"

# Install Python dependencies
echo "Installing Python test dependencies..."
pip install -r test-requirements.txt

# Run ansible-lint
echo "Running ansible-lint..."
ansible-lint archives.yml

# Run Molecule tests
echo "Running Molecule tests..."
molecule test

echo "All tests passed!"
