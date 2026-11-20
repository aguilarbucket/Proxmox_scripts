# Actualizar el kernel de Proxmox VE con el script

## Instalación

El script está diseñado para Proxmox VE con BIOS heredado y GRUB. Ejecútalo como root desde una terminal interactiva y asegúrate de poder acceder a la consola del host.

1. Ejecuta `bash ./proxmox-kernel-update.sh` desde el directorio donde guardaste el archivo.
2. Revisa el kernel candidato y la simulación de APT. Si el plan coincide con la actualización esperada, escribe `INSTALAR`. Si APT vuelve a pedir confirmación, comprueba que muestra el mismo plan.
3. Espera a que el script confirme que el kernel nuevo y el anterior tienen su imagen, su initramfs y su entrada en GRUB. Si la instalación o las comprobaciones fallan, conserva la sesión y revisa el error antes de reiniciar.
4. Reinicia normalmente. Ejecuta `uname -r` y confirma que devuelve el kernel candidato. Comprueba que `systemctl is-active pveproxy pvedaemon` devuelve dos líneas `active` y verifica SSH y el panel web desde otro equipo.


## Resultado de la prueba

El script instaló el kernel firmado `7.0.14-30-pve`, actualizó su metapaquete y conservó `7.0.14-8-pve` en GRUB. APT no eliminó paquetes.

Después del reinicio, `uname -r` devolvió `7.0.14-30-pve`. En la sesión del propio host, la conexión SSH al nodo funcionó, `pveproxy` y `pvedaemon` devolvieron `active` y el panel respondió `HTTP 200`. La comprobación desde otro equipo queda pendiente.

## Rollback si el kernel nuevo falla

1. Desde la consola del host, reinicia y abre **Advanced options for Proxmox VE GNU/Linux** en GRUB.
2. Selecciona la entrada normal del kernel que estaba activo antes de la actualización.
3. Comprueba con `uname -r` que arrancó el kernel anterior y verifica el acceso al host. La selección manual aplica a ese arranque. Si necesitas reiniciar otra vez mientras investigas el fallo, vuelve a seleccionar el kernel anterior.

## Alcance

El script actualiza dentro de la rama activa consultando los repositorios configurados. La versión candidata de APT no acredita por sí sola la mitigación de una CVE. La prueba descrita corresponde a un nodo con BIOS heredado y GRUB.
