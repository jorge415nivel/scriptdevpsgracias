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
# VERIFICAR ROOT
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

if ! apt-get update -y >/dev/null 2>&1; then
    echo -e "${RED}ERROR: no se pudo actualizar APT.${RESET}"
    exit 1
fi

if ! apt-get install -y \
    bc screen nano curl wget unzip zip \
    net-tools netcat-openbsd lsof figlet lolcat \
    gawk apache2 python3 python3-pip \
    ca-certificates procps iproute2 \
    >/dev/null 2>&1; then
    echo -e "${RED}ERROR: falló la instalación de dependencias.${RESET}"
    exit 1
fi

for CMD in netstat lolcat figlet curl unzip; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo -e "${RED}ERROR: falta el comando $CMD.${RESET}"
        exit 1
    fi
done

echo -e "${GREEN}Dependencias OK.${RESET}"

# ------------------------------------------------------------
# PREPARAR DIRECTORIOS
# ------------------------------------------------------------

echo -e "${YELLOW}[2/7] Preparando directorios...${RESET}"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR" "$SCRIPT_DIR" "$ADM_DIR" "$EXEC_DIR"

echo -e "${GREEN}Directorios OK.${RESET}"

# ------------------------------------------------------------
# DESCARGAR REPOSITORIO
# ------------------------------------------------------------

echo -e "${YELLOW}[3/7] Descargando tu repositorio...${RESET}"

rm -f "$ZIP_FILE"

if ! curl -fL --retry 3 --connect-timeout 15 \
    "$ZIP_URL" -o "$ZIP_FILE" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: no se pudo descargar el repositorio.${RESET}"
    exit 1
fi

if [ ! -s "$ZIP_FILE" ]; then
    echo -e "${RED}ERROR: el ZIP descargado está vacío.${RESET}"
    exit 1
fi

if ! unzip -q "$ZIP_FILE" -d "$TMP_DIR"; then
    echo -e "${RED}ERROR: no se pudo extraer el ZIP.${RESET}"
    exit 1
fi

REPO_DIR="$TMP_DIR/scriptdevpsgracias-master/BOT/gerador"

if [ ! -d "$REPO_DIR" ]; then
    echo -e "${RED}ERROR: no existe BOT/gerador en el repositorio.${RESET}"
    exit 1
fi

echo -e "${GREEN}Repositorio descargado correctamente.${RESET}"

# ------------------------------------------------------------
# COPIAR ARCHIVOS DE BOT/GERADOR
# ------------------------------------------------------------

echo -e "${YELLOW}[4/7] Instalando archivos de BOT/gerador...${RESET}"

if ! cp -a "$REPO_DIR"/. "$SCRIPT_DIR"/; then
    echo -e "${RED}ERROR: no se pudieron copiar los archivos.${RESET}"
    exit 1
fi

# ------------------------------------------------------------
# CORRECCION PERMANENTE DE LA OPCION 9
# ------------------------------------------------------------

if [ -s "$REPO_DIR/menu_inst" ]; then
    install -D -m 755 "$REPO_DIR/menu_inst" "$ADM_DIR/menu_inst"
elif [ -s "$SCRIPT_DIR/menu_inst" ]; then
    install -D -m 755 "$SCRIPT_DIR/menu_inst" "$ADM_DIR/menu_inst"
else
    echo -e "${RED}ERROR: no se encontró menu_inst.${RESET}"
    echo -e "${YELLOW}Comprueba BOT/gerador/menu_inst en GitHub.${RESET}"
    exit 1
fi

if [ ! -s "$ADM_DIR/menu_inst" ]; then
    echo -e "${RED}ERROR: no se instaló correctamente menu_inst.${RESET}"
    exit 1
fi

echo -e "${GREEN}Menú de puertos instalado en $ADM_DIR/menu_inst${RESET}"

# Compatibilidad con scripts antiguos.
cp -a "$REPO_DIR"/. /root/

echo -e "${GREEN}Archivos instalados.${RESET}"

# ------------------------------------------------------------
# PERMISOS
# ------------------------------------------------------------

echo -e "${YELLOW}[5/7] Corrigiendo permisos...${RESET}"

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
for FILE in menu user verifica ferramentas get trans; do
    [ ! -f "$SCRIPT_DIR/$FILE" ] || chmod +x "$SCRIPT_DIR/$FILE"
done
chmod 755 "$ADM_DIR/menu_inst"

# ------------------------------------------------------------
# ARCHIVOS DE INICIALIZACION
# ------------------------------------------------------------

echo -e "${YELLOW}[6/7] Creando estructura de ChumoGH/ADM...${RESET}"

# El encabezado consulta estos archivos dentro de /etc/adm-lite.
# Usar los archivos del repositorio cuando existan y crear valores
# predeterminados solo cuando falten.
if [ -s "$SCRIPT_DIR/v-local.log" ]; then
    cp -f "$SCRIPT_DIR/v-local.log" "$ADM_DIR/v-local.log"
