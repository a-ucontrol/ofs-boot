# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="7"

inherit eutils unpacker

MY_P="Unigine_Heaven-${PV}"

DESCRIPTION="GPU benchmark with interactive mode"
HOMEPAGE="http://www.unigine.com/products/heaven/"
SRC_URI="${MY_P}.run"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~x86 amd64"
IUSE=""

RDEPEND="
media-libs/openal"

RESTRICT="fetch strip"

S="${WORKDIR}"

my_dir="/opt/${P}"

pkg_nofetch() {
	einfo "Please, download it from:"
	einfo "http://www.unigine.com/download/#heaven"
}

#pkg_setup() {
#	games_pkg_setup
#}

src_unpack() {
	unpack_makeself
}

src_install() {
	insinto "${my_dir}"
	doins -r "${S}"/data




#	exeinto "${my_dir}"/bin/x64
#	doexe "${S}"/bin/x64/*
#	exeinto "${my_dir}"/bin/x86
#	doexe "${S}"/bin/x86/*




	exeinto "${my_dir}"/bin/
	doexe "${S}"/bin/*

#	doexe "${S}"/bin/lib*
#	doexe "${S}"/bin/browser*
#	doexe "${S}"/bin/heaven*


	exeinto "${my_dir}"
	doexe "${S}"/heaven

#	games_make_wrapper Heaven_x64 "./heaven_x64" "${my_dir}"/bin
#	games_make_wrapper Heaven_x86 "./heaven_x86" "${my_dir}"/bin
}

pkg_postinst() {
	einfo "Example scripts for ${PN} can be found here:"
	einfo "${my_dir}"
}
