#!/bin/bash

# Find and symlink 1c-enterprise-ring (required)
ring_path=$(find /opt/1C/1CE/components -name ring -type f -print -quit 2>/dev/null)
if [ -z "$ring_path" ]; then
    echo "::error::Could not find ring executable in /opt/1C/1CE" >&2
    exit 1
fi
sudo ln -sfn "$(dirname "$ring_path")" /opt/1C/1CE/components/1c-enterprise-ring

# Find and symlink 1cedtcli (optional)
edtcli_path=$(find /opt/1C/1CE/components -name 1cedtcli -type f -print -quit 2>/dev/null)
if [ -n "$edtcli_path" ]; then
    sudo ln -sfn "$(dirname "$edtcli_path")" /opt/1C/1CE/components/1cedtcli
fi

# Update PATH (only add directories that exist)
PATH="/opt/1C/1CE/components/1c-enterprise-ring:$PATH"
if [ -d "/opt/1C/1CE/components/1cedtcli" ]; then
    PATH="/opt/1C/1CE/components/1cedtcli:$PATH"
fi

echo "::group::Successfully added to PATH"
echo "/opt/1C/1CE/components/1c-enterprise-ring"
[ -d "/opt/1C/1CE/components/1cedtcli" ] && echo "/opt/1C/1CE/components/1cedtcli"
echo "::endgroup::"