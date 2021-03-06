# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="bcm2835-driver"
PKG_VERSION="d095b96ac33de9eb4b95539cb3261f35a3c74509"
PKG_SHA256="f3d40adebe3dd0cb9a85e4c8b6dec864aedfaa9661e134f447655b2a33097c8c"
PKG_LICENSE="nonfree"
PKG_SITE="http://www.broadcom.com"
PKG_URL="$DISTRO_SRC/$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_DEPENDS_TARGET="toolchain dtc"
PKG_LONGDESC="OpenMAX-bcm2835: OpenGL-ES and OpenMAX driver for BCM2835"
PKG_TOOLCHAIN="manual"

if [ "$TARGET_FLOAT" = "softfp" -o "$TARGET_FLOAT" = "soft" ]; then
  FLOAT="softfp"
elif [ "$TARGET_FLOAT" = "hard" ]; then
  FLOAT="hardfp"
fi

make_target() {
  mkdir -p $SYSROOT_PREFIX/usr/include
    cp -PRv $FLOAT/opt/vc/include/* $SYSROOT_PREFIX/usr/include

  mkdir -p $SYSROOT_PREFIX/usr/lib
    cp -PRv $FLOAT/opt/vc/lib/*.so $SYSROOT_PREFIX/usr/lib
    ln -sf $SYSROOT_PREFIX/usr/lib/libbrcmEGL.so $SYSROOT_PREFIX/usr/lib/libEGL.so
    ln -sf $SYSROOT_PREFIX/usr/lib/libbrcmGLESv2.so $SYSROOT_PREFIX/usr/lib/libGLESv2.so
    cp -PRv $FLOAT/opt/vc/lib/*.a $SYSROOT_PREFIX/usr/lib
    cp -PRv $FLOAT/opt/vc/lib/pkgconfig $SYSROOT_PREFIX/usr/lib
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/lib
    cp -PRv $FLOAT/opt/vc/lib/*.so $INSTALL/usr/lib
    ln -sf /usr/lib/libbrcmEGL.so $INSTALL/usr/lib/libEGL.so
    ln -sf /usr/lib/libbrcmEGL.so $INSTALL/usr/lib/libEGL.so.1
    ln -sf /usr/lib/libbrcmGLESv2.so $INSTALL/usr/lib/libGLESv2.so
    ln -sf /usr/lib/libbrcmGLESv2.so $INSTALL/usr/lib/libGLESv2.so.2

# some useful debug tools
  mkdir -p $INSTALL/usr/bin
    cp -PRv $FLOAT/opt/vc/bin/dtoverlay $INSTALL/usr/bin
    ln -s dtoverlay $INSTALL/usr/bin/dtparam
    cp -PRv $FLOAT/opt/vc/bin/vcdbg $INSTALL/usr/bin
    cp -PRv $FLOAT/opt/vc/bin/vcgencmd $INSTALL/usr/bin
    cp -PRv $FLOAT/opt/vc/bin/tvservice $INSTALL/usr/bin
    cp -PRv $FLOAT/opt/vc/bin/edidparser $INSTALL/usr/bin

  mkdir -p $INSTALL/opt/vc
    ln -sf /usr/lib $INSTALL/opt/vc/lib
}

post_install() {
  enable_service unbind-console.service
}
