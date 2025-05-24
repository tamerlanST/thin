#!/bin/bash

set -e

USERNAME="${SUDO_USER:-$(whoami)}"
HOME_DIR=$(eval echo "~$USERNAME")
RDP_SERVER="35.179.130.236"  # ← Укажи свой сервер

echo "[1/8] Настраиваем для пользователя: $USERNAME (home: $HOME_DIR)"

echo "[2/8] Установка X и FreeRDP + драйверы..."
apt update
apt install --no-install-recommends -y \
  xinit xserver-xorg freerdp2-x11 openbox linux-firmware

echo "[3/8] Настройка .xinitrc (если нужно)..."
if [ ! -f "$HOME_DIR/.xinitrc" ]; then
  cat > "$HOME_DIR/.xinitrc" <<EOF
#!/bin/bash
while true; do
  xfreerdp /v:$RDP_SERVER /u: /f /cert-ignore
  sleep 3
done
EOF
  chmod +x "$HOME_DIR/.xinitrc"
  chown $USERNAME:$USERNAME "$HOME_DIR/.xinitrc"
else
  echo ".xinitrc уже есть — оставляем."
fi

echo "[4/8] Настройка .bash_profile (если нужно)..."
if [ ! -f "$HOME_DIR/.bash_profile" ]; then
  cat > "$HOME_DIR/.bash_profile" <<EOF
[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && startx
EOF
  chown $USERNAME:$USERNAME "$HOME_DIR/.bash_profile"
else
  echo ".bash_profile уже есть — оставляем."
fi

echo "[5/8] Включаем автологин в tty1..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

echo "[6/8] Настройка X11 конфигурации для AMD (modesetting)..."
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/10-amdgpu.conf <<EOF
Section "Device"
    Identifier "AMD"
    Driver "modesetting"
EndSection
EOF

echo "[7/8] Отключаем GDM и переходим в консольный режим..."
systemctl disable gdm3 2>/dev/null || true
systemctl set-default multi-user.target

echo "[8/8] Готово. Перезагрузи систему: sudo reboot"
