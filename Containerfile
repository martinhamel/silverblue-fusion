FROM quay.io/fedora/fedora-silverblue:latest

# -------------------------------------------------------------------------
# INSTALLATION DE RPM FUSION
# RPM Fusion fournit des paquets supplémentaires non inclus dans les
# dépôts Fedora officiels, souvent pour des raisons de licence ou
# de brevets.
# -------------------------------------------------------------------------
RUN dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# -------------------------------------------------------------------------
# INSTALLATION DE FFMPEG
# Le paquet ffmpeg n'est pas inclus par défaut dans Fedora en raison de
# problèmes de licence. Nous le remplaçons par la version de RPM Fusion.
# -------------------------------------------------------------------------
RUN dnf -y swap ffmpeg-free ffmpeg --allowerasing

# -------------------------------------------------------------------------
# MISES À JOUR DES PAQUETS MULTIMÉDIA
# On met à jour les paquets multimédia pour s'assurer d'avoir les
# dernières versions, tout en évitant de mettre à jour
# PackageKit-gstreamer-plugin qui peut causer des problèmes.
# -------------------------------------------------------------------------
RUN dnf group install multimedia -y

# -------------------------------------------------------------------------
# INSTALLATION DES PILOTES MULTIMÉDIA HARDWARE ACCELERATED AMD
# On remplace les pilotes multimédia par leurs versions non "freeworld" de
# RPM Fusion pour l'acceleration materielle.
# -------------------------------------------------------------------------
RUN dnf -y swap mesa-va-drivers mesa-va-drivers-freeworld
RUN dnf -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

# -------------------------------------------------------------------------
# AJOUT DES DÉPÔTS EXTERNES
# On regroupe toutes les opérations sur les dépôts en une seule étape
# pour optimiser le nombre de couches de l'image.
# -------------------------------------------------------------------------
RUN set -eux; \
    # Dépôt Microsoft pour VS Code
    rpm --import https://packages.microsoft.com/keys/microsoft.asc; \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo; \
    \
    # Dépôt Mullvad VPN
    curl -fsSL https://repository.mullvad.net/rpm/stable/mullvad.repo -o /etc/yum.repos.d/mullvad.repo; \
    curl -fsSL https://repository.mullvad.net/rpm/mullvad-keyring.asc -o /etc/pki/rpm-gpg/mullvad-keyring.asc; \
    rpm --import /etc/pki/rpm-gpg/mullvad-keyring.asc

# -------------------------------------------------------------------------
# PRÉPARATION POUR MULLVAD VPN
# Le script d'installation de Mullvad s'attend à ce que certains
# répertoires existent. /opt est un lien symbolique vers /var/opt sur
# les systèmes ostree, nous utilisons donc le chemin réel pour éviter
# les problèmes pendant la construction de l'image.
# -------------------------------------------------------------------------
RUN mkdir -p "/var/opt/Mullvad VPN/resources/" && \
    touch "/var/opt/Mullvad VPN/resources/mullvad-setup" && \
    mkdir -p /var/log/mullvad-vpn/

# -------------------------------------------------------------------------
# INSTALLATION DES PAQUETS
# On utilise rpm-ostree, la méthode standard pour les systèmes immuables
# comme Silverblue, pour installer les paquets.
# -------------------------------------------------------------------------
RUN dnf install -y \
    fish \
    code \
    mullvad-vpn \
    podman-compose \
    ffmpegthumbnailer

# -------------------------------------------------------------------------
# SUPPRESSION DE FIREFOX
# Firefox est installé par défaut sur Fedora Silverblue dans une configuration
# où il manque de certaines fonctionnalités multimédia. Utilisons plutôt
# Firefox Flatpak.
RUN dnf remove -y firefox

# -------------------------------------------------------------------------
# ACTIVATION DES SERVICES
# Le service du VPN est activé pour se lancer au démarrage.
# -------------------------------------------------------------------------
RUN systemctl enable mullvad-daemon