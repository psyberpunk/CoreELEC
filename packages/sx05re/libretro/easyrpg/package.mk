################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="easyrpg"
PKG_VERSION="22ac2b45d6b4bf2f04bf40deebaf58a6e36936ff"
PKG_SHA256="cec7e9609c5b12d44e4effc2ba165ddc3bc6074efc5699ab1a53444c810bf565"
PKG_REV="2"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/libretro/easyrpg-libretro"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="An unofficial libretro port of the EasyRPG/Player."
PKG_LONGDESC="An unofficial libretro port of the EasyRPG/Player."

PKG_IS_ADDON="no"
PKG_TOOLCHAIN="make"
PKG_AUTORECONF="no"
PKG_USE_CMAKE="no"

make_target() {
  make -C ../builds/libretro -f Makefile.libretro
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/lib/libretro
  cp ../builds/libretro/easyrpg_libretro.so $INSTALL/usr/lib/libretro/
}
