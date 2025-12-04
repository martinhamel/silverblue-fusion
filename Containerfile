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
# On installe le groupe Fedora Workstation en excluant le paquet 'rootfiles'
# qui entre en conflit avec les fichiers de l'image de base.
# -------------------------------------------------------------------------
RUN dnf groupinstall -y "Fedora Workstation" --exclude=rootfiles

# -------------------------------------------------------------------------
# PRÉPARATION POUR MULLVAD VPN (ne change pas)
# -------------------------------------------------------------------------
RUN mkdir -p "/var/opt/Mullvad VPN/resources/" && \
    touch "/var/opt/Mullvad VPN/resources/mullvad-setup" && \
    mkdir -p /var/log/mullvad-vpn/

# -------------------------------------------------------------------------
# INSTALLATION DES PAQUETS
# On utilise dnf, la méthode standard pour les images de conteneurs.
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
# CONFIGURATION FINALE
# On s'assure que le système démarre en mode graphique, on active le service
# Mullvad et on nettoie les caches pour réduire la taille de l'image.
# -------------------------------------------------------------------------
RUN systemctl set-default graphical.target && \
    systemctl enable mullvad-daemon.service && \
    dnf clean all