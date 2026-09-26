#!/bin/bash

# ============================================================
# SCRIPT DEVPS - INSTALADOR CORREGIDO
# Repositorio:
# https://github.com/jorge415nivel/scriptdevpsgracias
# ============================================================

set -u

REPO="https://github.com/jorge415nivel/scriptdevpsgracias"
BRANCH="master"
ZIP_URL="${REPO}/archive/refs/heads/${BRANCH}.zip"

TMP_DIR="/tmp/scriptdevpsgracias-install"
ZIP_FILE="/tmp/scriptdevpsgracias-master.zip"

SCRIPT_DIR="/etc/SCRIPT"
ADM_DIR="/etc/adm-lite"
EXEC_DIR="/bin/ejecutar"

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

clear

echo -e "${CYAN}============================================================${RESET}"
echo -e "${CYAN}        SCRIPT DEVPS - INSTALADOR CORREGIDO${RESET}"
echo -e "${CYAN}============================================================${RESET}"
echo

# ------------------------------------------------------------
# ROOT
# ------------------------------------------------------------

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}ERROR: debes ejecutar este instalador como root.${RESET}"
    exit 1
fi

# ------------------------------------------------------------
# INSTALAR DEPENDENCIAS
# ------------------------------------------------------------

echo -e "${YELLOW}[1/7] Instalando dependencias...${RESET}"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y >/dev/null 2>&1

apt-get install -y \
    bc \
    screen \
    nano \
    curl \
    wget \
    unzip \
    zip \
    net-tools \
    netcat-openbsd \
    lsof \
    figlet \
    lolcat \
    gawk \
    apache2 \
    python3 \
    python3-pip \
    ca-certificates \
    procps \
    iproute2 \
    >/dev/null 2>&1

if ! command -v netstat >/dev/null 2>&1; then
    echo -e "${RED}ERROR: netstat no quedó instalado.${RESET}"
    exit 1
fi

if ! command -v lolcat >/dev/null 2>&1; then
    echo -e "${RED}ERROR: lolcat no quedó instalado.${RESET}"
    exit 1
fi

if ! command -v figlet >/dev/null 2>&1; then
    echo -e "${RED}ERROR: figlet no quedó instalado.${RESET}"
    exit 1
fi

echo -e "${GREEN}Dependencias OK.${RESET}"

# ------------------------------------------------------------
# PREPARAR DIRECTORIOS
# ------------------------------------------------------------

echo -e "${YELLOW}[2/7] Preparando directorios...${RESET}"

rm -rf "$TMP_DIR"

mkdir -p "$TMP_DIR"
mkdir -p "$SCRIPT_DIR"
mkdir -p "$ADM_DIR"
mkdir -p "$EXEC_DIR"

echo -e "${GREEN}Directorios OK.${RESET}"

# ------------------------------------------------------------
# DESCARGAR REPOSITORIO COMPLETO
# ------------------------------------------------------------

echo -e "${YELLOW}[3/7] Descargando tu repositorio...${RESET}"

rm -f "$ZIP_FILE"

if ! curl -fL --retry 3 --connect-timeout 15 \
    "$ZIP_URL" \
    -o "$ZIP_FILE" >/dev/null 2>&1; then

    echo -e "${RED}ERROR: no se pudo descargar el repositorio.${RESET}"
    exit 1
fi

if [ ! -s "$ZIP_FILE" ]; then
    echo -e "${RED}ERROR: el ZIP descargado está vacío.${RESET}"
    exit 1
fi

unzip -q "$ZIP_FILE" -d "$TMP_DIR"

REPO_DIR="$TMP_DIR/scriptdevpsgracias-master/BOT/gerador"

if [ ! -d "$REPO_DIR" ]; then
    echo -e "${RED}ERROR: no existe BOT/gerador dentro del repositorio.${RESET}"
    exit 1
fi

echo -e "${GREEN}Repositorio descargado correctamente.${RESET}"

# ------------------------------------------------------------
# COPIAR TODOS LOS ARCHIVOS DE BOT/GERADOR
# ------------------------------------------------------------

echo -e "${YELLOW}[4/7] Instalando archivos de BOT/gerador...${RESET}"

cp -a "$REPO_DIR"/. "$SCRIPT_DIR"/

# La lista del ZIP contiene "lista", pero ese archivo no existe.
# Lo eliminamos de la lista para evitar descargas falsas.
if [ -f "$SCRIPT_DIR/lista-arq" ]; then
    sed -i '/^lista$/d' "$SCRIPT_DIR/lista-arq"
fi

# Copiar también a /root para mantener compatibilidad
# con scripts antiguos que usan archivos por ruta relativa.
cp -a "$REPO_DIR"/. /root/

echo -e "${GREEN}Archivos instalados.${RESET}"

# ------------------------------------------------------------
# PERMISOS
# ------------------------------------------------------------

echo -e "${YELLOW}[5/7] Corrigiendo permisos...${RESET}"

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/menu 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/user 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/verifica 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/ferramentas 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/get 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/trans 2>/dev/null || true

# ------------------------------------------------------------
# ARCHIVOS DE INICIALIZACION
# ------------------------------------------------------------

echo -e "${YELLOW}[6/7] Creando estructura de ChumoGH/ADM...${RESET}"

# Versión local
if [ -f "$SCRIPT_DIR/v-local.log" ]; then
    cp -f "$SCRIPT_DIR/v-local.log" "$ADM_DIR/v-local.log"
else
    echo "V4.3" > "$ADM_DIR/v-local.log"
fi

