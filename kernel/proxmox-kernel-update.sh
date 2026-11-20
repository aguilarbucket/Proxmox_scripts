#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Proxmox VE: actualización de la rama activa del kernel en hosts BIOS con GRUB.
set -euo pipefail
export LC_ALL=C

fail() { printf '%s\n' "$*" >&2; exit 1; }

(( EUID == 0 )) || fail 'Ejecuta el script como root.'
[[ -r /etc/pve/.version && ! -d /sys/firmware/efi && -s /boot/grub/grub.cfg ]] ||
    fail 'Este script requiere Proxmox VE con BIOS heredado y GRUB.'
[[ -t 0 && -t 1 ]] || fail 'Ejecuta el script en una terminal interactiva.'

active=$(uname -r)
[[ $active =~ ^([0-9]+\.[0-9]+)\.[0-9]+-[0-9]+-pve$ ]] ||
    fail "No se reconoce la rama del kernel activo: $active"
meta="proxmox-kernel-${BASH_REMATCH[1]}"

check_boot() {
    local kernel=$1
    [[ -s /boot/vmlinuz-$kernel && -s /boot/initrd.img-$kernel ]] ||
        fail "Falta la imagen o initramfs de $kernel."
    grep -Fq "with Linux $kernel'" /boot/grub/grub.cfg ||
        fail "No se encontró la entrada normal de $kernel en GRUB."
}

check_boot "$active"
printf 'Kernel activo: %s\n' "$active"
df -h / /boot

apt-get -o APT::Update::Error-Mode=any update
candidate=$(apt-cache policy "$meta" | awk '$1 == "Candidate:" { print $2 }')
[[ $candidate =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]] ||
    fail "Versión candidata no reconocida: ${candidate:-ninguna}"
target="$candidate-pve"
signed="proxmox-kernel-$target-signed"
printf 'Rama: %s\nCandidato: %s\n' "$meta" "$target"

if [[ $active == "$target" ]]; then
    printf 'El candidato ya está activo.\n'
    exit 0
fi
dpkg --compare-versions "$target" gt "$active" || fail 'El candidato no es más nuevo que el kernel activo.'

simulation=$(apt-get -s --no-remove install "$meta=$candidate" "$signed=$candidate")
printf '%s\n' "$simulation"
if ! awk -v meta="$meta" -v signed="$signed" '
    $1 == "Remv" || $1 == "Purg" { bad = 1 }
    $1 == "Inst" && $2 != meta && $2 != signed { bad = 1 }
    END { exit bad }
' <<< "$simulation"; then
    fail 'APT propone cambios fuera de los paquetes previstos.'
fi

printf '\nRecuperación: consola local > GRUB > Advanced options > %s (modo normal).\n' "$active"
read -r -p 'Escribe INSTALAR para continuar: ' answer
[[ $answer == INSTALAR ]] || fail 'Actualización cancelada.'
apt-get --no-remove install "$meta=$candidate" "$signed=$candidate"

check_boot "$target"
check_boot "$active"
printf '\nInstalado: %s. Respaldo en GRUB: %s.\n' "$target" "$active"
printf 'En tu ventana de mantenimiento, reinicia y confirma uname -r, SSH y panel desde otro equipo.\n'
printf 'Si necesitas volver al kernel anterior, selecciónalo en GRUB desde la consola local.\n'
