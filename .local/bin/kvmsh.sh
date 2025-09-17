#!/usr/bin/env bash
set -euo pipefail

# kvmsh: Import/Clean OVA-based VMs for KVM/libvirt (Arch-friendly)
# Modes:
#	Import (default): extract .ova -> convert .vmdk to .qcow2 -> (system) move to /var/lib/libvirt/images/<VM_NAME>/ -> virt-install
#	Clean: --clean <VM_NAME>  => shutdown/destroy, undefine, delete disks
#	Mount ISO: mount-iso <DIR> <VM_NAME> [--label LABEL] [--dev sdb]  => build ISO from DIR and hot-attach as SCSI CD-ROM
#
# Deps: tar, qemu-img, virt-install, virsh, systemd (libvirtd running), (optional) qemu-system-x86_64
#       mount-iso also needs mkisofs (cdrtools) or genisoimage

usage() {
	cat <<'USAGE'
Usage:
	kvmsh [options] <file.ova>
	kvmsh --clean <VM_NAME> [--force]
	kvmsh mount-iso <DIR> <VM_NAME> [--label LABEL] [--dev sdb]

Options (all optional; defaults shown in brackets):
	-n, --name NAME         VM name [basename of OVA]
	-r, --ram MB            RAM megabytes [4096]
	-c, --vcpus N           vCPUs [2]
	-o, --os-variant STR    osinfo variant, e.g. ubuntu22.04, fedora-rawhide [generic]
	-b, --bus BUS           disk bus: virtio|sata|scsi [virtio]
	-g, --graphics MODE     spice|vnc|none [spice]  (auto-falls back to vnc if spice unsupported)
	-N, --network NET       libvirt network [default] (auto-falls back to user if NET missing)
	-d, --dir DIR           working dir (extract/convert here) [mktemp]
	-y, --yes               non-interactive; assume "yes" to prompts
	-h, --help              show help

Cleanup mode:
	--clean <VM_NAME>       Remove VM and its disks (see --force)
	--force                 Skip confirmations during cleanup

Mount ISO mode:
	mount-iso <DIR> <VM_NAME> [--label LABEL] [--dev sdb]
	  Builds an ISO from <DIR>, writes an XML that targets SCSI bus, and hot-attaches it to <VM_NAME>.
	  Read-only inside guest (ISO/CD). Detach with:
	    virsh detach-device <VM_NAME> /tmp/<DIRNAME>-<STAMP>.xml --live --config

Notes:
	- Respects LIBVIRT_DEFAULT_URI (e.g., export LIBVIRT_DEFAULT_URI=qemu:///system)
	- System libvirt: disks are placed under /var/lib/libvirt/images/<VM_NAME>/ with qemu:qemu perms
	- List OS variants with: osinfo-query os | less
USAGE
}

# --- Small helpers available to all modes ---
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }

ensure_libvirtd() {
	if ! systemctl is-active --quiet libvirtd; then
		echo "libvirtd not active; attempting to start (may require sudo)..."
		if ! sudo systemctl start libvirtd; then
			echo "Warning: couldn't start libvirtd; operations may fail."
		fi
	fi
}

pick_iso_tool() {
	if command -v mkisofs >/dev/null 2>&1; then
		echo "mkisofs"
		return 0
	fi
	if command -v genisoimage >/dev/null 2>&1; then
		echo "genisoimage"
		return 0
	fi
	return 1
}

# Defaults
VM_NAME=""
RAM_MB=4096
VCPUS=2
OS_VARIANT="generic"
DISK_BUS="virtio"
GRAPHICS="spice"
NET="default"
WORKDIR=""
ASSUME_YES="false"
DO_CLEAN="false"
CLEAN_FORCE="false"
CLEAN_TARGET=""

