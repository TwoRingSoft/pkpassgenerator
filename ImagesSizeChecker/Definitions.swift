//
//  Definitions.swift
//  ImagesSizeChecker
//
//  Created by Andrew McKnight on 5/1/16.
//
//

import AppKit
import Foundation

enum PassType: String {
    case Generic = "generic"
    case BoardingPass = "boardingPass"
    case Coupon = "coupon"
    case EventTicket = "eventTicket"
    case StoreCard = "storeCard"
}

struct Pass {
    var type: PassType
    var images: PassImages
    var formatVersion: Int
    var barcode: BarCode?
}

enum BarCodeFormat: String {
    case PKBarcodeFormatQR
    case PKBarcodeFormatPDF417
    case PKBarcodeFormatAztec
}

struct BarCode {
    var message: String
    var format: BarCodeFormat

}

struct PassImages {
    var background: ImageSet?
    var footer: ImageSet?
    var icon: ImageSet?
    var logo: ImageSet?
    var strip: ImageSet?
    var thumbnail: ImageSet?
}

struct ImageSet {
    var single: CIImage
    var double: CIImage
    var triple: CIImage
}

enum Scale: String {
    case Single = "1x"
    case Double = "2x"
    case Triple = "3x"
}
