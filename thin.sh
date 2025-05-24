#!/bin/bash

set -e

USERNAME="${SUDO_USER:-$(whoami)}"
HOME_DIR=$(eval echo "~$USERNAME")
RDP_SERVER="192.168.1.100"  # Укажи IP или hostname сервера

echo "[1/6] Настраиваем для пользователя: $USERNAME (home: $HOME_DIR)"

echo "[2/6] Установка X и FreeRDP..."
apt update
apt install --no-install-recommends -y xinit xserver-xorg freerdp2-x11 openbox

echo "[3/6] Проверяем .xinitrc..."
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
  echo "Создан .xinitrc"
else
  echo ".xinitrc уже существует — оставляем как есть."
fi

echo "[4/6] Проверяем .bash_profile..."
if [ ! -f "$HOME_DIR/.bash_profile" ]; then
  cat > "$HOME_DIR/.bash_profile" <<EOF
[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && startx
EOF
  chown $USERNAME:$USERNAME "$HOME_DIR/.bash_profile"
  echo "Создан .bash_profile"
else
  echo ".bash_profile уже существует — оставляем как есть."
fi

echo "[5/6] Включаем autologin в tty1..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

echo "[6/6] Отключаем GDM и переходим в текстовый режим..."
systemctl disable gdm3 || true
systemctl set-default multi-user.target

echo ""
echo "✅ Готово. Перезагрузи систему: sudo reboot"
echo "Ubuntu должна загрузиться сразу в RDP-сессию от имени $USERNAME."
