# Copyright 2000-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake eutils

DESCRIPTION="C++ library for developing interactive web applications."
MY_P=${P/_/-}
HOMEPAGE="http://webtoolkit.eu/"
SRC_URI="https://github.com/kdeforche/wt/archive/${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="fcgi firebird graphicsmagick mysql pdf postgres qt5 resources +server +ssl +sqlite test"

RDEPEND="
	dev-libs/boost:=
	pdf? (
		media-libs/libharu
		x11-libs/pango
	)
	firebird? ( dev-db/firebird )
	graphicsmagick? ( media-gfx/graphicsmagick )
	postgres? ( dev-db/postgresql:* )
	mysql? ( virtual/mysql )
	qt5? ( dev-qt/qtcore:5 )
	sqlite? ( dev-db/sqlite:3 )
	fcgi? (
		dev-libs/fcgi
		virtual/httpd-fastcgi
	)
	server? (
		ssl? ( dev-libs/openssl )
	)
	sys-libs/zlib
"
DOCS="Changelog INSTALL"
S=${WORKDIR}/${MY_P}

pkg_setup() {
	if use !server && use !fcgi; then
		ewarn "You have to select at least built-in server support or fcgi support."
		ewarn "Invalid use flag combination, enable at least one of: server, fcgi"
	fi

	if use test && use !sqlite; then
		ewarn "Tests need sqlite, disabling."
	fi
}

src_prepare() {
	# just to be sure
	rm -rf Wt/Dbo/backend/amalgamation

	# fix png linking
	if use pdf; then
		sed -e 's/-lpng12/-lpng/' \
			-i cmake/WtFindHaru.txt || die
	fi

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DDESTDIR="${D}"
		-DLIB_INSTALL_DIR=$(get_libdir)
		-DBUILD_TESTS=$(usex test)
		-DSHARED_LIBS=ON
		-DMULTI_THREADED=ON
		-DUSE_SYSTEM_SQLITE3=ON
		-DWEBUSER=wt
		-DWEBGROUP=wt
		-DWT_WRASTERIMAGE_IMPLEMENTATION=$(usex graphicsmagick GraphicsMagick none)
		-DENABLE_FIREBIRD=$(usex firebird)
		-DENABLE_HARU=$(usex pdf)
		-DENABLE_MYSQL=$(usex mysql)
		-DENABLE_POSTGRES=$(usex postgres)
		-DENABLE_QT4=OFF
		-DENABLE_QT5=$(usex qt5)
		-DENABLE_SQLITE=$(usex sqlite)
		-DENABLE_SSL=$(usex ssl)
		-DCONNECTOR_FCGI=$(usex fcgi)
		-DCONNECTOR_HTTP=$(usex server)
		-DBUILD_EXAMPLES=OFF
	)

	cmake_src_configure
}

src_test() {
	# Tests need sqlite
	if use sqlite; then
		pushd "${CMAKE_BUILD_DIR}" > /dev/null
		./test/test || die
		popd > /dev/null
	fi
}

pkg_postinst() {
	if use fcgi; then
		elog "You selected fcgi support. Please make sure that the web-server"
		elog "has fcgi support and access to the fcgi socket."
		elog "You can use spawn-fcgi to spawn the witty-processes and run them"
		elog "in a chroot environment."
	fi
}
