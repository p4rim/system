#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZOS_BUILD_ROOT="$ROOT/work-zos-root"

prepare_build_root() {
    echo "==> Building preinstalled Zen OS root filesystem"

    sudo rm -rf "$ZOS_BUILD_ROOT"
    sudo mkdir -p "$ZOS_BUILD_ROOT"
}

load_packages() {
    local duplicates

    duplicates="$(
        grep -Ev '^[[:space:]]*(#|$)' "$ROOT/zos/packages.x86_64" \
            | sort \
            | uniq -d
    )"

    if [[ -n "$duplicates" ]]; then
        echo "ERROR: Duplicate packages found:"
        echo "$duplicates"
        exit 1
    fi

    mapfile -t ZOS_PACKAGES \
        < <(grep -Ev '^[[:space:]]*(#|$)' "$ROOT/zos/packages.x86_64")

    echo "==> Zen OS target packages: ${#ZOS_PACKAGES[@]}"
    printf '    %s\n' "${ZOS_PACKAGES[@]}"
}

install_packages() {
    sudo pacstrap -K "$ZOS_BUILD_ROOT" "${ZOS_PACKAGES[@]}"
}

apply_overlay() {
    echo "==> Applying Zen OS filesystem overlay"

    sudo cp -a "$ROOT/zos/rootfs/." "$ZOS_BUILD_ROOT/"
    sudo chown -R root:root "$ZOS_BUILD_ROOT/etc/chromium"
}

configure_rootfs() {
    echo "==> Configuring baked Zen OS filesystem"

    sudo sed -i \
        's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
        "$ZOS_BUILD_ROOT/etc/locale.gen"

    sudo arch-chroot "$ZOS_BUILD_ROOT" locale-gen

    sudo arch-chroot "$ZOS_BUILD_ROOT" \
        ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime

    sudo arch-chroot "$ZOS_BUILD_ROOT" systemctl enable NetworkManager

    sudo arch-chroot "$ZOS_BUILD_ROOT" dconf update
}

pack_rootfs() {
    echo "==> Packing Zen OS root filesystem"

    sudo mkdir -p "$ROOT/airootfs/usr/share/zos"

    sudo rm -f "$ROOT/airootfs/usr/share/zos/rootfs.tar.zst"

    sudo tar \
        --acls \
        --xattrs \
        --numeric-owner \
        -C "$ZOS_BUILD_ROOT" \
        -I 'zstd -19 -T0' \
        -cf "$ROOT/airootfs/usr/share/zos/rootfs.tar.zst" \
        .
}

prepare_installer() {
    echo "==> Preparing Zen OS installer"

    sudo cp "$ROOT/zos/install.sh" \
        "$ROOT/airootfs/usr/share/zos/install.sh"

    sudo chmod 755 \
        "$ROOT/airootfs/usr/share/zos/install.sh"
}

build_iso() {
    echo "==> Building Zen OS ISO"

    sudo rm -rf "$ROOT/work"

    sudo mkarchiso \
        -v \
        -w "$ROOT/work" \
        -o "$ROOT/out" \
        "$ROOT"
}

main() {
    prepare_build_root
    load_packages
    install_packages
    apply_overlay
    configure_rootfs
    pack_rootfs
    prepare_installer
    build_iso
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
