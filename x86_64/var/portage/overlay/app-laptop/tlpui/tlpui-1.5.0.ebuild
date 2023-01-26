EAPI=7
PYTHON_COMPAT=( python3_10 )

inherit autotools distutils-r1

DESCRIPTION="A GTK user interface for TLP written in Python"
HOMEPAGE="https://github.com/d4nj1/TLPUI/"

GIT_COMMIT="2edc214"
SRC_URI="https://github.com/d4nj1/TLPUI/tarball/${GIT_COMMIT} -> ${P}.tar.gz"


LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
	>=app-laptop/tlp-1.5.0"


S="${WORKDIR}/d4nj1-TLPUI-${GIT_COMMIT}"
