FROM quay.io/fedora/fedora-bootc:40 AS silverblue-fusion

# -------------------------------------------------------------------------
# INSTALLATION DE RPM FUSION ET AUTRES DÉPÔTS
# (Cette partie ne change pas)
# -------------------------------------------------------------------------
RUN dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN set -eux; \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc; \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo; \
    curl -fsSL https://repository.mullvad.net/rpm/stable/mullvad.repo -o /etc/yum.repos.d/mullvad.repo; \
    curl -fsSL https://repository.mullvad.net/rpm/mullvad-keyring.asc -o /etc/pki/rpm-gpg/mullvad-keyring.asc; \
    rpm --import /etc/pki/rpm-gpg/mullvad-keyring.asc

# -------------------------------------------------------------------------
# INSTALLATION DE L'ENVIRONNEMENT DE BUREAU
# C'est l'étape cruciale qui manquait.
# On installe le groupe de paquets qui correspond à Fedora Workstation.
# -------------------------------------------------------------------------
RUN dnf groupinstall -y "Fedora Workstation"

# -------------------------------------------------------------------------
# PRÉPARATION POUR MULLVAD VPN (ne change pas)
# -------------------------------------------------------------------------
RUN mkdir -p "/var/opt/Mullvad VPN/resources/" && \
    touch "/var/opt/Mullvad VPN/resources/mullvad-setup" && \
    mkdir -p /var/log/mullvad-vpn/

# -------------------------------------------------------------------------
# INSTALLATION DES PAQUETS SUPPLÉMENTAIRES
# On utilise maintenant dnf pour tous les paquets.
# -------------------------------------------------------------------------
RUN dnf install -y \
    fish \
    code \
    mullvad-vpn \
    podman-compose \
    ffmpegthumbnailer

# -------------------------------------------------------------------------
# INSTALLATION DE FFMPEG ET DES PAQUETS MULTIMÉDIA
# (Ces commandes ne changent pas, mais doivent être après l'installation des dépôts)
# -------------------------------------------------------------------------
RUN dnf -y swap ffmpeg-free ffmpeg --allowerasing
RUN dnf group install multimedia -y
RUN dnf -y swap mesa-va-drivers mesa-va-drivers-freeworld
RUN dnf -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

# -------------------------------------------------------------------------
# CONFIGURATION DU SYSTÈME
# 1. On s'assure que le système démarre en mode graphique par défaut.
# 2. On active le service Mullvad.
# 3. On nettoie les caches pour réduire la taille de l'image.
# -------------------------------------------------------------------------
RUN systemctl set-default graphical.target && \
    systemctl enable mullvad-daemon.service && \
    dnf clean all