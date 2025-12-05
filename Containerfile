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
# 2. INSTALLATION GLOBALE
# -------------------------------------------------------------------------
RUN dnf install -y \
    fish \
    code \
    podman-compose \
    ffmpegthumbnailer

# -------------------------------------------------------------------------
# 3. MULLVAD VPN (VERSION CORRIGÉE & ROBUSTE)
# -------------------------------------------------------------------------
WORKDIR /tmp/mullvad-work

RUN dnf install -y dnf-plugins-core cpio policycoreutils && \
    dnf download --destdir=. mullvad-vpn && \
    rpm2cpio *.rpm | cpio -idmv

RUN cp -r usr/share/* /usr/share/ && \
    mv "opt/Mullvad VPN" /usr/lib/mullvad-vpn && \
    mv usr/bin/mullvad /usr/lib/mullvad-vpn/ && \
    mv usr/bin/mullvad-daemon /usr/lib/mullvad-vpn/

RUN chmod +x /usr/lib/mullvad-vpn/mullvad-vpn && \
    chmod +x /usr/lib/mullvad-vpn/mullvad-daemon && \
    chmod +x /usr/lib/mullvad-vpn/mullvad && \
    ln -sf "/usr/lib/mullvad-vpn/mullvad-vpn" /usr/bin/mullvad-vpn && \
    ln -sf "/usr/lib/mullvad-vpn/mullvad-gui" /usr/bin/mullvad-gui && \
    ln -sf "/usr/lib/mullvad-vpn/mullvad" /usr/bin/mullvad && \
    ln -sf "/usr/lib/mullvad-vpn/mullvad-daemon" /usr/bin/mullvad-daemon

RUN mkdir -p /usr/lib/tmpfiles.d && \
    echo "d  /var/log/mullvad-vpn    0755 root root -" > /usr/lib/tmpfiles.d/mullvad-vpn.conf && \
    echo "d  /var/cache/mullvad-vpn  0755 root root -" >> /usr/lib/tmpfiles.d/mullvad-vpn.conf && \
    echo "d  /etc/mullvad-vpn        0755 root root -" >> /usr/lib/tmpfiles.d/mullvad-vpn.conf && \
    echo "L+ \"/var/opt/Mullvad VPN\"  -    -    -    - /usr/lib/mullvad-vpn" >> /usr/lib/tmpfiles.d/mullvad-vpn.conf && \
    cp usr/lib/systemd/system/mullvad-daemon.service /usr/lib/systemd/system/ && \
    sed -i 's|ExecStart=.*|ExecStart=/usr/bin/mullvad-daemon -v --disable-stdout-timestamps|' /usr/lib/systemd/system/mullvad-daemon.service && \
    sed -i '/WorkingDirectory/d' /usr/lib/systemd/system/mullvad-daemon.service && \
    systemctl enable mullvad-daemon

RUN sed -i 's|Exec="/opt/Mullvad VPN/mullvad-vpn"|Exec="/usr/bin/mullvad-vpn"|' /usr/share/applications/mullvad-vpn.desktop && \
    sed -i 's|^Icon=.*|Icon=mullvad-vpn|' /usr/share/applications/mullvad-vpn.desktop

RUN echo '/usr/lib/mullvad-vpn(/.*)? system_u:object_r:bin_t:s0' >> /etc/selinux/targeted/contexts/files/file_contexts.local && \
    # On applique la règle immédiatement. OSTree la respectera aussi à la finalisation.
    restorecon -R -v /usr/lib/mullvad-vpn && \
    # Nettoyage
    cd / && rm -rf /tmp/mullvad-work

WORKDIR /

# -------------------------------------------------------------------------
# 4. NETTOYAGE & MULTIMEDIA
# -------------------------------------------------------------------------
RUN dnf remove firefox -y

RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf group install -y multimedia && \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld 

RUN dnf clean all
