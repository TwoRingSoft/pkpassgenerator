# PKPassGenerator

`PKPassGenerator` provides a template for a generic Wallet (née PassKit) pass, and utilities to generate a pass with minimal effort. 

**Note:** One part is necessarily manual: you must create a new "Pass Type ID" Certificate at [developer.apple.com](developer.apple.com).

Once you've done that, follow these steps to generate a pass:

1. fill in the blanks provided in `pass.json` (this sets up a "generic" pass; see references linked below for more types, as well as fields you can use)
2. add any images you'd like to include to `Images.xcassets`
3. in the Build Settings for `Generate PKPass`, set the value of `PASS_NAME` as you'd like your final pass' filename to be named
4. select the `Generate PKPass` scheme and build (⌘+B)

This will check the sizes of the images you provided, copy them along with `pass.json` into a directory called `$PASS_NAME.pass`, and run `signpass` on it. If everything goes ok, a pass should appear on your screen, opened from the file called `$PASS_NAME.pkpass`.

`signpass.xcodeproj` is provided by Apple in their Wallet Programming Guide, and is included here to complete the signing process.

## Images

**Note:** do *not* use transparency in your `icon` image. Transparent regions are drawn as black when the icon is displayed in shares through Messages, emails, etc.

### Sizes

There are various guidelines on sizes of images, which the project will check and provide warnings for any violations. The following websites were used as references for the values used:

- [https://developer.apple.com/library/watchos/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html/apple_ref/doc/uid/TP40012195-CH4-SW52#//apple_ref/doc/uid/TP40012195-CH4-SW52](https://developer.apple.com/library/watchos/documentation/UserExperience/Conceptual/PassKit_PG/Creating.html/apple_ref/doc/uid/TP40012195-CH4-SW52#//apple_ref/doc/uid/TP40012195-CH4-SW52)
- [https://www.raywenderlich.com/25227/passbook-faq](https://www.raywenderlich.com/25227/passbook-faq)
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

- Devise a way to manage multiple passes, from this project or otherwise (possibly including a better way to get the name in besides the `PASS_NAME` build setting)
- Automate creation of the "Pass Type ID" Certificate using [fastlane spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)
- Automate extraction of ID and Team ID from the certificate

**Pull requests welcome!**
