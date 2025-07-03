#!/bin/bash

# Test script for the archives role

set -e

echo "Running ansible-lint on the archives role..."
ansible-lint .

echo "Running molecule test on the archives role..."
molecule test

echo "All tests passed!" 