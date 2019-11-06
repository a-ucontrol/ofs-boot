# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit eutils toolchain-funcs autotools

DESCRIPTION="locks the local X display until a password is entered"
HOMEPAGE="https://github.com/Arkq/alock"
SRC_URI="https://github.com/Arkq/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="imlib pam"

DEPEND="x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXpm
	x11-libs/libXrender
	x11-libs/libXcursor
	imlib? ( media-libs/imlib2[X] )
	pam? ( virtual/pam )
	"
RDEPEND="${DEPEND}"

src_configure() {
	eautoreconf
	econf \
		--prefix=/usr \
		$(use_enable pam) \
		$(use_enable imlib imlib2)
}
