FROM ghcr.io/ublue-os/silverblue-main:latest AS fedora-workstation-fusion

RUN set -eux; \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc; \
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo; \
    curl -fsSL https://repository.mullvad.net/rpm/stable/mullvad.repo -o /etc/yum.repos.d/mullvad.repo; \
    curl -fsSL https://repository.mullvad.net/rpm/mullvad-keyring.asc -o /etc/pki/rpm-gpg/mullvad-keyring.asc; \
    rpm --import /etc/pki/rpm-gpg/mullvad-keyring.asc

# -------------------------------------------------------------------------
# PRÉPARATION POUR MULLVAD VPN (ne change pas)
# -------------------------------------------------------------------------
RUN mkdir -p "/var/opt/Mullvad VPN/resources/" && \
    touch "/var/opt/Mullvad VPN/resources/mullvad-setup" && \
    mkdir -p /var/log/mullvad-vpn/

# -------------------------------------------------------------------------
# INSTALLATION ET CONFIGURATION DES LOGICIELS SUPPLÉMENTAIRES
# -------------------------------------------------------------------------
RUN dnf install -y \
    fish \
    code \
    mullvad-vpn \
    podman-compose 

