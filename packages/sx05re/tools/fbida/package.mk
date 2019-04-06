# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present CoreELEC (https://coreelec.org)

PKG_NAME="fbida"
PKG_VERSION="b733a22190c70443fedcd4e87397c426c9d48af6"
PKG_SHA256="4aa43acc5c47fac8cb54db787d7a77ad4c20c08e2913162cf52a53ab9533740f"
PKG_ARCH="any"
PKG_SITE="https://github.com/kraxel/fbida"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain libexif pixman libdrm libepoxy tiff"
PKG_SHORTDESC="The fbida project contains a few applications for viewing and editing images, with the main focus being photos."
PKG_LONGDESC="The fbida project contains a few applications for viewing and editing images, with the main focus being photos."
PKG_TOOLCHAIN="manual"

pre_configure_target() {
  sed -i "s|cpp -include jpeglib.h|$CPP -include $SYSROOT_PREFIX/usr/include/jpeglib.h|" GNUmakefile

  CFLAGS="$CFLAGS -I$(get_build_dir libepoxy)/include"
}

make_target() {
  make -f GNUmakefile fbi
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
    cp fbi $INSTALL/usr/bin
}
