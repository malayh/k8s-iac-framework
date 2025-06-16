#!/bin/bash
# This script setups up tools to operate the clusters

#
# Note: This script is tested on Ubuntu. Feel free to modify it for your OS. Consider submitting a PR if you make it work on another OS.
#

RC_FILE="$HOME/.bashrc"


#
# Make
#
which make > /dev/null || {
    echo "Installing Make";
    sudo apt-get update
    sudo apt-get install -y make
} && echo "Make installed."

#
# unzip 
#
which unzip > /dev/null || {
    echo "Installing unzip";
    sudo apt-get update
    sudo apt-get install -y unzip
} && echo "unzip installed."


# 
# OpenTofu
#
which tofu > /dev/null || {
    echo "Installing OpenTofu";
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb
    rm -f install-opentofu.sh
} && echo "OpenTofu installed."

test -f $HOME/.terraformrc && echo ".terraformrc already exists, skipping creation." || {
    echo "plugin_cache_dir   = \"$HOME/.terraform.d/plugin-cache/\""  > $HOME/.terraformrc
    echo "disable_checkpoint = true" >> $HOME/.terraformrc
    mkdir -p $HOME/.terraform.d/plugin-cache/
    echo ".terraformrc created."
}

#
# Helm
#
which helm > /dev/null || {
    echo "Installing Helm";
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm -f get_helm.sh

    echo "export HELM_CACHE_HOME=$HOME/.helm/cache" >> $RC_FILE
    echo "export HELM_DATA_HOME=$HOME/.helm/data" >> $RC_FILE
    mkdir -p $HOME/.helm/cache
    mkdir -p $HOME/.helm/data

} && echo "Helm installed."

#
# Kubectl
#
which kubectl > /dev/null || {
    echo "Installing kubectl";
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo chmod 777 kubectl
    sudo mv kubectl /usr/local/bin/
} && echo "Kubectl installed."

#
# Terragrunt
#
which terragrunt > /dev/null || {
    echo "Installing Terragrunt";
    set -euo pipefail

    OS="linux"
    ARCH="amd64"
    VERSION="v0.69.10"
    BINARY_NAME="terragrunt_${OS}_${ARCH}"

    # Download the binary
    curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/$VERSION/$BINARY_NAME" -o "$BINARY_NAME"

    # Generate the checksum
    CHECKSUM="$(sha256sum "$BINARY_NAME" | awk '{print $1}')"

    # Download the checksum file
    curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/$VERSION/SHA256SUMS" -o SHA256SUMS

    # Grab the expected checksum
    EXPECTED_CHECKSUM="$(grep "$BINARY_NAME" <SHA256SUMS | awk '{print $1}')"

    # Compare the checksums
    if [ "$CHECKSUM" == "$EXPECTED_CHECKSUM" ]; then
        echo "Checksums match!"
        sudo mv "$BINARY_NAME" /usr/local/bin/terragrunt
        chmod +x /usr/local/bin/terragrunt
    else
        echo "Checksums do not match!"
    fi

    rm -f SHA256SUMS
}

#
# AWS CLI
#
which aws > /dev/null || {
    echo "Installing AWS CLI";
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -f awscliv2.zip
    rm -rf aws
} && echo "AWS CLI installed."