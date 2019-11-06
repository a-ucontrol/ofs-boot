
EAPI=5

inherit eutils

RESTRICT="strip"

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="${P}.tar.xz"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
"
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
    cp -r ./* ${D}/
}
