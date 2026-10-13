#!/bin/bash
# ============================================================
# SCRIPT DEVPS - INSTALADOR CORREGIDO
# Repositorio: https://github.com/jorge415nivel/scriptdevpsgracias
#
# Instala los archivos del repositorio y coloca menu_inst y sus
# archivos auxiliares en /etc/adm-lite para evitar el error de la
# opción 9. No elimina instalaciones anteriores ni cuentas SSH.
# ============================================================

set -Eeuo pipefail
umask 022

REPO="https://github.com/jorge415nivel/scriptdevpsgracias"
BRANCH="master"
ZIP_URL="${REPO}/archive/refs/heads/${BRANCH}.zip"

TMP_DIR="$(mktemp -d /tmp/scriptdevps-install.XXXXXX)"
ZIP_FILE="${TMP_DIR}/repo.zip"
SCRIPT_DIR="/etc/SCRIPT"
ADM_DIR="/etc/adm-lite"
EXEC_DIR="/bin/ejecutar"

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
    echo -e "${RED}ERROR: $*${RESET}" >&2
    exit 1
}

step() {
    echo
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${CYAN}$*${RESET}"
    echo -e "${CYAN}============================================================${RESET}"
}

echo -e "${CYAN}SCRIPT DEVPS - INSTALADOR CORREGIDO${RESET}"

# -------------------- ROOT / OS --------------------
if [[ "${EUID}" -ne 0 ]]; then
    fail "Ejecuta como root. Ejemplo: sudo bash instalador.sh"
fi

if [[ ! -r /etc/os-release ]]; then
    fail "No se puede identificar el sistema operativo."
fi
. /etc/os-release
case "${ID:-}" in
    ubuntu|debian) ;;
    *) echo -e "${YELLOW}Aviso: este instalador está pensado para Ubuntu/Debian; tu sistema es ${PRETTY_NAME:-desconocido}.${RESET}" ;;
esac

# -------------------- DEPENDENCIAS --------------------
step "[1/7] Instalando dependencias"

export DEBIAN_FRONTEND=noninteractive
if ! apt-get update; then
    fail "apt-get update falló. Revisa los repositorios y la conexión antes de continuar."
fi

if ! apt-get install -y \
    bash coreutils findutils grep sed gawk \
    bc screen nano curl wget unzip zip \
    net-tools netcat-openbsd lsof figlet lolcat \
    apache2 python3 python3-pip ca-certificates procps iproute2; then
    fail "No se pudieron instalar todas las dependencias."
fi

for cmd in bash curl unzip netstat figlet; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Falta el comando requerido: $cmd"
done
echo -e "${GREEN}Dependencias verificadas.${RESET}"

# -------------------- DOWNLOAD --------------------
step "[2/7] Descargando y verificando el repositorio"

if ! curl --fail --location --retry 3 --connect-timeout 15 \
    "$ZIP_URL" --output "$ZIP_FILE"; then
    fail "No se pudo descargar el ZIP desde GitHub."
fi
[[ -s "$ZIP_FILE" ]] || fail "El ZIP descargado está vacío."
unzip -tq "$ZIP_FILE" >/dev/null || fail "El archivo descargado no es un ZIP válido."

mkdir -p "$TMP_DIR/unpacked"
unzip -q "$ZIP_FILE" -d "$TMP_DIR/unpacked"

REPO_ROOT="$(find "$TMP_DIR/unpacked" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[[ -n "$REPO_ROOT" && -d "$REPO_ROOT/BOT/gerador" ]] || fail "No se encontró BOT/gerador dentro del repositorio."
REPO_DIR="$REPO_ROOT/BOT/gerador"
[[ -s "$REPO_DIR/menu" ]] || fail "No se encontró BOT/gerador/menu."
[[ -s "$REPO_DIR/menu_inst" ]] || fail "No se encontró BOT/gerador/menu_inst."
echo -e "${GREEN}Repositorio descargado y estructura comprobada.${RESET}"

# -------------------- DIRECTORIES / COPY --------------------
step "[3/7] Copiando archivos del menú principal"

mkdir -p "$SCRIPT_DIR" "$ADM_DIR" "$EXEC_DIR"

# Copiar el contenido completo, conservando archivos locales que no estén
# en el ZIP. Los archivos del repositorio sí actualizan su homónimo.
if ! cp -a "$REPO_DIR/." "$SCRIPT_DIR/"; then
    fail "No se pudieron copiar los archivos a $SCRIPT_DIR."
