#!/bin/bash

# This script sets up a project repository using k8s-iac-framework
TEMP_DIR=$(mktemp -d)
REPO="https://github.com/malayh/k8s-iac-framework.git"

# Clone the repository
git clone "$REPO" "$TEMP_DIR" || {
    echo "Failed to clone repository."
    exit 1
}

rm -rf "$TEMP_DIR/.git"
mv "$TEMP_DIR"/* . || {
    echo "Failed to move files."
    exit 1
}

rm -rf "$TEMP_DIR"
echo "Installing dependencies..."
. scripts/localsetup.sh

echo "Repository setup complete."
echo "Read https://github.com/malayh/k8s-iac-framework/blob/main/README.md#usage for next steps"
