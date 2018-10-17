//
//  main.swift
//  ImagesSizeChecker
//
//  Created by Andrew McKnight on 5/1/16.
//
//

import Foundation

let args = ProcessInfo.processInfo.arguments

let backgroundImageSet = parseImageSet(basePath: args[2])
let footerImageSet = parseImageSet(basePath: args[3])
let iconImageSet = parseImageSet(basePath: args[4])
let logoImageSet = parseImageSet(basePath: args[5])
let stripImageSet = parseImageSet(basePath: args[6])
let thumbnailImageSet = parseImageSet(basePath: args[7])

let passImages = PassImages(
    background: backgroundImageSet,
    footer: footerImageSet,
    icon: iconImageSet,
    logo: logoImageSet,
    strip: stripImageSet,
    thumbnail: thumbnailImageSet
)

let passPath = args[1]
let pass = parsePass(path: passPath, images: passImages)

checkSizesInPass(pass: pass)

print("Finished!")
