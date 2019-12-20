//
//  FaceNet.swift
//  CameraAI
//
//  Created by Trong Tran on 12/17/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit

typealias FaceOutput = [CIImage]

// MARK: - FaceNet
final class FaceNet {
    
    private var tfFacenet: tfWrap?
    
    // MARK: - Methods
    func load(modelName: String) {
        clean()
        tfFacenet = tfWrap()
        tfFacenet?.loadModel(modelName,
                             labels: nil,
                             memMapped: false,
                             optEnv: true)
        tfFacenet?.setInputLayer("input",
                                 outputLayer: "embeddings")
    }
    
    func run(image: CIImage) -> [Double] {
        let inputEdge = 160
        guard let tfFacenet = tfFacenet,
              //Resize image to 160x160
              let resize = image.resizeImage(newWidth: CGFloat(inputEdge),
                                             newHeight: CGFloat(inputEdge))?.cgImage else { return [] }
        let input = CIImage(cgImage: resize)
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            inputEdge,
                            inputEdge,
                            kCVPixelFormatType_32BGRA,
                            [String(kCVPixelBufferIOSurfacePropertiesKey): [:]] as CFDictionary,
                            &buffer)
        if let buffer = buffer { CIContext().render(input, to: buffer) }
        guard let network_output = tfFacenet.run(onFrame: buffer) else { return [] }
        let output = network_output.compactMap {
            ($0 as? NSNumber)?.doubleValue
        }
        return output
    }
    
    func clean() {
        tfFacenet?.clean()
        tfFacenet = nil
    }
    
    func loadedModel() -> Bool {
        return tfFacenet != nil
    }
    
}

// MARK: - FaceDetector
final class FaceDetector {
    
    private let faceDetector = CIDetector(ofType: CIDetectorTypeFace,
                                          context: nil,
                                          options: [ CIDetectorAccuracy: CIDetectorAccuracyHigh ])
    
    func extractFaces(frame: CIImage) -> FaceOutput {
        guard let features = faceDetector?.features(in: frame) else {
            return []
        }
        let faces = features.map({ (f) -> CIImage in
            let rect = f.bounds
            let cropped = frame.cropped(to: rect)
            let face = cropped.transformed(by: CGAffineTransform(translationX: -rect.origin.x,
                                                                 y: -rect.origin.y))
            return face
        })
        return faces
    }
}
//
//extension UIImage{
//    var faces: [UIImage] {
//        guard let ciimage = CIImage(image: self) else { return [] }
//        var orientation: NSNumber {
//            switch imageOrientation {
//            case .up:            return 1
//            case .upMirrored:    return 2
//            case .down:          return 3
//            case .downMirrored:  return 4
//            case .leftMirrored:  return 5
//            case .right:         return 6
//            case .rightMirrored: return 7
//            case .left:          return 8
//            default:             return 0
//            }
//        }
//        return CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])?
//            .features(in: ciimage, options: [CIDetectorImageOrientation: orientation])
//            .compactMap {
//                let rect = $0.bounds.insetBy(dx: -10, dy: -10)
//                UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
//                defer { UIGraphicsEndImageContext() }
//                UIImage(ciImage: ciimage.cropped(to: rect)).draw(in: CGRect(origin: .zero, size: rect.size))
//                guard let face = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
//                // now that you have your face image you need to properly apply a circle mask to it
//                let size = face.size
//                let breadth = min(size.width, size.height)
//                let breadthSize = CGSize(width: breadth, height: breadth)
//                UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
//                defer { UIGraphicsEndImageContext() }
//                guard let cgImage = face.cgImage?.cropping(to: CGRect(origin: CGPoint(x: size.width > size.height ? (size.width-size.height).rounded(.down)/2 : 0, y: size.height > size.width ? (size.height-size.width).rounded(.down)/2 : 0), size: breadthSize))
//                    else { return nil }
//                let faceRect = CGRect(origin: .zero, size: CGSize(width: min(size.width, size.height), height: min(size.width, size.height)))
//                UIBezierPath(ovalIn: faceRect).addClip()
//                UIImage(cgImage: cgImage).draw(in: faceRect)
//                return UIGraphicsGetImageFromCurrentImageContext()
//            } ?? []
//    }
//}
