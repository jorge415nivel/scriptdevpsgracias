#!/bin/bash
clear
echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
echo -e "\033[1;36m-------------------- INSTALADOR SCRIPT DEVPS -----------------------\033[0m"
echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
echo -e "\033[1;33mPreparando la instalación desde tu repositorio (SIN KEY)...\033[0m"

cd $HOME

# Descargamos la lista de archivos directamente de TU repositorio de GitHub
wget -q https://raw.githubusercontent.com/jorge415nivel/scriptdevpsgracias/master/lista-arq -O lista-arq

if [[ -e $HOME/lista-arq ]]; then
    echo -e "\033[1;33mDescargando archivos del sistema...\033[0m"
    for arqx in $(cat $HOME/lista-arq); do
        echo -ne "\033[1;33mDescargando: \033[1;36m[$arqx] \033[0m"
        wget -q https://raw.githubusercontent.com/jorge415nivel/scriptdevpsgracias/master/$arqx -O $HOME/$arqx
        
        if [[ -e $HOME/$arqx ]]; then
            echo -e "\033[1;32m- Recibido con éxito!\033[0m"
            chmod +x $HOME/$arqx 2>/dev/null
        else
            echo -e "\033[1;31m- Falló\033[0m"
        fi
    done
    
    # Instalación de dependencias básicas del sistema
    echo -e "\033[1;33mInstalando dependencias del sistema...\033[0m"
    apt-get update -y > /dev/null 2>&1
    apt-get install bc screen nano curl netcat apache2 -y > /dev/null 2>&1
    
    # Ajuste de puerto de apache si existe
    if [[ -e /etc/apache2/ports.conf ]]; then
        sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
        service apache2 restart > /dev/null 2>&1
    fi

    # Crear comando global 'gerar' si el archivo existe
    if [[ -e $HOME/gerar.sh ]]; then
        cat $HOME/gerar.sh > /bin/gerar
        chmod +x /bin/gerar
    fi
    
    # Limpiar archivo temporal
    rm -f $HOME/lista-arq
    
    echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
    echo -e "\033[1;32m ¡INSTALACIÓN COMPLETADA CON ÉXITO! \033[0m"
    echo -e "\033[1;33m Ahora puedes escribir \033[1;31m'menu'\033[1;33m o \033[1;31m'gerar'\033[1;33m para iniciar el panel.\033[0m"
    echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
else
    echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
    echo -e "\033[1;31m Error: No se pudo descargar la lista de archivos desde GitHub.\033[0m"
    echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
fi
