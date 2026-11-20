# Actualizar el kernel de Proxmox VE con el script

## Motivación

El script nació al revisar el [aviso de seguridad PSA-2026-00080-1 de Proxmox](https://forum.proxmox.com/threads/proxmox-virtual-environment-security-advisories.149331/page-5#-subject-psa-2026-00080-1-kernel-tcp-use-after-free-cve-2026-98432), publicado el 31 de octubre de 2026. El aviso documenta la [CVE-2026-98432](https://nvd.nist.gov/vuln/detail/CVE-2026-98432), un fallo de tipo *use-after-free* en la gestión de conexiones TCP sobre IPv4 del kernel Linux. Para la rama probada, Proxmox indica que la corrección está incluida desde `7.0.14-25-pve`.

El parche ya estaba disponible en el repositorio, pero no me había dado cuenta de que el nodo seguía arrancado con `7.0.14-8-pve`. Lo confirmé con `uname -r` y actualicé a `7.0.14-30-pve`, el candidato que ofrecía APT para esa rama. Después del reinicio, volví a ejecutar `uname -r` para confirmar que el kernel corregido estaba activo.

El script reúne los pasos que hice a mano. Detecta la rama activa, simula la instalación, pide confirmación y comprueba que el kernel anterior siga disponible en GRUB para recuperar el arranque si hace falta. Para otros avisos, compara el candidato de APT con la versión corregida que indique Proxmox.

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

Si compartes una captura o un log de la ejecución, oculta el nombre del nodo, las direcciones IP y las URL de repositorios privados que puedan aparecer en la terminal.
