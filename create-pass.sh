#!/bin/sh

#  create-pass.sh
#  PKPassGenerator
#
#  Created by Andrew McKnight on 5/1/16.
#

set -eou

"$BUILT_PRODUCTS_DIR/ImagesSizeChecker" \
$PROJECT_DIR/pass.json \
$PROJECT_DIR/Images.xcassets/background.imageset \
$PROJECT_DIR/Images.xcassets/footer.imageset \
$PROJECT_DIR/Images.xcassets/icon.imageset \
$PROJECT_DIR/Images.xcassets/logo.imageset \
$PROJECT_DIR/Images.xcassets/strip.imageset \
$PROJECT_DIR/Images.xcassets/thumbnail.imageset

# Copy resources into directory
PASS_DIR="$PROJECT_DIR/$PASS_NAME.pass"
rm -rf "$PASS_DIR"
mkdir "$PASS_DIR"
echo "$PASS_DIR"
find "$PROJECT_DIR/Images.xcassets" -type f -name "*.png" | xargs -I {} cp {} "$PASS_DIR"
cp "$PROJECT_DIR/pass.json" "$PASS_DIR"

# sign the bundle
SIGN_PASS_CMD="$BUILT_PRODUCTS_DIR/signpass -p $PASS_DIR"
echo "$SIGN_PASS_CMD"
eval "$SIGN_PASS_CMD"

open "$PROJECT_DIR/$PASS_NAME.pkpass"