set shell := ["bash","-c"]


install-tools:
    echo "Installing tools..."
    ./scripts/localsetup.sh

get-helpers:
    # Optinal: These are helper scripts/commands. 
    echo "Fetching helper scripts..."
    git clone https://github.com/malayh/helpers.git && cd helpers && ./install
    rm -rf helpers