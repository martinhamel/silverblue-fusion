#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root (sudo)." >&2
    exit 1
fi

podman build --pull -t localhost/my-os .

bootc switch --transport containers-storage localhost/my-os
bootc upgrade

