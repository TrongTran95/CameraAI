//
//  Image+.swift
//  CameraAI
//
//  Created by Trong Tran on 12/17/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//


import UIKit

extension UIImage {
    func resizeImage(newWidth: CGFloat, newHeight: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: floor(newWidth),
                                           height: floor(newHeight)))
        self.draw(in: CGRect(x: 0,
                             y: 0,
                             width: newWidth,
                             height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension CIImage {
    func resizeImage(newWidth: CGFloat, newHeight: CGFloat) -> UIImage? {
        return UIImage(ciImage: self).resizeImage(newWidth: newWidth,
                                                  newHeight: newHeight)
    }
}
