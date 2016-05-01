//
//  main.swift
//  ImagesSizeChecker
//
//  Created by Andrew McKnight on 5/1/16.
//
//

import AppKit
import Foundation

func parseJSON(path: String) throws -> NSDictionary? {
    if !NSFileManager.defaultManager().fileExistsAtPath(path) {
        return nil
    }

    do {
        let JSONData = try NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
        return try NSJSONSerialization.JSONObjectWithData(JSONData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
    } catch {
        print("error: could not parse json at \(path)")
        exit(1)
    }
}

func parseImageSet(basePath: String) -> ImageSet? {

    let jsonPath = "\(basePath)/Contents.json"

    var optionalDict: NSDictionary?
    do {
        optionalDict = try parseJSON(jsonPath)
    } catch {
        print("error: \(jsonPath) does not exist")
    }

    guard let dict = optionalDict else {
        print("error: couldn't parse json at \(jsonPath)")
        exit(1)
    }

    guard let images = dict["images"] as? NSArray else {
        print("error: unexpected object value keyed on \"images\"")
        exit(1)
    }

    var single: Image?
    var double: Image?
    var triple: Image?

    for image in images {
        guard let imageDict = image as? NSDictionary else {
            print("error: unexpected object in \"images\" array")
            exit(1)
        }

        if let filename = imageDict["filename"] as? String {

            guard let scale = imageDict["scale"] as? String else {
                print("error: couldn't find value for key \"scale\"")
                exit(1)
            }

            guard let scaleValue = Scale(rawValue: scale) else {
                print("error: unexpected value for \"scale\"")
                exit(1)
            }

            let filePath = "\(basePath)/\(filename)"
            guard let ciImage = CIImage(contentsOfURL: NSURL(fileURLWithPath: filePath)) else {
                print("error: could not read file at \(filePath)")
                exit(1)
            }

            switch(scaleValue) {
            case .Single:
                single = Image(image: ciImage, scale: scaleValue)
            case .Double:
                double = Image(image: ciImage, scale: scaleValue)
            case .Triple:
                triple = Image(image: ciImage, scale: scaleValue)
            }
        }
    }

    // if all are nil, then we simply aren't providing this image

    if single == nil && double == nil && triple == nil {
        return nil
    }

    // if one is provided, we should provide them all

    guard let unwrappedSingle = single else {
        print("error: did not find a 1x image in \(basePath)")
        exit(1)
    }

    guard let unwrappedDouble = double else {
        print("error: did not find a 2x image in \(basePath)")
        exit(1)
    }

    guard let unwrappedTriple = triple else {
        print("error: did not find a 3x image in \(basePath)")
        exit(1)
    }

    return ImageSet(single: unwrappedSingle, double: unwrappedDouble, triple: unwrappedTriple)
}

func passType(fromJSON json: NSDictionary) -> PassType {
    var types = [PassType]()

    for type: PassType in [.Generic, .BoardingPass, .Coupon, .EventTicket, .StoreCard] {
        if json[type.rawValue] as? NSDictionary != nil {
            types.append(type)
        }
    }

    if types.count == 0 {
        print("error: no type definition found containing field definitions")
        exit(1)
    }

    if types.count > 1 {
        print("error: multiple pass definitions found: \(types)")
        exit(1)
    }

    return types.first!
}

func parsePass(path: String, images: PassImages) -> Pass {
    var optionalPassJSON: NSDictionary?
    do {
        optionalPassJSON = try parseJSON(path)
    } catch {
        print("error: couldn't parse \(path)")
        exit(1)
    }

    guard let passJSON = optionalPassJSON else {
        print("error: couldn't parse \(path)")
        exit(1)
    }

    guard let formatVersion = passJSON["formatVersion"] as? Int else {
        print("error: couldn't find formatVersion")
        exit(1)
    }

    if formatVersion != 1 {
        print("error: formatVersion must be 1")
        exit(1)
    }

    var barcode: BarCode?
    if let barcodeDict = passJSON["barcode"] as? NSDictionary {
        guard let message = barcodeDict["message"] as? String else {
            print("error: could not find barcode message")
            exit(1)
        }

        guard let format = barcodeDict["format"] as? String else {
            print("error: could not find barcode format")
            exit(1)
        }

        guard let formatValue = BarCodeFormat(rawValue: format) else {
            print("error: unknown barcode format supplied")
            exit(1)
        }

        barcode = BarCode(message: message, format: formatValue)
    }

    let type = passType(fromJSON: passJSON)

    return Pass(type: type, images: images, formatVersion: formatVersion, barcode: barcode)
}

func checkSizesInPass(pass: Pass) {
    var warnings = [String]()
    if let background = pass.images.background {
        if !(background.single.image.extent.size.width <= 180) { warnings.append("failed image size check: background.single.image.extent.size.width <= 180") }
        if !(background.single.image.extent.size.height <= 220) { warnings.append("failed image size check: background.single.image.extent.size.height <= 220") }

        if !(background.double.image.extent.size.width <= 180 * 2) { warnings.append("failed image size check: background.double.image.extent.size.width <= 180 * 2") }
        if !(background.double.image.extent.size.height <= 220 * 2) { warnings.append("failed image size check: background.double.image.extent.size.height <= 220 * 2") }

        if !(background.triple.image.extent.size.width <= 180 * 3) { warnings.append("failed image size check: background.triple.image.extent.size.width <= 180 * 3") }
        if !(background.triple.image.extent.size.height <= 220 * 3) { warnings.append("failed image size check: background.triple.image.extent.size.height <= 220 * 3") }
    }

    if let footer = pass.images.footer {
        if !(footer.single.image.extent.size.width <= 286) { warnings.append("failed image size check: footer.single.image.extent.size.width <= 286") }
        if !(footer.single.image.extent.size.height <= 15) { warnings.append("failed image size check: footer.single.image.extent.size.height <= 15") }

        if !(footer.double.image.extent.size.width <= 286 * 2) { warnings.append("failed image size check: footer.double.image.extent.size.width <= 286 * 2") }
        if !(footer.double.image.extent.size.height <= 15 * 2) { warnings.append("failed image size check: footer.double.image.extent.size.height <= 15 * 2") }

        if !(footer.triple.image.extent.size.width <= 286 * 3) { warnings.append("failed image size check: footer.triple.image.extent.size.width <= 286 * 3") }
        if !(footer.triple.image.extent.size.height <= 15 * 3) { warnings.append("failed image size check: footer.triple.image.extent.size.height <= 15 * 3") }
    }

    if let icon = pass.images.icon {
        if !(icon.single.image.extent.size.width <= 29) { warnings.append("failed image size check: icon.single.image.extent.size.width <= 29") }
        if !(icon.single.image.extent.size.height <= 29) { warnings.append("failed image size check: icon.single.image.extent.size.width <= 29") }

        if !(icon.double.image.extent.size.width <= 29 * 2) { warnings.append("failed image size check: icon.single.image.extent.size.width <= 29 * 2") }
        if !(icon.double.image.extent.size.height <= 29 * 2) { warnings.append("failed image size check: icon.single.image.extent.size.width <= 29 * 2") }

        if !(icon.triple.image.extent.size.width <= 29 * 3) { warnings.append("failed image size check: icon.single.image.extent.size.width <= 29 * 3") }
        if !(icon.triple.image.extent.size.height <= 29 * 3) { warnings.append("failed image size check: icon.single.image.extent.size.width <= 29 * 3") }
    }

    if let logo = pass.images.logo {
        if !(logo.single.image.extent.size.width <= 160) { warnings.append("failed image size check: logo.single.image.extent.size.width <= 160") }
        if !(logo.single.image.extent.size.height <= 50) { warnings.append("failed image size check: logo.single.image.extent.size.height <= 50") }

        if !(logo.double.image.extent.size.width <= 160 * 2) { warnings.append("failed image size check: logo.double.image.extent.size.width <= 160 * 2") }
        if !(logo.double.image.extent.size.height <= 50 * 2) { warnings.append("failed image size check: logo.double.image.extent.size.height <= 50 * 2") }

        if !(logo.triple.image.extent.size.width <= 160 * 3) { warnings.append("failed image size check: logo.triple.image.extent.size.width <= 160 * 3") }
        if !(logo.triple.image.extent.size.height <= 50 * 3) { warnings.append("failed image size check: logo.triple.image.extent.size.height <= 50 * 3") }
    }

    if let thumbnail = pass.images.thumbnail {
        if !(thumbnail.single.image.extent.size.width <= 90) { warnings.append("failed image size check: thumbnail.single.image.extent.size.width <= 90") }
        if !(thumbnail.single.image.extent.size.height <= 90) { warnings.append("failed image size check: thumbnail.single.image.extent.size.height <= 90") }
        let singleAspectRatio = thumbnail.single.image.extent.size.width / thumbnail.single.image.extent.size.height
        if !(singleAspectRatio >= (3.0 / 2.0) && singleAspectRatio >= (2.0 / 3.0)) { warnings.append("failed image size check: thumbnail @1x aspect ratio >= (3.0 / 2.0) && thumbnail @1x aspect ratio >= (2.0 / 3.0)") }

        if !(thumbnail.double.image.extent.size.width <= 90 * 2) { warnings.append("failed image size check: thumbnail.double.image.extent.size.width <= 90 * 2") }
        if !(thumbnail.double.image.extent.size.height <= 90 * 2) { warnings.append("failed image size check: thumbnail.double.image.extent.size.height <= 90 * 2") }
        let doubleAspectRatio = thumbnail.double.image.extent.size.width / thumbnail.double.image.extent.size.height
        if !(doubleAspectRatio >= (3.0 / 2.0) && doubleAspectRatio >= (2.0 / 3.0)) { warnings.append("failed image size check: thumbnail @2x aspect ratio >= (3.0 / 2.0) && thumbnail @2x aspect ratio >= (2.0 / 3.0)") }

        if !(thumbnail.triple.image.extent.size.width <= 90 * 3) { warnings.append("failed image size check: thumbnail.triple.image.extent.size.width <= 90 * 3") }
        if !(thumbnail.triple.image.extent.size.height <= 90 * 3) { warnings.append("failed image size check: thumbnail.triple.image.extent.size.height <= 90 * 3") }
        let tripleAspectRatio = thumbnail.triple.image.extent.size.width / thumbnail.triple.image.extent.size.height
        if !(tripleAspectRatio >= (3.0 / 2.0) && tripleAspectRatio >= (2.0 / 3.0)) { warnings.append("failed image size check: thumbnail @3x aspect ratio >= (3.0 / 2.0) && thumbnail @3x aspect ratio >= (2.0 / 3.0)") }
    }

    if let strip = pass.images.strip {
        // 1x checks
        if pass.type == .EventTicket {
            if !(strip.single.image.extent.size.width <= 320) { warnings.append("failed image size check: strip.single.image.extent.size.width <= 320") }
            if !(strip.single.image.extent.size.height <= 84) { warnings.append("failed image size check: strip.single.image.extent.size.height <= 84") }
        } else if let barcode = pass.barcode where barcode.format == BarCodeFormat.PKBarcodeFormatQR {
            if !(strip.single.image.extent.size.width <= 320) { warnings.append("failed image size check: strip.single.image.extent.size.width <= 320") }
            if !(strip.single.image.extent.size.height <= 110) { warnings.append("failed image size check: strip.single.image.extent.size.height <= 110") }
        } else {
            if !(strip.single.image.extent.size.width <= 320) { warnings.append("failed image size check: strip.single.image.extent.size.width <= 320") }
            if !(strip.single.image.extent.size.height <= 123) { warnings.append("failed image size check: strip.single.image.extent.size.height <= 123") }
        }

        // 2x/3x checks
        if pass.type == .EventTicket {
            if !(strip.double.image.extent.size.width <= 375 * 2) { warnings.append("failed image size check: strip.double.image.extent.size.width <= 375 * 2") }
            if !(strip.double.image.extent.size.height <= 98 * 2) { warnings.append("failed image size check: strip.double.image.extent.size.height <= 98 * 2") }

            if !(strip.triple.image.extent.size.width <= 375 * 3) { warnings.append("failed image size check: strip.triple.image.extent.size.width <= 375 * 3") }
            if !(strip.triple.image.extent.size.height <= 98 * 3) { warnings.append("failed image size check: strip.triple.image.extent.size.height <= 98 * 3") }
        } else if pass.type == .StoreCard || pass.type == .Coupon {
            if !(strip.double.image.extent.size.width <= 375 * 2) { warnings.append("failed image size check: strip.double.image.extent.size.width <= 375 * 2") }
            if !(strip.double.image.extent.size.height <= 144 * 2) { warnings.append("failed image size check: strip.double.image.extent.size.height <= 144 * 2") }

            if !(strip.triple.image.extent.size.width <= 375 * 3) { warnings.append("failed image size check: strip.triple.image.extent.size.width <= 375 * 3") }
            if !(strip.triple.image.extent.size.height <= 144 * 3) { warnings.append("failed image size check: strip.triple.image.extent.size.height <= 144 * 3") }
        } else {
            if !(strip.double.image.extent.size.width <= 375 * 2) { warnings.append("failed image size check: strip.double.image.extent.size.width <= 375 * 2") }
            if !(strip.double.image.extent.size.height <= 123 * 2) { warnings.append("failed image size check: strip.double.image.extent.size.height <= 123 * 2") }

            if !(strip.triple.image.extent.size.width <= 375 * 3) { warnings.append("failed image size check: strip.triple.image.extent.size.width <= 375 * 3") }
            if !(strip.triple.image.extent.size.height <= 123 * 3) { warnings.append("failed image size check: strip.triple.image.extent.size.height <= 123 * 3") }
        }
    }

    for warning in warnings {
        print("warning: \(warning)")
    }
}

let args = NSProcessInfo.processInfo().arguments

let backgroundImageSet = parseImageSet(args[2])
let footerImageSet = parseImageSet(args[3])
let iconImageSet = parseImageSet(args[4])
let logoImageSet = parseImageSet(args[5])
let stripImageSet = parseImageSet(args[6])
let thumbnailImageSet = parseImageSet(args[7])

let passImages = PassImages(background: backgroundImageSet, footer: footerImageSet, icon: iconImageSet, logo: logoImageSet, strip: stripImageSet, thumbnail: thumbnailImageSet)

let passPath = args[1]
let pass = parsePass(passPath, images: passImages)

checkSizesInPass(pass)

print("here")















