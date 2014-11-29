#!/bin/sh -ex

#
# 1. Tcl code
#

CAIUS_INSTALL_DIR="$XPACK_INSTALL_DIR/usr/share/tcltk/tcl8.6/caius"

mkdir -p "$CAIUS_INSTALL_DIR/bin"

cp -a  $XPACK_BASE_DIR/lib/*      "$CAIUS_INSTALL_DIR/"
cp -a "$XPACK_BASE_DIR/xsl"       "$CAIUS_INSTALL_DIR/"
cp -a "$XPACK_BASE_DIR/bin/caius" "$CAIUS_INSTALL_DIR/bin/"

#
# 2. man pages
#

CAIUS_MAN_DIR="$XPACK_INSTALL_DIR/usr/share/man/man3"

mkdir -p "$CAIUS_MAN_DIR"

cp -a $XPACK_BASE_DIR/doc/_manpages/*.3caius.gz "$CAIUS_MAN_DIR"

#
# 3. HTML documentation
#

CAIUS_DOC_DIR="$XPACK_INSTALL_DIR/usr/share/doc/caius/"

mkdir -p "$CAIUS_DOC_DIR"

cp -a $XPACK_BASE_DIR/doc/_site $CAIUS_DOC_DIR/html

# keep this in a separate folder!
rm -f $CAIUS_DOC_DIR/html/assets/img/cogwheels*.png
rm -f $CAIUS_DOC_DIR/html/assets/img/spaceman*.png

#
# 4. Changelog and LICENSE files
#

xsltproc $XPACK_BASE_DIR/xsl/changelog.xsl pack/changelog.xml | gzip \
    > $CAIUS_DOC_DIR/Changelog.gz

cp $XPACK_BASE_DIR/LICENSE $CAIUS_DOC_DIR
cp $XPACK_BASE_DIR/THANKS  $CAIUS_DOC_DIR

