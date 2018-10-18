#!/bin/sh

#  create-pass.sh
#  PKPassGenerator
#
#  Created by Andrew McKnight on 5/1/16.
#

set -x

# get the location of the root of the pass files, from PROJECT_DIR if building in Xcode, or from a path parameter from sh/make
if [[ -z "${PROJECT_DIR}" ]]; then
    ROOT_DIR="${1}"
else
    ROOT_DIR="${PROJECT_DIR}"
fi

# get the location of the executables for ImagesSizeChecker and signpass
if [[ -z "${BUILT_PRODUCTS_DIR}" ]]; then
    EXE_DIR="${2:-bin}" # may specify a custom override for this, but defaults to the current directory, where make:tools puts them
else
    EXE_DIR="${BUILT_PRODUCTS_DIR}"
fi

"${EXE_DIR}/ImagesSizeChecker"                      \
    $ROOT_DIR/pass.json                             \
    $ROOT_DIR/Images.xcassets/background.imageset   \
    $ROOT_DIR/Images.xcassets/footer.imageset       \
    $ROOT_DIR/Images.xcassets/icon.imageset         \
    $ROOT_DIR/Images.xcassets/logo.imageset         \
    $ROOT_DIR/Images.xcassets/strip.imageset        \
    $ROOT_DIR/Images.xcassets/thumbnail.imageset

# derive a pass name from the JSON
DOWNLOAD_URL=$(jq '.barcode.message' pass.json | sed s/\"//g)
PASS_NAME=$(basename -s '.pkpass' $DOWNLOAD_URL)

# copy resources into pass container directory
PASS_DIR="${ROOT_DIR}/${PASS_NAME}.pass"
rm -rf "${PASS_DIR}"
mkdir "${PASS_DIR}"
echo "${PASS_DIR}"
find "${ROOT_DIR}/Images.xcassets" -type f -name "*.png" | xargs -I {} cp {} "${PASS_DIR}"
cp "${ROOT_DIR}/pass.json" "${PASS_DIR}"

# sign the bundle
SIGN_PASS_CMD="${EXE_DIR}/signpass -p ${PASS_DIR}"
echo "${SIGN_PASS_CMD}"
eval "${SIGN_PASS_CMD}"

open "${ROOT_DIR}/${PASS_NAME}.pkpass"
