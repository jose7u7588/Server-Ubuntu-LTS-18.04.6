#!/bin/bash

echo "==============================================="
echo " Instalador automático de x11vnc"
echo " Ubuntu 18.04.6 LTS — Escritorio real :0"
echo "==============================================="

# 1. Actualizar sistema
echo "[1/10] Actualizando sistema..."
sudo apt update -y && sudo apt upgrade -y

# 2. Instalar SSH Server
echo "[2/10] Instalando OpenSSH Server..."
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# 3. Instalar x11vnc
echo "[3/10] Instalando x11vnc..."
sudo apt install x11vnc -y

# 4. Crear contraseña VNC
echo "[4/10] Configurando contraseña VNC..."
mkdir -p ~/.vnc
x11vnc -storepasswd 123456 ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# 5. Crear servicio systemd para iniciar x11vnc en DISPLAY :0
echo "[5/10] Creando servicio systemd para x11vnc..."

sudo bash -c 'cat > /etc/systemd/system/x11vnc.service << EOF
[Unit]
Description=Servidor VNC x11vnc sobre escritorio real :0
After=display-manager.service

[Service]
Type=simple
User='${SUDO_USER}'
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -usepw -forever -shared -rfbport 5900 -noxdamage
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

# 6. Abrir puerto 5900 en LAN
echo "[6/10] Abriendo puerto 5900/tcp en firewall..."
sudo ufw allow 5900/tcp

# 7. Instalar Tailscale (opcional)
echo "[7/10] Instalando Tailscale (opcional)..."
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable tailscaled
sudo systemctl start tailscaled

echo ">>> Para activar Tailscale después de este script, ejecuta:"
echo "sudo tailscale up"

# 8. Obtener IP local (LAN)
echo "[8/10] Obteniendo IP local..."
LAN_IP=$(hostname -I | awk '{print $1}')

# 9. Obtener IP pública
echo "[9/10] Obteniendo IP pública..."
PUBLIC_IP=$(curl -s ifconfig.me)

# 10. Obtener IP Tailscale (si existe)
echo "[10/10] Obteniendo IP Tailscale..."
TAILSCALE_IP=$(ip -4 addr show tailscale0 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)

echo "==============================================="
echo "           INFORMACIÓN DE CONEXIÓN"
echo "==============================================="
echo " ➤ IP Local (LAN):        $LAN_IP"
echo " ➤ IP Pública (WAN):      $PUBLIC_IP"

if [ -z "$TAILSCALE_IP" ]; then
    echo " ➤ IP Tailscale:          (No conectado aún)"
else
    echo " ➤ IP Tailscale:          $TAILSCALE_IP"
fi

echo ""
echo " • Puerto VNC: 5900"
echo " • Display usado: :0"
echo " • Comando de prueba LAN:"
echo "      vncviewer $LAN_IP:5900"
echo ""
echo "==============================================="
echo " Instalación completada."
echo " x11vnc está activo y funcionando sobre DISPLAY :0"