# --- Handle mount-iso mode early (separate arg parsing) ---
if [[ "${1-}" == "mount-iso" ]]; then
	shift
	MI_DIR="${1-}"; [[ -z "${MI_DIR}" ]] && { echo "Error: mount-iso requires <DIR> and <VM_NAME>"; usage; exit 1; }
	shift || true
	MI_VM="${1-}"; [[ -z "${MI_VM}" ]] && { echo "Error: mount-iso requires <DIR> and <VM_NAME>"; usage; exit 1; }
	shift || true
	MI_LABEL="LAB"
	MI_DEV="sdb"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--label) MI_LABEL="${2:-}"; shift 2;;
			--dev)   MI_DEV="${2:-}"; shift 2;;
			-h|--help) usage; exit 0;;
			*) echo "Unknown option for mount-iso: $1" >&2; usage; exit 1;;
		esac
	done

	[[ -d "$MI_DIR" ]] || { echo "Error: directory not found: $MI_DIR" >&2; exit 1; }

	# Determine libvirt connection wrappers
	LIBVIRT_URI="${LIBVIRT_DEFAULT_URI:-}"
	VIRT_CONNECT_ARGS=()
	if [[ -n "$LIBVIRT_URI" ]]; then
		VIRT_CONNECT_ARGS=( --connect "$LIBVIRT_URI" )
	fi
	VIRSH_CMD="virsh"
	if [[ "$LIBVIRT_URI" == "qemu:///system" ]]; then
		VIRSH_CMD="sudo virsh"
	fi

	ensure_libvirtd
	need virsh
	ISO_TOOL="$(pick_iso_tool)" || { echo "Missing: mkisofs (cdrtools) or genisoimage" >&2; exit 1; }

	BASE="$(basename "$MI_DIR")"
	STAMP="$(date +%Y%m%d-%H%M%S)"
	ISO="/tmp/${BASE}-${STAMP}.iso"
	XML="/tmp/${BASE}-${STAMP}.xml"

	echo "==> Building ISO from '$MI_DIR' -> $ISO"
	"$ISO_TOOL" -quiet -o "$ISO" -R -J -V "$MI_LABEL" "$MI_DIR"

	cat > "$XML" <<XML
<disk type='file' device='cdrom'>
	<driver name='qemu' type='raw'/>
	<source file='$ISO'/>
	<target dev='$MI_DEV' bus='scsi'/>
	<readonly/>
</disk>
XML

	echo "==> Attaching ISO to VM '$MI_VM' as $MI_DEV (SCSI CD-ROM)..."
	$VIRSH_CMD "${VIRT_CONNECT_ARGS[@]}" attach-device "$MI_VM" "$XML" --live --config >/dev/null
	echo "[✓] Attached."
	echo
	echo "Inside guest (manual mount):"
	echo "	sudo mkdir -p /mnt/cdrom"
	echo "	# Usually /dev/sr0; otherwise check: dmesg | tail, or ls /dev/sr*"
	echo "	sudo mount -o ro,exec /dev/sr0 /mnt/cdrom"
	echo
	echo "Detach later (host):"
	echo "	virsh ${VIRT_CONNECT_ARGS[*]} detach-device '$MI_VM' '$XML' --live --config"
	echo
	exit 0
fi

# Parse args (support leading --clean)
if [[ "${1-}" == "--clean" ]]; then
	DO_CLEAN="true"; shift
	CLEAN_TARGET="${1-}"; [[ -z "$CLEAN_TARGET" ]] && { echo "Error: --clean requires <VM_NAME>"; usage; exit 1; }
	shift || true
fi

ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
		-n|--name)        VM_NAME="${2:-}"; shift 2 ;;
		-r|--ram)         RAM_MB="${2:-}"; shift 2 ;;
		-c|--vcpus)       VCPUS="${2:-}"; shift 2 ;;
		-o|--os-variant)  OS_VARIANT="${2:-}"; shift 2 ;;
		-b|--bus)         DISK_BUS="${2:-}"; shift 2 ;;
		-g|--graphics)    GRAPHICS="${2:-}"; shift 2 ;;
		-N|--network)     NET="${2:-}"; shift 2 ;;
		-d|--dir)         WORKDIR="${2:-}"; shift 2 ;;
		-y|--yes)         ASSUME_YES="true"; shift ;;
		--force)          CLEAN_FORCE="true"; shift ;;
		-h|--help)        usage; exit 0 ;;
		--) shift; break ;;
		-*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
		*)  ARGS+=("$1"); shift ;;
	esac
done

# Determine libvirt URI and convenience wrappers
LIBVIRT_URI="${LIBVIRT_DEFAULT_URI:-}"
VIRT_CONNECT_ARGS=()
if [[ -n "$LIBVIRT_URI" ]]; then
	VIRT_CONNECT_ARGS=( --connect "$LIBVIRT_URI" )
fi
VIRSH_CMD="virsh"
SUDO=""
if [[ "$LIBVIRT_URI" == "qemu:///system" ]]; then
	VIRSH_CMD="sudo virsh"
	SUDO="sudo"
fi

