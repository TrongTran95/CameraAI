//
//  GlobalVariables.swift
//  CameraAI
//
//  Created by ivc on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import Foundation

enum ImageType: String {
    case FullRes
    case Thumbnail
}

var vectors = [Vector]()

var averageVectorObjects:[Vector] = []

let defaults = UserDefaults.standard

let DEFAULTS_LABEL = "UD_Label"

var fnet: FaceNet = FaceNet()

var fDetector: FaceDetector = FaceDetector()

extension UIImage {

    func scale(toSize newSize:CGSize) -> UIImage {

        // make sure the new size has the correct aspect ratio
        let aspectFill = self.size.resizeFill(toSize: newSize)

        UIGraphicsBeginImageContextWithOptions(aspectFill, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: aspectFill.width, height: aspectFill.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }

}
extension CGSize {

    func resizeFill(toSize: CGSize) -> CGSize {

        let scale : CGFloat = (self.height / self.width) < (toSize.height / toSize.width) ? (self.height / toSize.height) : (self.width / toSize.width)
        return CGSize(width: (self.width / scale), height: (self.height / scale))

    }
}
//https://medium.com/onfido-tech/live-face-tracking-on-ios-using-vision-framework-adf8a1799233
//https://stackoverflow.com/questions/43308621/cidetector-detected-face-image-is-not-showing
