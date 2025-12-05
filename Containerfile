FROM quay.io/fedora-ostree-desktops/silverblue:43 AS fedora-workstation-fusion

# -------------------------------------------------------------------------
    # 1. REPOS SETUP
    # -------------------------------------------------------------------------
        RUN dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        
        RUN set -eux; \
        rpm --import https://packages.microsoft.com/keys/microsoft.asc; \
        echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo; \
        curl -fsSL https://repository.mullvad.net/rpm/stable/mullvad.repo -o /etc/yum.repos.d/mullvad.repo; \
        curl -fsSL https://repository.mullvad.net/rpm/mullvad-keyring.asc -o /etc/pki/rpm-gpg/mullvad-keyring.asc; \
        rpm --import /etc/pki/rpm-gpg/mullvad-keyring.asc
        
# -------------------------------------------------------------------------
# 2. NETTOYAGE & MULTIMEDIA
# -------------------------------------------------------------------------
RUN dnf remove firefox -y

RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf group install -y multimedia && \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 

# -------------------------------------------------------------------------
# 3. INSTALLATION GLOBALE
# -------------------------------------------------------------------------
RUN dnf install -y \
    fish \
    code \
    podman-compose \
    ffmpegthumbnailer


RUN dnf clean all
