# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team CoreELEC (https://coreelec.org)

PKG_NAME="fbterm"
PKG_VERSION="926af0f9407a3aeebeeb5669cb13475c232f82ee"
PKG_SHA256=""
PKG_LICENSE="GPLv2+"
PKG_SITE="https://github.com/joeky888/fbterm"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC=" fbterm is a framebuffer based terminal emulator for linux "
PKG_TOOLCHAIN="configure"

pre_configure_target() {
  cd ..
  rm -rf .$TARGET_NAME
}

makeinstall_target() { 
mkdir -p $INSTALL/usr/bin
cp -rf $PKG_BUILD/src/fbterm $INSTALL/usr/bin
mkdir -p $INSTALL/usr/share/terminfo
cp -rf $PKG_DIR/terminfo/* $INSTALL/usr/share/terminfo/
tic $PKG_BUILD/terminfo/fbterm -o $INSTALL/usr/share/terminfo
# mv $INSTALL/usr/share/terminfo/f/fbterm $INSTALL/usr/share/terminfo/f/linux
# mv $INSTALL/usr/share/terminfo/f $INSTALL/usr/share/terminfo/l
# mkdir -p $INSTALL/usr/share/terminfo/f/
# cp $PKG_BUILD/terminfo/fbterm $INSTALL/usr/share/terminfo/f/
}