elif [ ! -s "$ADM_DIR/v-local.log" ]; then
    echo "V4.3" > "$ADM_DIR/v-local.log"
fi

if [ ! -s "$ADM_DIR/versao_script" ]; then
    echo "1" > "$ADM_DIR/versao_script"
fi

if [ ! -s /root/name ]; then
    echo "VPS-VIP" > /root/name
fi
cp -f /root/name "$ADM_DIR/name"

if [ ! -s /root/exito ]; then
    echo "Verified [ SCRIPT DEVPS ] ADM" > /root/exito
fi
cp -f /root/exito "$ADM_DIR/exito"

echo "0" > "$EXEC_DIR/val"
echo "0" > "$EXEC_DIR/uskill"
echo "desactivado" > "$EXEC_DIR/val1"
date +"%d-%m-%y" > "$EXEC_DIR/fecha"
touch "$EXEC_DIR/key.fix"

chmod 755 "$EXEC_DIR" "$ADM_DIR"
chmod 644 "$EXEC_DIR/val" "$EXEC_DIR/uskill" \
    "$EXEC_DIR/val1" "$EXEC_DIR/fecha" "$EXEC_DIR/key.fix"
chmod 644 "$ADM_DIR/v-local.log" "$ADM_DIR/versao_script" \
    "$ADM_DIR/name" "$ADM_DIR/exito"

# ------------------------------------------------------------
# COMANDOS AUXILIARES
# ------------------------------------------------------------

if [ -f "$SCRIPT_DIR/trans" ]; then
    cp -f "$SCRIPT_DIR/trans" /usr/bin/trans
    chmod +x /usr/bin/trans
fi

if [ -f "$SCRIPT_DIR/gerar.sh" ]; then
    cp -f "$SCRIPT_DIR/gerar.sh" /usr/bin/gerar.sh
    chmod +x /usr/bin/gerar.sh
fi

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
chmod 755 /usr/local/bin/menu

# ------------------------------------------------------------
# WRAPPER GERAR
# ------------------------------------------------------------

cat > /usr/local/bin/gerar <<'EOF'
#!/bin/bash
cd /etc/SCRIPT || exit 1
exec bash /usr/bin/gerar.sh "$@"
EOF
chmod 755 /usr/local/bin/gerar

cp -f /usr/local/bin/menu /usr/bin/menu
cp -f /usr/local/bin/gerar /usr/bin/gerar
chmod 755 /usr/bin/menu /usr/bin/gerar

# ------------------------------------------------------------
# APACHE
# ------------------------------------------------------------
# Nota: esto conserva la intención del instalador original
# (Apache en 81). Verifica que no haya otros servicios usando 81.

if [ -f /etc/apache2/ports.conf ]; then
    sed -i 's/^[[:space:]]*Listen 80$/Listen 81/' /etc/apache2/ports.conf
fi

if [ -d /etc/apache2/sites-enabled ]; then
    for FILE in /etc/apache2/sites-enabled/*.conf; do
        [ -f "$FILE" ] || continue
        sed -i 's/<VirtualHost \*:80>/<VirtualHost *:81>/g' "$FILE"
    done
fi

if apache2ctl configtest >/dev/null 2>&1; then
    systemctl restart apache2 >/dev/null 2>&1 || \
        echo -e "${YELLOW}Aviso: Apache no pudo reiniciarse.${RESET}"
else
    echo -e "${YELLOW}Aviso: revisa la configuración de Apache.${RESET}"
fi

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
    "$SCRIPT_DIR/v-local.log" \
    "$ADM_DIR/menu_inst" \
    "$ADM_DIR/v-local.log" \
    "$ADM_DIR/versao_script" \
    "$ADM_DIR/name" \
    "$ADM_DIR/exito" \
    /root/name \
    /root/exito \
    "$EXEC_DIR/val"
do
    if [ ! -s "$FILE" ]; then
        echo -e "${RED}FALTA: $FILE${RESET}"
        ERROR=1
    else
        echo -e "${GREEN}OK: $FILE${RESET}"
    fi
done

for FILE in \
    "$SCRIPT_DIR/menu" \
    "$SCRIPT_DIR/menu_inst" \
    "$SCRIPT_DIR/cabecalho" \
    "$SCRIPT_DIR/gerar.sh" \
    "$ADM_DIR/menu_inst"
do
    if [ -f "$FILE" ] && ! bash -n "$FILE" >/dev/null 2>&1; then
        echo -e "${RED}ERROR DE SINTAXIS: $FILE${RESET}"
        ERROR=1
    fi
done

if [ "$ERROR" -ne 0 ]; then
    echo
    echo -e "${RED}LA INSTALACION TERMINO CON ERRORES.${RESET}"
    echo -e "${YELLOW}Revisa los archivos marcados antes de usar el menú.${RESET}"
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
echo -e "  $ADM_DIR/menu_inst"
echo
echo -e "${GREEN}Verificación de archivos completada.${RESET}"
echo
