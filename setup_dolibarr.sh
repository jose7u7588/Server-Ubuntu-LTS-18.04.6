#!/bin/bash
# setup_dolibarr.sh
# Script para instalar Dolibarr 21.0.0 en Ubuntu 18.04 + Tailscale

# ---------------------------------------------------
# Variables configurables
DOLI_USER="doliuser"
DOLI_PASS="changeme123"
DOLI_DB="dolibarr"
DOLI_ROOT="/var/www/html/dolibarr"
DOLI_DOCS="/var/www/html/dolibarr/documents"

# ---------------------------------------------------
echo "### Actualizando repositorios y paquetes"
sudo apt update && sudo apt upgrade -y

echo "### Instalando Apache y MySQL"
sudo apt install apache2 mysql-server -y

echo "### Instalando PHP 7.2 y extensiones necesarias"
sudo apt install php7.2 php7.2-cli php7.2-common php7.2-mysql php7.2-gd \
php7.2-xml php7.2-intl php7.2-mbstring php7.2-curl php7.2-zip php7.2-opcache -y

echo "### Reiniciando Apache"
sudo systemctl restart apache2

# ---------------------------------------------------
echo "### Creando base de datos y usuario para Dolibarr"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DOLI_DB} CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DOLI_USER}'@'localhost' IDENTIFIED BY '${DOLI_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DOLI_DB}.* TO '${DOLI_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# ---------------------------------------------------
echo "### Descargando Dolibarr 21.0.0"
cd /tmp
wget https://sourceforge.net/projects/dolibarr/files/Dolibarr%20ERP-CRM/21.0.0/dolibarr-21.0.0.tgz
tar xzf dolibarr-21.0.0.tgz
sudo mv dolibarr-21.0.0 ${DOLI_ROOT}
sudo mkdir -p ${DOLI_DOCS}

echo "### Configurando permisos"
sudo chown -R www-data:www-data ${DOLI_ROOT}
sudo find ${DOLI_ROOT} -type d -exec chmod 755 {} \;
sudo find ${DOLI_ROOT} -type f -exec chmod 644 {} \;

# ---------------------------------------------------
echo "### Configurando Apache VirtualHost para Dolibarr"
DOLI_CONF="/etc/apache2/sites-available/dolibarr.conf"
sudo bash -c "cat > ${DOLI_CONF}" <<EOL
<VirtualHost *:80>
    ServerAdmin admin@dolibarr.local
    DocumentRoot ${DOLI_ROOT}/htdocs
    ServerName dolibarr

    <Directory ${DOLI_ROOT}/htdocs>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/dolibarr_error.log
    CustomLog \${APACHE_LOG_DIR}/dolibarr_access.log combined
</VirtualHost>
EOL

sudo a2ensite dolibarr.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# ---------------------------------------------------
echo "### Instalando Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# ---------------------------------------------------
echo "### Creando archivo manual"
MANUAL="/root/MANUAL_DOLIBARR.txt"
sudo bash -c "cat > ${MANUAL}" <<EOL
Dolibarr 21.0.0 en Ubuntu 18.04 LTS
-------------------------------------

1. Servidor web: Apache 2.4
   DocumentRoot: ${DOLI_ROOT}/htdocs
   VirtualHost: /etc/apache2/sites-available/dolibarr.conf

2. Base de datos: MySQL
   Usuario: ${DOLI_USER}
   Contraseña: ${DOLI_PASS}
   Base de datos: ${DOLI_DB}
   Puerto: 3306
   Charset: utf8

3. Permisos:
   Directorios: 755
   Archivos: 644
   Propietario: www-data:www-data

4. Acceso remoto seguro con Tailscale:
   - Instalar Tailscale en servidor y dispositivos externos
   - Conectar con la misma cuenta
   - Obtener IP de Tailscale:
     tailscale ip -4
   - Acceso vía navegador:
     http://<IP_TAILSCALE>/

5. Archivo de configuración Dolibarr: ${DOLI_ROOT}/htdocs/conf/conf.php
   Configurar:
     \$dolibarr_main_url_root='http://<IP_TAILSCALE>/';
     \$dolibarr_main_document_root='${DOLI_ROOT}/htdocs';
     \$dolibarr_main_data_root='${DOLI_DOCS}';
     \$dolibarr_main_db_host='localhost';
     \$dolibarr_main_db_name='${DOLI_DB}';
     \$dolibarr_main_db_user='${DOLI_USER}';
     \$dolibarr_main_db_pass='${DOLI_PASS}';

6. Reiniciar Apache si se hacen cambios:
   sudo systemctl restart apache2

-------------------------------------
Manual generado automáticamente.
EOL

echo "### ¡Instalación y configuración completadas!"
echo "Manual de uso disponible en: ${MANUAL}"

