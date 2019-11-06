# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils pax-utils rpm user versionator

DESCRIPTION="Native linux client of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1C_Enterprise83-client"

SRC_URI="amd64? ( ${MY_PN}-${MY_PV}.x86_64.rpm
	    nls? ( ${MY_PN}-nls-${MY_PV}.x86_64.rpm ) )"

SLOT="8.3"
LICENSE="1CEnterprise_en"
KEYWORDS=""
RESTRICT="fetch strip"

IUSE="+nls"


RDEPEND="~app-office/1C_Enterprise-common-${PV}:${SLOT}
	~app-office/1C_Enterprise-server-${PV}:${SLOT}
	>=dev-libs/icu-4.6
	app-crypt/mit-krb5
	media-gfx/imagemagick
	net-print/cups
	x11-libs/libSM
	dev-libs/atk
	x11-libs/libXxf86vm
	>=sys-libs/e2fsprogs-libs-1.41
	>=x11-libs/cairo-1.0
	sys-libs/glibc:2.2
	>=sys-devel/gcc-3.4
	x11-libs/gtk+:2
	x11-libs/gdk-pixbuf:2
	dev-libs/glib:2
	net-libs/libsoup:2.4
	|| ( =net-libs/webkit-gtk-bin-3 net-libs/webkit-gtk:3 )
	app-text/enchant
	sys-libs/zlib"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
	dodir /opt /usr
	mv "${WORKDIR}"/opt/* "${D}"/opt
	local res
	for res in 16 22 24 32 36 48 64 72 96 128 192 256; do
		for icon in 1cestart 1cv8 1cv8c 1cv8s; do
			newicon -s ${res} "${WORKDIR}/usr/share/icons/hicolor/${res}x${res}/apps/${icon}.png" "${icon}.png"
		done
	done


	domenu "${WORKDIR}"/usr/share/applications/{1cv8,1cv8c,1cestart}.desktop
}

pkg_preinst() { gnome2_icon_savelist; }
pkg_postinst() { gnome2_icon_cache_update; fdo-mime_desktop_database_update; }
pkg_postrm() { gnome2_icon_cache_update; fdo-mime_desktop_database_update; }
