EAPI=8

inherit cmake virtualx xdg

DESCRIPTION="Quite Universal Circuit Simulator in Qt5"

SRC_URI="https://github.com/ra3xdh/qucs_s/releases/download/${PV}/qucs-s-${PV}.tar.gz"

KEYWORDS="amd64 ~arm ~x86"

LICENSE="GPL-2"
SLOT="0"

QT_PV="5.15:5"

CDEPEND="
	>=dev-qt/qtconcurrent-${QT_PV}
	>=dev-qt/qtcore-${QT_PV}
	>=dev-qt/qtdeclarative-${QT_PV}[widgets]
	>=dev-qt/qtgui-${QT_PV}
	>=dev-qt/qtnetwork-${QT_PV}[ssl]
	>=dev-qt/qtprintsupport-${QT_PV}
	>=dev-qt/qtquickcontrols-${QT_PV}
	>=dev-qt/qtscript-${QT_PV}
	>=dev-qt/qtsql-${QT_PV}[sqlite]
	>=dev-qt/qtsvg-${QT_PV}
	>=dev-qt/qtwidgets-${QT_PV}
	>=dev-qt/qtx11extras-${QT_PV}
	>=dev-qt/qtxml-${QT_PV}
"
DEPEND="${CDEPEND}"
RDEPEND="${CDEPEND}"