echo "1" > "$ADM_DIR/versao_script"

# Nombre del servidor
if [ ! -s /root/name ]; then
    echo "VPS-VIP" > /root/name
fi

cp -f /root/name "$ADM_DIR/name"

# Archivo de éxito
if [ ! -s /root/exito ]; then
    echo "Verified [ SCRIPT DEVPS ] ADM" > /root/exito
fi

echo "Verified [ SCRIPT DEVPS ] ADM" > "$ADM_DIR/exito"

# Variables usadas por menu/cabecalho
echo "0" > "$EXEC_DIR/val"
echo "0" > "$EXEC_DIR/uskill"
echo "desactivado" > "$EXEC_DIR/val1"

date +"%d-%m-%y" > "$EXEC_DIR/fecha"

touch "$EXEC_DIR/key.fix"

chmod 755 "$EXEC_DIR"
chmod 755 "$ADM_DIR"
chmod 644 "$EXEC_DIR/val"
chmod 644 "$EXEC_DIR/uskill"
chmod 644 "$EXEC_DIR/val1"
chmod 644 "$EXEC_DIR/fecha"
chmod 644 "$EXEC_DIR/key.fix"

# ------------------------------------------------------------
# TRANS
# ------------------------------------------------------------

if [ -f "$SCRIPT_DIR/trans" ]; then
    cp -f "$SCRIPT_DIR/trans" /usr/bin/trans
    chmod +x /usr/bin/trans
fi

# ------------------------------------------------------------
# GERAR
# ------------------------------------------------------------

if [ -f "$SCRIPT_DIR/gerar.sh" ]; then
    cp -f "$SCRIPT_DIR/gerar.sh" /usr/bin/gerar.sh
    chmod +x /usr/bin/gerar.sh
fi

# ------------------------------------------------------------
# HTTP SERVER
# ------------------------------------------------------------

if [ -f "$SCRIPT_DIR/http-server.py" ]; then
    cp -f "$SCRIPT_DIR/http-server.py" /bin/http-server.sh
    chmod +x /bin/http-server.sh
fi

# ------------------------------------------------------------
# WRAPPER MENU
# ------------------------------------------------------------

cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash

cd /etc/SCRIPT || exit 1

exec bash /etc/SCRIPT/menu "$@"
EOF

chmod +x /usr/local/bin/menu

# ------------------------------------------------------------
# WRAPPER GERAR
# ------------------------------------------------------------

cat > /usr/local/bin/gerar <<'EOF'
#!/bin/bash

cd /etc/SCRIPT || exit 1

exec bash /usr/bin/gerar.sh "$@"
EOF

chmod +x /usr/local/bin/gerar

# También dejamos el comando en /usr/bin
cp -f /usr/local/bin/menu /usr/bin/menu
cp -f /usr/local/bin/gerar /usr/bin/gerar

chmod +x /usr/bin/menu
chmod +x /usr/bin/gerar

# ------------------------------------------------------------
# APACHE
# ------------------------------------------------------------

if [ -f /etc/apache2/ports.conf ]; then
    sed -i 's/^Listen 80$/Listen 81/g' /etc/apache2/ports.conf
fi

systemctl restart apache2 >/dev/null 2>&1 || true

# ------------------------------------------------------------
# VALIDACIONES
# ------------------------------------------------------------

echo -e "${YELLOW}[7/7] Verificando instalación...${RESET}"

ERROR=0

for FILE in \
    "$SCRIPT_DIR/menu" \
    "$SCRIPT_DIR/menu-txt" \
    "$SCRIPT_DIR/cabecalho" \
    "$SCRIPT_DIR/gerar.sh" \
    "$SCRIPT_DIR/idioma_geral" \
    "$SCRIPT_DIR/trans" \
    "$ADM_DIR/v-local.log" \
    "$ADM_DIR/versao_script" \
    "/root/name" \
    "/root/exito" \
    "$EXEC_DIR/val"
do

    if [ ! -s "$FILE" ]; then
        echo -e "${RED}FALTA: $FILE${RESET}"
        ERROR=1
    else
        echo -e "${GREEN}OK: $FILE${RESET}"
    fi

done

# Validar sintaxis
bash -n "$SCRIPT_DIR/menu" >/dev/null 2>&1 || ERROR=1
bash -n "$SCRIPT_DIR/menu-txt" >/dev/null 2>&1 || ERROR=1
bash -n "$SCRIPT_DIR/cabecalho" >/dev/null 2>&1 || ERROR=1
bash -n "$SCRIPT_DIR/gerar.sh" >/dev/null 2>&1 || ERROR=1

if [ "$ERROR" -ne 0 ]; then
    echo
    echo -e "${RED}LA INSTALACION TERMINO CON ERRORES.${RESET}"
    exit 1
fi

# ------------------------------------------------------------
# LIMPIEZA
# ------------------------------------------------------------

rm -rf "$TMP_DIR"
rm -f "$ZIP_FILE"

echo
echo -e "${CYAN}============================================================${RESET}"
echo -e "${GREEN}       INSTALACION COMPLETADA CORRECTAMENTE${RESET}"
echo -e "${CYAN}============================================================${RESET}"
echo
echo -e "${WHITE}Comandos disponibles:${RESET}"
echo -e "  ${GREEN}menu${RESET}"
echo -e "  ${GREEN}gerar${RESET}"
echo
echo -e "${WHITE}Archivos instalados en:${RESET}"
echo -e "  $SCRIPT_DIR"
echo
echo -e "${GREEN}No es necesario copiar archivos manualmente.${RESET}"
echo
