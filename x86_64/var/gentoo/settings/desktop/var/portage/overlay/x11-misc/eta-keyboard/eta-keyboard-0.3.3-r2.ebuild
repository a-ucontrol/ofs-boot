
EAPI=6
inherit eutils qmake-utils

DESCRIPTION="Qt virtual Keyboard"
HOMEPAGE="https://github.com/E-Tahta/eta-keyboard"
SRC_URI="https://github.com/E-Tahta/eta-keyboard/archive/debian/${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/eta-keyboard-debian-$PV"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
dev-qt/qtgui:5
"
RDEPEND="
${DEPEND}
"

src_configure() {
    epatch "$FILESDIR/timer-interval.patch" || die
    eqmake5
}

src_install() {
	insinto /usr
	dobin eta-keyboard
	dobin ${FILESDIR}/vkeyboard
	insinto /usr/share/applications
	doins ${FILESDIR}/*.desktop
}
