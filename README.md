# PKPassGenerator

`PKPassGenerator` provides a template for a generic Wallet (née PassKit) pass, and utilities to generate a pass with minimal effort.

## Building a Wallet Business Card

1. Create a new "Pass Type ID" Certificate at [developer.apple.com](http://developer.apple.com).
1. `make init`–this will install dependencies and make a copy of `pass.json.template` to `pass.json` for you to edit (see notes on JSON below)
1. Fill in the blanks provided in `pass.json` (see notes on JSON below)
1. In Xcode, add any images you'd like to include to `Images.xcassets` (see notes on Images below)
1. Build the pass
    - In Xcode, select the `Generate PKPass` scheme and build (⌘+B)
    - On the command line, `make pass`

> The last step builds the `ImageSizeChecker` and `signpass` executables and runs `create-pass.sh`, which checks the sizes of the images you provided, copies them along with `pass.json` into a directory called `$PASS_NAME.pass`, and provides that to `signpass`. 

> `PASS_NAME` is derived from the URL you specify for the hosted filename at `barcode.message` from pass.json. 

> `signpass.xcodeproj` is provided by Apple in their Wallet Programming Guide, and is included in this project to complete the signing process.

If everything works, a pass should appear on your screen, opened from the file called `$PASS_NAME.pkpass`.

## JSON

There is a template JSON file (`pass.json.template`) with placeholders where you fill in the appropriate required values, and a few sample fields for basic info to get you started. This is copied to `pass.json` for you to edit by `make init`, which is `.gitignore`d to avoid committing sensitive data to source control.

> This sets up a "generic" pass; see references linked below for more types, as well as fields you may include.

Some values to grab for JSON fields, from the Pass Type certificate you created (open it in Keychain Assistant to see its details):

- `passTypeIdentifier`: **Common Name** Pass Type ID: <this.value>
- `teamIdentifier`: **Organizational Unit**
- `barcode.message`: The location at which the `pkpass` file will be located and available for download to peoples' Wallets. 

## Images

> Do *not* use transparency in your `icon` image. Transparent regions are drawn as black when the icon is displayed in shares through Messages, emails, etc.

### Sizes

There are various guidelines on sizes of images, which the project will check and provide warnings for any violations. The following websites were used as references for the values used:

- [https://developer.apple.com/library/watchos/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html/apple_ref/doc/uid/TP40012195-CH4-SW52#//apple_ref/doc/uid/TP40012195-CH4-SW52](https://developer.apple.com/library/watchos/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html/apple_ref/doc/uid/TP40012195-CH4-SW52#//apple_ref/doc/uid/TP40012195-CH4-SW52)

> The background image (background.png) is displayed behind the entire front of the pass. The expected dimensions are 180 x 220 points. The image is cropped slightly on all sides and blurred. Depending on the image, you can often provide an image at a smaller size and let it be scaled up, because the blur effect hides details. This lets you reduce the file size without a noticeable difference in the pass.
The footer image (footer.png) is displayed near the barcode. The allotted space is 286 x 15 points.
The icon (icon.png) is displayed when a pass is shown on the lock screen and by apps such as Mail when showing a pass attached to an email. The icon should measure 29 x 29 points.
The logo image (logo.png) is displayed in the top left corner of the pass, next to the logo text. The allotted space is 160 x 50 points; in most cases it should be narrower.
The strip image (strip.png) is displayed behind the primary fields.
On iPhone 6 and 6 Plus The allotted space is 375 x 98 points for event tickets, 375 x 144 points for gift cards and coupons, and 375 x 123 in all other cases.
On prior hardware The allotted space is 320 x 84 points for event tickets, 320 x 110 points for other pass styles with a square barcode on devices with 3.5 inch screens, and 320 x 123 in all other cases.
The thumbnail image (thumbnail.png) displayed next to the fields on the front of the pass. The allotted space is 90 x 90 points. The aspect ratio should be in the range of 2:3 to 3:2, otherwise the image is cropped.

- [https://www.raywenderlich.com/25227/passbook-faq](https://www.raywenderlich.com/25227/passbook-faq)

> Note all the sizes below are in pixels for the retina images:
background@2x.png – 360px x 440px, the image is blurred and cropped a bit on all sides to fit visually inside passbook
icon@2x.png – 58px x 58px, a shine is automatically applied
logo@2x.png – 320px x 100px, usually you should not take up the whole width
strip@2x.png – 624px x 220px (sometimes varies a bit), a shine is applied, you can use suppressStripShine in your pass.json to disable the shine if you don’t want it
thumbnail@2x.png – 180px x 180px

- [https://www.raywenderlich.com/20734/beginning-passbook-part-1](https://www.raywenderlich.com/20734/beginning-passbook-part-1)

I'm still not 100% sure how to check for the proper size of `strip.png` per device or OS version, so if anyone has any insight please open a pull request!

## Hosting

As the tutorials linked below will note, if you'd like to host your pass from a website, there are some special considerations. This comes in handy if you like people to get your pass by scanning a barcode on it.

I store mine in AWS S3 (which will give me HTTPS service) with a `Content-Type` of `application/vnd.apple.pkpass`.

To test, try generating using the above steps, and upload your `.pkpass` file to your server at the same location you specify in the `pass.json`'s `barcode`->`message` value. Then, with the pass still showing on your Mac, open the Wallet app on an iDevice, select the ⊕ button next to passes, select "Scan Code to Add a Pass", and scan away. 

## References

Other helpful references:

- [http://www.atomicbird.com/blog/passbook-card-details](http://www.atomicbird.com/blog/passbook-card-details):
	Step-by-step guide to creating a business card for PassKit. Fairly dated but still helpful. Original inspiration for this project.
- [http://www.myuiviews.com/2014/06/01/step-by-step-create-a-passbook-business-card.html](http://www.myuiviews.com/2014/06/01/step-by-step-create-a-passbook-business-card.html):
	Another step-by-step guide used to supplement the one listed above.
- [Wallet Programming Guide](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/PassKit_PG/index.html#//apple_ref/doc/uid/TP40012195-CH1-SW1):
	Design guidelines for passes, as well as the overall development process
- [PassKit Package Format Reference](https://developer.apple.com/library/ios/documentation/UserExperience/Reference/PassKit_Bundle/Chapters/Introduction.html#//apple_ref/doc/uid/TP40012026-CH0-SW1):
	Reference for all the keys and values in the `pass.json` file, as well as the expected members of the `$PASS_NAME.pass` directory

## Next Steps

- Devise a way to manage multiple passes
- Automate creation of the "Pass Type ID" Certificate using [fastlane spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)
- Automate extraction of ID and Team ID from the certificate

**Pull requests welcome!**