fi

# Compatibilidad con versiones antiguas: la opción 9 llama directamente
# a /etc/adm-lite/menu_inst. Este archivo se instala siempre desde el ZIP.
install -m 0755 "$REPO_DIR/menu_inst" "$ADM_DIR/menu_inst"

# El menú de puertos depende de varios archivos de soporte. Se copian desde
# el repositorio a /etc/adm-lite si existen, sin sobrescribir configuraciones
# locales ya presentes. menu_inst es la excepción: se actualiza siempre.
AUX_FILES=(
    confdropbear idioma_menuinst optimizador limiter.sh limitera limiterb
    ferramentas ferramentas-txt ferramentascodes menu menu-txt
    menu_credito payloads ssl v-local.log
)
for name in "${AUX_FILES[@]}"; do
    if [[ -f "$REPO_DIR/$name" && ! -e "$ADM_DIR/$name" ]]; then
        install -m 0644 "$REPO_DIR/$name" "$ADM_DIR/$name"
    fi
done

# Los scripts auxiliares que se ejecutan directamente necesitan permiso.
for name in menu_inst optimizador ferramentas limiter.sh; do
    [[ ! -f "$ADM_DIR/$name" ]] || chmod 0755 "$ADM_DIR/$name"
done

# Archivos de compatibilidad usados por algunas versiones del menú.
if [[ -f "$REPO_DIR/trans" ]]; then
    install -m 0755 "$REPO_DIR/trans" /usr/bin/trans
fi
if [[ -f "$REPO_DIR/gerar.sh" ]]; then
    install -m 0755 "$REPO_DIR/gerar.sh" /usr/bin/gerar.sh
fi
if [[ -f "$REPO_DIR/http-server.py" ]]; then
    install -m 0755 "$REPO_DIR/http-server.py" /bin/http-server.sh
fi

echo -e "${GREEN}Archivos principales y auxiliares copiados.${RESET}"

# -------------------- STATE FILES --------------------
step "[4/7] Preparando archivos de estado"

# Crear únicamente los archivos que falten; no reiniciar el estado existente.
if [[ ! -s "$ADM_DIR/v-local.log" ]]; then
    if [[ -s "$SCRIPT_DIR/v-local.log" ]]; then
        install -m 0644 "$SCRIPT_DIR/v-local.log" "$ADM_DIR/v-local.log"
    else
        printf '%s\n' "V4.3" > "$ADM_DIR/v-local.log"
    fi
fi
[[ -s "$ADM_DIR/versao_script" ]] || printf '%s\n' "1" > "$ADM_DIR/versao_script"

if [[ ! -s /root/name ]]; then
    printf '%s\n' "VPS-VIP" > /root/name
fi
if [[ ! -s /root/exito ]]; then
    printf '%s\n' "Verified [ SCRIPT DEVPS ] ADM" > /root/exito
fi
install -m 0644 /root/name "$ADM_DIR/name"
install -m 0644 /root/exito "$ADM_DIR/exito"

[[ -s "$EXEC_DIR/val" ]] || printf '%s\n' "0" > "$EXEC_DIR/val"
[[ -s "$EXEC_DIR/uskill" ]] || printf '%s\n' "0" > "$EXEC_DIR/uskill"
[[ -s "$EXEC_DIR/val1" ]] || printf '%s\n' "desactivado" > "$EXEC_DIR/val1"
[[ -s "$EXEC_DIR/fecha" ]] || date +"%d-%m-%y" > "$EXEC_DIR/fecha"
[[ -e "$EXEC_DIR/key.fix" ]] || touch "$EXEC_DIR/key.fix"

chmod 0755 "$SCRIPT_DIR" "$ADM_DIR" "$EXEC_DIR"
chmod 0644 "$EXEC_DIR/val" "$EXEC_DIR/uskill" "$EXEC_DIR/val1" "$EXEC_DIR/fecha" "$EXEC_DIR/key.fix"
chmod 0644 "$ADM_DIR/v-local.log" "$ADM_DIR/versao_script" "$ADM_DIR/name" "$ADM_DIR/exito"

# -------------------- COMMAND WRAPPERS --------------------
step "[5/7] Configurando comandos"

