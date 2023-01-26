# Copyright 2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7

inherit autotools eutils

DESCRIPTION="x11spice connects a running X server as a Spice server"
HOMEPAGE="http://www.spice-space.org/"

GIT_COMMIT="21c9b06871f49c57f770bce99ed4300df8ec7972"
SRC_URI="https://gitlab.freedesktop.org/spice/x11spice/-/archive/version1.2/x11spice-version1.2.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~x86"
RESTRICT="mirror"

RDEPEND="sys-process/audit
         app-emulation/spice"

DEPEND="${RDEPEND}"

S="${WORKDIR}/x11spice-version1.2"

src_configure() {
   CFLAGS="$CFLAGS -I/usr/include/libdrm"
  ./autogen.sh
   econf --enable-dummy
}
