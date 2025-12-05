#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root (sudo)." >&2
    exit 1
fi

podman build --pull -t localhost/my-os .

bootc switch --transport containers-storage localhost/my-os
bootc upgrade

# ---------------------------------------------------------
# 4. Nettoyage mensuel (une fois par mois)
# ---------------------------------------------------------
# On garde une trace du mois du dernier nettoyage dans un fichier
# Format stocké : YYYY-MM (ex: 2025-11)
STATE_FILE="/var/opt/my-os/.last_cleanup_month"
CURRENT_MONTH=$(date +%Y-%m)

LAST_MONTH=""
if [ -r "$STATE_FILE" ]; then
    LAST_MONTH=$(cat "$STATE_FILE" 2>/dev/null || echo "")
fi

if [ "$LAST_MONTH" != "$CURRENT_MONTH" ]; then
    echo "--> Nettoyage mensuel : exécution du pruning pour $CURRENT_MONTH"
    # IMPORTANT : Avec des tags uniques chaque jour, le nettoyage évite
    # l'accumulation d'images et de couches inutiles sur le disque.
    podman system prune -a -f

    # Enregistrer le mois courant pour éviter un deuxième nettoyage
    # pendant ce même mois.
    printf '%s' "$CURRENT_MONTH" > "$STATE_FILE"
else
    echo "--> Nettoyage déjà effectué ce mois-ci ($CURRENT_MONTH)."
fi