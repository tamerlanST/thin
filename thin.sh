#!/bin/bash

set -e

USERNAME="thinuser"
PASSWORD="ThinKurwaPassword!"         # Для локального входа, можно сменить
RDP_SERVER="35.179.130.236"       # ← Замените на свой сервер

echo "[1/7] Creating user $USERNAME..."
adduser --disabled-password --gecos "" "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

echo "[2/7] Installing minimal X + FreeRDP..."
apt update
apt install --no-install-recommends -y \
  xserver-xorg xinit openbox freerdp2-x11 \
  systemd-timesyncd

echo "[3/7] Enabling autologin on tty1..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

echo "[4/7] Setting up .bash_profile autostart..."
su - "$USERNAME" -c "cat > ~/.bash_profile" <<EOF
[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && startx
EOF

echo "[5/7] Setting up .xinitrc with xfreerdp..."
su - "$USERNAME" -c "cat > ~/.xinitrc" <<EOF
#!/bin/bash
while true; do
  xfreerdp /v:$RDP_SERVER /u: /f /cert-ignore
  sleep 3
done
EOF
chmod +x /home/$USERNAME/.xinitrc

echo "[6/7] Disabling Ubuntu splash (optional)..."
sed -i 's/quiet splash/quiet/' /etc/default/grub
update-grub

echo "[7/7] Done. Reboot to test the thin client."
#
