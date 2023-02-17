EAPI=7

inherit eutils

RESTRICT="strip"

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="${PN}-${PV}.tar.xz"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
media-libs/libjpeg-turbo
dev-libs/libxslt
media-libs/libva
"
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
    mkdir -p ${D}/usr ${D}/etc/ld.so.conf.d
    cp -r ./* ${D}/usr/
    cp ${FILESDIR}/llvm-32.conf ${D}/etc/ld.so.conf.d
}

pkg_postinst() {
HF=va_dri2.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/va\/${HF}>"/ /usr/include/va/${HF}
HF=va_glx.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/va\/${HF}>"/ /usr/include/va/${HF}
HF=va_x11.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/va\/${HF}>"/ /usr/include/va/${HF}
HF=va_dricommon.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/va\/${HF}>"/ /usr/include/va/${HF}
HF=va_backend_glx.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/va\/${HF}>"/ /usr/include/va/${HF}
HF=xsltconfig.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/libxslt\/${HF}>"/ /usr/include/libxslt/${HF}
HF=jconfig.h
sed -i s/'error "abi_x86_32 not supported by the package."'/"include <i686-pc-linux-gnu\/${HF}>"/ /usr/include/${HF}
}
