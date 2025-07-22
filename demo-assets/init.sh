#!/usr/bin/env bash


SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function generate_sample_clp_config {
    local ip=$(hostname -i)
    local file="${SCRIPT_PATH}/clp-config.yml"
    cp "$file" "${file}.bak"
    sed -i "s|\${REPLACE_IP}|$ip|g" "$file"
    echo "Replaced \${REPLACE_IP} with $ip in $file"
}

function update_metadata_config {
    if [[ $# -ne 1 ]]; then
        echo "Usage: update_metadata_config </path/to/clp-package>"
        return 1
    fi
 
    local clp_pkg_home=$1
    local clp_config_path="$(readlink -f ${clp_pkg_home})/etc/clp-config.yml"
    local credential_path="$(readlink -f ${clp_pkg_home})/etc/credentials.yml"
    host=$(yq r "$clp_config_path" 'database.host')
    port=$(yq r "$clp_config_path" 'database.port')
    name=$(yq r "$clp_config_path" 'database.name')
    user=$(yq r "$credential_path" 'database.user')
    password=$(yq r "$credential_path" 'database.password')
    echo "Metadata database host: $host"
    echo "Metadata database port: $port"
    echo "Metadata database name: $name"
    echo "Metadata database user: $user"
    echo "Metadata database password: $password"
    
    local values_yaml_path="${SCRIPT_PATH}/../values.yaml"
    cp "$values_yaml_path" "${values_yaml_path}.bak"
    yq w -i --style double "$values_yaml_path" 'presto.coordinator.config.clpProperties.metadata.database.url' "jdbc:mysql://${host}:${port}"
    yq w -i --style double "$values_yaml_path" 'presto.coordinator.config.clpProperties.metadata.database.name' "$name"
    yq w -i --style double "$values_yaml_path" 'presto.coordinator.config.clpProperties.metadata.database.user' "$user"
    yq w -i --style double "$values_yaml_path" 'presto.coordinator.config.clpProperties.metadata.database.password' "$password"
}

if declare -f "$1" > /dev/null; then
    "$@"
else
    echo "Error: '$1' is not a valid function name."
    echo "Available functions:"
    declare -F | awk '{print $3}'
    exit 1
fi
