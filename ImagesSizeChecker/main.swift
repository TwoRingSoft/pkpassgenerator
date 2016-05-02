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

    var single: CIImage?
    var double: CIImage?
    var triple: CIImage?

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
                single = ciImage
            case .Double:
                double = ciImage
            case .Triple:
                triple = ciImage
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

func checkImageSet(set: ImageSet, name: String, size: CGSize) -> [String] {
    var warnings = [String]()

    if !(set.single.extent.size.width <= size.width) { warnings.append("\(name)@1x width must be <= \(size.width)") }
    if !(set.single.extent.size.height <= size.height) { warnings.append("\(name)@1x height must be <= \(size.height)") }

    if !(set.double.extent.size.width <= size.width * 2) { warnings.append("\(name)@2x width must be <= \(size.width * 2)") }
    if !(set.double.extent.size.height <= size.height * 2) { warnings.append("\(name)@2x height must be <= \(size.height * 2)") }

    if !(set.triple.extent.size.width <= size.width * 3) { warnings.append("\(name)@3x width must be <= \(size.width * 3)") }
    if !(set.triple.extent.size.height <= size.height * 3) { warnings.append("\(name)@3x height must be <= \(size.height * 3)") }

    return warnings
}

func checkSizesInPass(pass: Pass) {
    var warnings = [String]()
    if let background = pass.images.background {
        warnings.appendContentsOf(checkImageSet(background, name: "background", size: CGSize(width: 180, height: 220)))
    }

    if let footer = pass.images.footer {
        warnings.appendContentsOf(checkImageSet(footer, name: "footer", size: CGSize(width: 286, height: 15)))
    }

    if let icon = pass.images.icon {
        warnings.appendContentsOf(checkImageSet(icon, name: "icon", size: CGSize(width: 29, height: 29)))
    }

    if let logo = pass.images.logo {
        warnings.appendContentsOf(checkImageSet(logo, name: "logo", size: CGSize(width: 160, height: 50)))
    }

    if let thumbnail = pass.images.thumbnail {
        warnings.appendContentsOf(checkImageSet(thumbnail, name: "thumbnail", size: CGSize(width: 90, height: 90)))

        let singleAspectRatio = thumbnail.single.extent.size.width / thumbnail.single.extent.size.height
        if !(singleAspectRatio <= (3.0 / 2.0) && singleAspectRatio >= (2.0 / 3.0)) { warnings.append("thumbnail @1x aspect ratio must be <= 3/2 and >= 2/3") }

        let doubleAspectRatio = thumbnail.double.extent.size.width / thumbnail.double.extent.size.height
        if !(doubleAspectRatio <= (3.0 / 2.0) && doubleAspectRatio >= (2.0 / 3.0)) { warnings.append("thumbnail @2x aspect ratio must be <= 3/2 and >= 2/3") }

        let tripleAspectRatio = thumbnail.triple.extent.size.width / thumbnail.triple.extent.size.height
        if !(tripleAspectRatio <= (3.0 / 2.0) && tripleAspectRatio >= (2.0 / 3.0)) { warnings.append("thumbnail @3x aspect ratio must be <= 3/2 and >= 2/3") }
    }

    // FIXME: the checks for strip.png are probably not 100% accurate
    if let strip = pass.images.strip {
        // 1x checks
        if pass.type == .EventTicket {
            if !(strip.single.extent.size.width <= 320) { warnings.append("strip@1x width must be <= 320 for Event Tickets") }
            if !(strip.single.extent.size.height <= 84) { warnings.append("strip@1x height must be <=84 for Event Tickets") }
        } else if let barcode = pass.barcode where barcode.format == BarCodeFormat.PKBarcodeFormatQR {
            if !(strip.single.extent.size.width <= 320) { warnings.append("strip@1x width must be <= 320 when appearing with QR codes") }
            if !(strip.single.extent.size.height <= 110) { warnings.append("strip@1x height must be <= 110 when appearing with QR codes") }
        } else {
            if !(strip.single.extent.size.width <= 320) { warnings.append("strip@1x width must be <= 320") }
            if !(strip.single.extent.size.height <= 123) { warnings.append("strip@1x height must be <= 123") }
        }

        // 2x/3x checks
        if pass.type == .EventTicket {
            if !(strip.double.extent.size.width <= 375 * 2) { warnings.append("strip@2x width must be <= \(375 * 2) for Event Tickets") }
            if !(strip.double.extent.size.height <= 98 * 2) { warnings.append("strip@2x height must be <= \(98 * 2) for Event Tickets") }

            if !(strip.triple.extent.size.width <= 375 * 3) { warnings.append("strip@3x width must be <= \(375 * 3) for Event Tickets") }
            if !(strip.triple.extent.size.height <= 98 * 3) { warnings.append("strip@3x height must be <= \(98 * 3) for Event Tickets") }
        } else if pass.type == .StoreCard || pass.type == .Coupon {
            if !(strip.double.extent.size.width <= 375 * 2) { warnings.append("strip@2x width must be <= \(375 * 2) for Store Cards and Coupons") }
            if !(strip.double.extent.size.height <= 144 * 2) { warnings.append("strip@2x height must be <= \(144 * 2) for Store Cards and Coupons") }

            if !(strip.triple.extent.size.width <= 375 * 3) { warnings.append("strip@3x width must be <= \(375 * 3) for Store Cards and Coupons") }
            if !(strip.triple.extent.size.height <= 144 * 3) { warnings.append("strip@3x height must be <= \(144 * 3) for Store Cards and Coupons") }
        } else {
            if !(strip.double.extent.size.width <= 375 * 2) { warnings.append("strip@2x width must be <= \(375 * 2)") }
            if !(strip.double.extent.size.height <= 123 * 2) { warnings.append("strip@2x height must be <= \(123 * 2)") }

            if !(strip.triple.extent.size.width <= 375 * 3) { warnings.append("strip@3x width must be <= \(375 * 3)") }
            if !(strip.triple.extent.size.height <= 123 * 3) { warnings.append("strip@3x height must be <= \(123 * 2)") }
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















