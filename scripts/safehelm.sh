#!/bin/bash

function isEncrypted() (
    local file="$1"
    if [ -z "$file" ]; then
        echo "Error: No file specified for encryption check."
        return 1
    fi

    grep -q 'ENC\[' "$file" && {
        echo "'$file' is encrypted."
        return 0
    } || {
        echo "'$file' is not encrypted."
        return 1
    }
)



function safehelm() {
    # verify dependencies
    which jq > /dev/null 2>&1 || { echo "jq is not installed. Please install it by running 'sudo apt-get install jq'"; return 1; }
    which helm > /dev/null 2>&1 || { echo "helm is not installed. Please install it"; return 1; }
    which sops > /dev/null 2>&1 || { echo "sops is not installed. Please install it"; return 1; }

    env=$(kubectl config view --minify --output 'jsonpath={..current-context}');
    namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}');
    key="${env}//${namespace}"
    valuefile=""

    test -f ./map.json || { 
        echo "Error: ./map.json not found"; return 1; 
    }

    filename=$(jq -r ".\"${key}\"" map.json)
    if [ $? -gt 0 ]; then
        echo -e "Error reading map.json"; 
        return 1;
    fi

    if [ "$filename" == "null" ]; then
        echo -e "Error: values file not found for the current environment and namespace"; 
        return 1;
    fi

    test -f "$filename" || {
        echo "Error:'$filename' not found"; 
        return 1;
    }

    valuefile="-f $filename"


    echo -e "--------------------------------------------------------------"
    echo -e "Environment\t: \033[0;32m$env\033[0m"
    echo -e "Namespace\t: \033[0;32m$namespace\033[0m"
    echo -e "Command  \t: \033[0;32mhelm $@ $valuefile\033[0m"
    echo -e "--------------------------------------------------------------"

    read -p "Are you sure you want to continue? Press CTRL+C to stop. Press Enter to continue..." -n 1 -r

    isEncrypted "$filename" && {
        echo -e "Decrypting values file."
        sops -d "$filename" > /tmp/decrypted_values.yaml
        valuefile="-f /tmp/decrypted_values.yaml"
    }

    helm $@ $valuefile

    test -f /tmp/decrypted_values.yaml && rm -f /tmp/decrypted_values.yaml;
}

safehelm "$@"