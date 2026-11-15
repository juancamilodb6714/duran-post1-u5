#!/bin/bash
# VBoxManage_commands.sh — Parte 2: comandos del laboratorio con la VM Lab5-Alpine

# ===== Paso 1: Creación de la máquina virtual =====
# Opción B: Crear la VM con VBoxManage (línea de comandos)
VBoxManage createvm --name "Lab5-Alpine" --ostype "Linux_64" --register

VBoxManage modifyvm "Lab5-Alpine" \
    --memory 1024 --vram 16 \
    --cpus 1 \
    --nic1 nat

VBoxManage createmedium disk \
    --filename "Lab5-Alpine.vdi" \
    --size 10240 \
    --format VDI

VBoxManage storagectl "Lab5-Alpine" --name "SATA" --add sata
VBoxManage storageattach "Lab5-Alpine" \
    --storagectl "SATA" --port 0 --device 0 \
    --type hdd --medium "Lab5-Alpine.vdi"

VBoxManage storagectl "Lab5-Alpine" --name "IDE" --add ide
VBoxManage storageattach "Lab5-Alpine" \
    --storagectl "IDE" --port 0 --device 0 \
    --type dvddrive --medium "alpine-standard-3.19.0-x86_64.iso"

# ===== Paso 2: Instalación del sistema operativo =====
# Dentro de la VM: localhost:~# setup-alpine
# Al finalizar: localhost:~# poweroff
# Retirar el ISO de la unidad óptica antes del siguiente arranque

# ===== Paso 3: Configuración de modos de red =====
# Apagar la VM antes de cambiar la configuración de red
VBoxManage controlvm "Lab5-Alpine" poweroff

# Modo 1: NAT (predeterminado — ya configurado)
# La VM accede a internet a través del anfitrión
# IP típica: 10.0.2.15 / Gateway: 10.0.2.2

# Modo 2: Host-Only (red aislada VM ↔ anfitrión, sin internet)
# Primero crear una interfaz Host-Only si no existe:
VBoxManage hostonlyif create
# Asignar la red Host-Only a la NIC de la VM:
VBoxManage modifyvm "Lab5-Alpine" --nic1 hostonly --hostonlyadapter1 "vboxnet0"

# Iniciar VM, verificar IP (rango 192.168.56.x)
# Desde el anfitrión: ping 192.168.56.101 debe responder
# Desde la VM: ping 8.8.8.8 debe fallar (sin internet en Host-Only)

# Modo 3: Bridge (VM conectada directamente a la red física del anfitrión)
VBoxManage modifyvm "Lab5-Alpine" --nic1 bridged --bridgeadapter1 "Ethernet"
# La VM obtiene IP del router de la red local (DHCP)
# Verificar con: ip addr show eth0 dentro de la VM

# ===== Paso 4: Gestión de snapshots =====
# La VM debe estar encendida para tomar un snapshot en caliente
# (con contenido de RAM incluido)

# Tomar snapshot del estado base (Alpine recién instalado)
VBoxManage snapshot "Lab5-Alpine" take "snap_base" \
  --description "Alpine Linux 3.19 recién instalado, sin modificaciones"

# Instalar software adicional dentro de la VM
# (conectar a NAT primero si se estaba usando Host-Only)
# lab5-vm:~# apk update
# lab5-vm:~# apk add curl wget nano htop

# Tomar segundo snapshot con el software instalado
VBoxManage snapshot "Lab5-Alpine" take "snap_con_herramientas" \
  --description "Alpine con curl, wget, nano y htop instalados"

# Verificar la lista de snapshots
VBoxManage snapshot "Lab5-Alpine" list

# Restaurar al estado base (sin desinstalar el software manualmente)
VBoxManage controlvm "Lab5-Alpine" poweroff
VBoxManage snapshot "Lab5-Alpine" restore "snap_base"

VBoxManage startvm "Lab5-Alpine" --type gui
# Verificar que curl ya no está disponible (apk info curl devuelve vacío)

# ===== Paso 5: Asignación de recursos con VBoxManage modifyvm =====
# Apagar la VM antes de modificar su hardware
VBoxManage controlvm "Lab5-Alpine" poweroff

# Verificar la asignacion actual (1 CPU, 1024 MB, configurados en el Paso 1)
# VBoxManage showvminfo "Lab5-Alpine" | findstr /i "memory cpus"           # Windows
VBoxManage showvminfo "Lab5-Alpine" | grep -i "memory\|cpus"          # Linux/macOS

# Aumentar a 2 CPUs virtuales y 2048 MB de RAM
VBoxManage modifyvm "Lab5-Alpine" --cpus 2 --memory 2048

VBoxManage startvm "Lab5-Alpine" --type gui

# Dentro de la VM:
# lab5-vm:~# nproc
# lab5-vm:~# free -m

# ===== Paso 6: Disco dinámico frente a disco de tamaño fijo =====
# Con la VM apagada, crear un segundo disco de 4 GB con asignacion FIJA
VBoxManage controlvm "Lab5-Alpine" poweroff

VBoxManage createmedium disk \
  --filename "Lab5-Alpine-fixed.vdi" \
  --size 4096 \
  --format VDI \
  --variant Fixed

VBoxManage storageattach "Lab5-Alpine" \
  --storagectl "SATA" --port 1 --device 0 \
  --type hdd --medium "Lab5-Alpine-fixed.vdi"

VBoxManage startvm "Lab5-Alpine" --type gui

# Dentro de la VM:
# lab5-vm:~# apk add e2fsprogs
# lab5-vm:~# fdisk /dev/sdb
# lab5-vm:~# mkfs.ext4 /dev/sdb1
# lab5-vm:~# mkdir /mnt/fijo
# lab5-vm:~# mount /dev/sdb1 /mnt/fijo
# lab5-vm:~# time dd if=/dev/zero of=/mnt/fijo/test.img bs=1M count=200
# lab5-vm:~# sync
# lab5-vm:~# time dd if=/dev/zero of=/root/test.img bs=1M count=200
# lab5-vm:~# sync
# lab5-vm:~# rm /mnt/fijo/test.img /root/test.img

# ===== Paso 9: Exportación en formato OVF =====
# Apagar la VM antes de exportar
VBoxManage controlvm "Lab5-Alpine" poweroff

# Exportar la VM en formato OVA (OVF comprimido, un solo archivo)
VBoxManage export "Lab5-Alpine" \
    --output "Lab5-Alpine-export.ova" \
    --manifest \
    --options manifest

# Verificar el archivo exportado
dir Lab5-Alpine-export.ova       # Windows
ls -lh Lab5-Alpine-export.ova # Linux/macOS

# El archivo .ova puede importarse en otra instalación de VirtualBox o VMware
# con: VBoxManage import Lab5-Alpine-export.ova