cat > /usr/local/bin/menu <<'EOF_MENU'
#!/bin/bash
cd /etc/SCRIPT || exit 1
exec bash /etc/SCRIPT/menu "$@"
EOF_MENU
chmod 0755 /usr/local/bin/menu
ln -sfn /usr/local/bin/menu /usr/bin/menu

cat > /usr/local/bin/gerar <<'EOF_GERAR'
#!/bin/bash
if [[ -x /usr/bin/gerar.sh ]]; then
    exec /usr/bin/gerar.sh "$@"
fi
echo "ERROR: no se encontró /usr/bin/gerar.sh" >&2
exit 1
EOF_GERAR
chmod 0755 /usr/local/bin/gerar
ln -sfn /usr/local/bin/gerar /usr/bin/gerar

# -------------------- APACHE --------------------
step "[6/7] Comprobando Apache"

# Conserva el comportamiento esperado del script (puerto 81), pero no
# sobrescribe a ciegas una configuración ya personalizada.
if [[ -f /etc/apache2/ports.conf ]]; then
    if grep -Eq '^[[:space:]]*Listen[[:space:]]+80([[:space:]]|$)' /etc/apache2/ports.conf; then
        sed -i -E 's/^[[:space:]]*Listen[[:space:]]+80([[:space:]]*)$/Listen 81\1/' /etc/apache2/ports.conf
    fi
fi

if [[ -d /etc/apache2/sites-enabled ]]; then
    shopt -s nullglob
    for file in /etc/apache2/sites-enabled/*.conf; do
        sed -i 's/<VirtualHost \*:80>/<VirtualHost *:81>/g' "$file"
    done
    shopt -u nullglob
fi

if command -v apache2ctl >/dev/null 2>&1 && apache2ctl configtest; then
    systemctl restart apache2 || echo -e "${YELLOW}Aviso: Apache no pudo reiniciarse; revisa su estado.${RESET}"
else
    echo -e "${YELLOW}Aviso: no se modificó Apache por un error de configuración.${RESET}"
fi

# -------------------- VALIDATION --------------------
step "[7/7] Validando archivos instalados"

ERROR=0
REQUIRED_FILES=(
    "$SCRIPT_DIR/menu"
    "$SCRIPT_DIR/menu-txt"
    "$SCRIPT_DIR/cabecalho"
    "$SCRIPT_DIR/gerar.sh"
    "$SCRIPT_DIR/idioma_geral"
    "$SCRIPT_DIR/trans"
    "$ADM_DIR/menu_inst"
    "$ADM_DIR/idioma_menuinst"
    "$ADM_DIR/confdropbear"
    "$ADM_DIR/v-local.log"
    "$ADM_DIR/versao_script"
    "$ADM_DIR/name"
    "$ADM_DIR/exito"
    "$EXEC_DIR/val"
)
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -s "$file" ]]; then
        echo -e "${GREEN}OK: $file${RESET}"
    else
        echo -e "${RED}FALTA: $file${RESET}"
        ERROR=1
    fi
done

for file in "$SCRIPT_DIR/menu" "$SCRIPT_DIR/menu_inst" "$SCRIPT_DIR/gerar.sh" "$ADM_DIR/menu_inst" "$ADM_DIR/optimizador"; do
    if [[ -f "$file" ]] && ! bash -n "$file" >/dev/null 2>&1; then
        echo -e "${RED}Error de sintaxis en: $file${RESET}"
        ERROR=1
    fi
done

if [[ "$ERROR" -ne 0 ]]; then
    echo
    echo -e "${RED}La instalación no superó todas las verificaciones.${RESET}"
    echo -e "${YELLOW}No se han borrado las cuentas SSH. Corrige los archivos indicados antes de usar todas las opciones.${RESET}"
    exit 1
fi

echo
echo -e "${CYAN}============================================================${RESET}"
echo -e "${GREEN}INSTALACIÓN COMPLETADA Y ARCHIVOS PRINCIPALES VERIFICADOS${RESET}"
echo -e "${CYAN}============================================================${RESET}"
echo -e "${WHITE}Comandos disponibles:${RESET}"
echo -e "  ${GREEN}menu${RESET}"
echo -e "  ${GREEN}gerar${RESET}"
echo
echo "Menú principal: $SCRIPT_DIR/menu"
echo "Menú de puertos: $ADM_DIR/menu_inst"
echo
echo -e "${YELLOW}Nota: la validación confirma archivos y sintaxis básica; no garantiza que servicios externos o puertos estén disponibles en el proveedor VPS.${RESET}"
