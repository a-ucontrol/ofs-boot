# Copyright 2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=8

inherit autotools

DESCRIPTION="x11spice connects a running X server as a Spice server"
HOMEPAGE="http://www.spice-space.org/"

GIT_COMMIT="21c9b06871f49c57f770bce99ed4300df8ec7972"
SRC_URI="https://gitlab.freedesktop.org/spice/x11spice/-/archive/version1.2/x11spice-version1.2.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~x86"
RESTRICT="mirror"

RDEPEND="x11-libs/gtk+:3
         sys-process/audit
         app-emulation/spice"

DEPEND="${RDEPEND}"

S="${WORKDIR}/x11spice-version1.2"

src_configure() {
   CFLAGS="$CFLAGS -I/usr/include/libdrm -Wno-error"
  ./autogen.sh
   econf --enable-dummy
}