# -------------- CLEANUP MODE --------------
clean_vm() {
	local name="$1"
	ensure_libvirtd

	# Confirm unless forced
	if [[ "$CLEAN_FORCE" != "true" ]]; then
		read -rp "This will PERMANENTLY delete VM '$name' and its disks. Continue? [y/N] " ans
		case "${ans,,}" in y|yes) ;; *) echo "Aborted."; exit 1;; esac
	fi

	# If defined, try to collect disk paths first
	mapfile -t DISK_PATHS < <( $VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" domblklist --details "$name" 2>/dev/null \
		| awk '$3=="file"{print $4}' || true )

	# Try graceful shutdown, then destroy if needed
	if $VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" dominfo "$name" >/dev/null 2>&1; then
		state="$($VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" domstate "$name" 2>/dev/null || true)"
		if [[ "$state" == "running" || "$state" == "blocked" ]]; then
			echo "==> Shutting down '$name'..."
			$VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" shutdown "$name" || true
			for _i in {1..15}; do
				sleep 1
				state="$($VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" domstate "$name" 2>/dev/null || true)"
				[[ "$state" == "shut off" || "$state" == "crashed" || -z "$state" ]] && break
			done
			if [[ "$state" != "shut off" && "$state" != "crashed" && -n "$state" ]]; then
				echo "==> Forcing off '$name'..."
				$VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" destroy "$name" || true
			fi
		fi
		echo "==> Undefining '$name'..."
		$VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" undefine "$name" --managed-save --snapshots-metadata || \
		$VIRSH_CMD --connect "${LIBVIRT_URI:-qemu:///session}" undefine "$name" || true
	else
		echo "Note: VM '$name' not found."
	fi

	# Delete disks
	local sys_dir="/var/lib/libvirt/images/$name"
	if [[ -d "$sys_dir" ]]; then
		echo "==> Removing storage folder: $sys_dir"
		$SUDO rm -rf --one-file-system "$sys_dir"
	fi

	for p in "${DISK_PATHS[@]}"; do
		[[ -z "${p:-}" ]] && continue
		if [[ -f "$p" && "$p" == *.qcow2 ]]; then
			echo "==> Removing disk: $p"
			if [[ "$p" == /var/lib/libvirt/images/* ]]; then
				$SUDO rm -f "$p" || true
			else
				rm -f "$p" || true
			fi
		fi
	done

	echo "==> Cleanup complete for '$name'."
	exit 0
}

# Handle cleanup early
if [[ "$DO_CLEAN" == "true" ]]; then
	need virsh
	clean_vm "$CLEAN_TARGET"
fi

# -------------- IMPORT MODE --------------
if [[ ${#ARGS[@]} -ne 1 ]]; then
	usage; exit 1
fi

OVA="${ARGS[0]}"
if [[ ! -f "$OVA" ]]; then
	echo "Error: file not found: $OVA" >&2
	exit 1
fi

# Derive name default
OVA_ABS="$(readlink -f "$OVA")"
BASENAME="$(basename "$OVA_ABS" .ova)"
if [[ -z "$VM_NAME" ]]; then
	VM_NAME="$BASENAME"
fi

# Deps
need tar
need qemu-img
need virt-install
need virsh
ensure_libvirtd

# Graphics auto-fallback
if [[ "$GRAPHICS" == "spice" ]]; then
	if ! command -v qemu-system-x86_64 >/dev/null 2>&1 || ! qemu-system-x86_64 -spice help >/dev/null 2>&1; then
		echo "Note: SPICE not supported. Falling back to VNC."
		GRAPHICS="vnc"
	endif
fi

# Work dir
CLEANUP=false
if [[ -z "$WORKDIR" ]]; then
	WORKDIR="$(mktemp -d -t kvmsh-XXXXXX)"
	CLEANUP=true
else
	mkdir -p "$WORKDIR"
fi
echo "==> Work dir: $WORKDIR"
pushd "$WORKDIR" >/dev/null

# Extract
echo "==> Extracting OVA..."
tar -xvf "$OVA_ABS" >/dev/null

# Find disks
mapfile -t VMDKS < <(ls -1 *.vmdk 2>/dev/null || true)
if [[ ${#VMDKS[@]} -eq 0 ]]; then
	echo "Error: no .vmdk found in OVA." >&2
	exit 1
fi
echo "==> Found ${#VMDKS[@]} disk(s):"
printf '    - %s\n' "${VMDKS[@]}"

if [[ "$ASSUME_YES" != "true" && ${#VMDKS[@]} -gt 1 ]]; then
	read -rp "Convert & attach ALL disks? [y/N] " ans
	case "${ans,,}" in y|yes) ;; *) echo "Aborted."; exit 1;; esac
fi

# Convert
QCOWS_LOCAL=()
for v in "${VMDKS[@]}"; do
	q="${v%.vmdk}.qcow2"
	echo "==> Converting $v -> $q"
	qemu-img convert -f vmdk "$v" -O qcow2 "$q"
	QCOWS_LOCAL+=("$q")
done

# Move for system libvirt
FINAL_QCOWS=()
if [[ "$LIBVIRT_URI" == "qemu:///system" ]]; then
	TARGET_DIR="/var/lib/libvirt/images/$VM_NAME"
	echo "==> Preparing system storage: $TARGET_DIR"
	$SUDO mkdir -p "$TARGET_DIR"
	for q in "${QCOWS_LOCAL[@]}"; do
		tgt="$TARGET_DIR/$(basename "$q")"
		echo "==> Moving $q -> $tgt"
		$SUDO mv "$q" "$tgt"
		$SUDO chown qemu:qemu "$tgt"
		$SUDO chmod 640 "$tgt"
		FINAL_QCOWS+=("$tgt")
	done
else
	for q in "${QCOWS_LOCAL[@]}"; do
		FINAL_QCOWS+=("$(readlink -f "$q")")
	done
fi

# Build disk args
DISK_ARGS=()
for q in "${FINAL_QCOWS[@]}"; do
	DISK_ARGS+=( --disk "path=$q,format=qcow2,bus=$DISK_BUS" )
done

# Graphics args
GRAPHIC_ARGS=()
case "$GRAPHICS" in
	spice) GRAPHIC_ARGS=( --graphics spice ) ;;
	vnc)   GRAPHIC_ARGS=( --graphics vnc ) ;;
	none)  GRAPHIC_ARGS=( --graphics none --console pty,target_type=serial ) ;;
	*)     echo "Invalid --graphics: $GRAPHICS" >&2; exit 1 ;;
esac

# Network
NETWORK_ARG=( --network "network=$NET" )
check_network() {
	local uri="$1" name="$2"
	if $VIRSH_CMD --connect "$uri" net-info "$name" >/dev/null 2>&1; then
		if ! $VIRSH_CMD --connect "$uri" net-info "$name" 2>/dev/null | grep -q "Active:.*yes"; then
			echo "==> Network '$name' inactive; starting..."
			if ! $VIRSH_CMD --connect "$uri" net-start "$name" >/dev/null 2>&1; then
				echo "Note: could not start network '$name'. Falling back to user networking."
				return 1
			fi
		fi
		return 0
	fi
	return 1
}
if [[ -n "$LIBVIRT_URI" && "$NET" != "user" ]]; then
	if ! check_network "$LIBVIRT_URI" "$NET"; then
		echo "Note: network '$NET' missing. Using user-mode."
		NETWORK_ARG=( --network user )
	fi
elif [[ -z "$LIBVIRT_URI" && "$NET" != "user" ]]; then
	echo "Note: no LIBVIRT_DEFAULT_URI set; using user-mode."
	NETWORK_ARG=( --network user )
fi

# Summary
echo "==> Creating VM:"
echo "	Name:        $VM_NAME"
echo "	RAM:         ${RAM_MB}MB"
echo "	vCPUs:       ${VCPUS}"
echo "	OS Variant:  ${OS_VARIANT}"
echo "	Disk bus:    ${DISK_BUS}"
echo "	Graphics:    ${GRAPHICS}"
echo "	Network:     ${NETWORK_ARG[*]}"
if [[ -n "$LIBVIRT_URI" ]]; then
	echo "	Connect:     $LIBVIRT_URI"
else
	echo "	Connect:     (default qemu:///session)"
fi
printf "	Disks:\n"; printf '	  - %s\n' "${FINAL_QCOWS[@]}"

if [[ "$ASSUME_YES" != "true" ]]; then
	read -rp "Proceed with virt-install? [y/N] " go
	case "${go,,}" in y|yes) ;; *) echo "Aborted."; exit 1;; esac
fi

# Create VM
virt-install \
	"${VIRT_CONNECT_ARGS[@]}" \
	--name "$VM_NAME" \
	--ram "$RAM_MB" \
	--vcpus "$VCPUS" \
	--import \
	--os-variant "$OS_VARIANT" \
	"${NETWORK_ARG[@]}" \
	"${DISK_ARGS[@]}" \
	"${GRAPHIC_ARGS[@]}" \
	--noautoconsole

echo "==> VM '$VM_NAME' created."
if [[ -n "$LIBVIRT_URI" ]]; then
	echo "	Manage:    virsh --connect $LIBVIRT_URI list --all"
	echo "	Start:     virsh --connect $LIBVIRT_URI start '$VM_NAME'"
else
	echo "	Manage:    virsh list --all"
	echo "	Start:     virsh start '$VM_NAME'"
fi
if [[ "$GRAPHICS" == "none" ]]; then
	echo "	Console:   virsh ${VIRT_CONNECT_ARGS[*]} console '$VM_NAME'"
else
	echo "	Viewer:    virt-viewer ${VIRT_CONNECT_ARGS[*]} '$VM_NAME'"
fi

popd >/dev/null

echo "==> Work dir kept at: $WORKDIR"

