# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature unpacker xdg

MY_PN="${PN/-desktop-bin}"
MY_URI="https://github.com/jitsi/jitsi-meet-electron/releases/download/v${PV}"

DESCRIPTION="Desktop application for Jitsi Meet built with Electron"
HOMEPAGE="https://github.com/jitsi/jitsi-meet-electron"
SRC_URI="
	amd64? ( ${MY_URI}/jitsi-meet-amd64.deb -> ${PN}-amd64.deb )
"

S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* amd64"
RESTRICT="splitdebug"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret
	dev-db/sqlcipher
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nettle
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	virtual/udev
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango"

src_prepare() {
	default
	#rm opt/Jitsi\ Meet/{LICENSE.electron.txt,LICENSES.chromium.html} || die
}

src_install() {
	mv usr/share/doc/${MY_PN}-electron usr/share/doc/${PF} || die
	#gunzip usr/share/doc/${PF}/changelog.gz || die

	insinto /
	doins -r usr
	doins -r opt

	fperms +x /opt/Jitsi\ Meet/chrome-sandbox
	fperms +x /opt/Jitsi\ Meet/chrome_crashpad_handler
	fperms +x /opt/Jitsi\ Meet/jitsi-meet

	dosym ../../opt/Jitsi\ Meet/${MY_PN} /usr/bin/${MY_PN}
	dosym ${MY_PN} /usr/bin/jitsii-meet
}

pkg_postinst() {
	xdg_pkg_postinst
	optfeature "emojis" media-fonts/noto-emoji
}
