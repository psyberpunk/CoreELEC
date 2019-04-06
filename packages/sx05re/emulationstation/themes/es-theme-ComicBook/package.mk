# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present CoreELEC (https://coreelec.org)

PKG_NAME="es-theme-ComicBook"
PKG_VERSION="9a68f104b609f5bd7c7a782090817ebe48e9a197"
PKG_SHA256="fad822542cf54d9e7136921ae1759a53545ada79a6e98bcc8ab14223e0b5d582"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/TMNTturtleguy/es-theme-ComicBook"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="emuelec"
PKG_SHORTDESC="ComicBook theme for Emulationstation"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"
PKG_TOOLCHAIN="manual"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/config/emulationstation/themes/$PKG_NAME
    cp -r * $INSTALL/usr/config/emulationstation/themes/$PKG_NAME
}
