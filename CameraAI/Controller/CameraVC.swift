//
//  CameraVC.swift
//  CameraAI
//
//  Created by Trong Tran on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData


class CameraVC: UIViewController {
    
    let captureSession = AVCaptureSession()
    
    var previewLayer:CALayer!
    
    var captureDevice:AVCaptureDevice!
    
    var capturedImageView: UIImageView!
    
    var takePhoto = false
    
    var capturedImage: UIImage!
    
    var managedContext : NSManagedObjectContext?

    var flagSave: Bool = false
    
    @IBOutlet weak var viewScreenShot: UIView!
    
    @IBOutlet weak var btnShot: UIButton!
    
    @IBOutlet weak var viewSaveImage: UIStackView!
    
    @IBAction func takePhoto(_ sender: Any) {
        takePhoto = true
        viewScreenShot.isHidden = true
        viewSaveImage.isHidden = false
    }

    @IBAction func actSave(_ sender: Any) {
        flagSave = true
        self.performSegue(withIdentifier: "showImageDetailVC", sender: self)
        handleAfterCapturedImage()
    }
    
    @IBAction func actCancel(_ sender: Any) {
        handleAfterCapturedImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()

        viewScreenShot.layer.cornerRadius = viewScreenShot.frame.size.width / 2
        btnShot.layer.cornerRadius = btnShot.frame.size.width / 2

        coreDataSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (flagSave) {
            let labelContent = defaults.object(forKey: DEFAULTS_LABEL) as! String
            self.prepareImageForSaving(image: capturedImage, label: labelContent)
            flagSave = false
        }
    }
    
    func handleAfterCapturedImage(){
        capturedImageView.removeFromSuperview()
        viewScreenShot.isHidden = false
        viewSaveImage.isHidden = true
        previewLayer.isHidden = false
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showImageDetailVC") {
            let imageDetailVC = segue.destination as! ImageDetailVC
            imageDetailVC.image = capturedImage
        }
    }

}

extension CameraVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        if let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first {
            captureDevice = availableDevices
            beginSession()
        }
    }
    
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        }catch {
            print(error.localizedDescription)
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.layer.frame
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String):NSNumber(value:kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        captureSession.commitConfiguration()
        
        let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePhoto {
            takePhoto = false
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                DispatchQueue.main.async {
                    //Set and show image
                    self.capturedImageView = UIImageView(image: image)
                    self.capturedImageView.contentMode = .scaleAspectFit
                    self.capturedImageView.frame = self.previewLayer.frame
                    self.view.addSubview(self.capturedImageView)
                    self.previewLayer.isHidden = true
                    
                    //Get face image
                    let face = self.capturedImageView.getFaceImage()

                    //Have face
                    if (face.1 != nil) {
                        self.capturedImageView.image = face.1
                        self.capturedImage = face.1
                    }
                    //No face
                    else {
                        self.capturedImage = image
                    }
                }
            }
        }
    }
    
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }
}

///Core data handler
extension CameraVC {
    func coreDataSetup() {
        let moc: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        self.managedContext = moc
    }
    
    func prepareImageForSaving(image:UIImage, label: String) {
        // create NSData from UIImage
        image.pngData()
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            // handle failed conversion
            print("jpg error")
            return
        }
        
        DispatchQueue.main.async {
            // scale image, I chose the size of the VC because it is easy
            let thumbnail = image.scale(toSize: self.view.frame.size)
            guard let thumbnailData  = thumbnail.jpegData(compressionQuality: 0.7) else {
                // handle failed conversion
                print("jpg error")
                return
            }
            // send to save function
            self.saveImage(imageData: imageData as NSData, thumbnailData: thumbnailData as NSData, label: label)
        }
    }
    
    func saveImage(imageData:NSData, thumbnailData:NSData, label: String) {
        // create new objects in moc
        guard let moc = self.managedContext else {
            return
        }
        
        guard let fullRes = NSEntityDescription.insertNewObject(forEntityName: "FullRes", into: moc) as? FullRes, let thumbnail = NSEntityDescription.insertNewObject(forEntityName: "Thumbnail", into: moc) as? Thumbnail else {
            // handle failed new object in moc
            print("moc error")
            return
        }
        
        //set image data of fullres
        fullRes.imageData = imageData as Data
        
        //set image data of thumbnail
        thumbnail.imageData = thumbnailData as Data
        thumbnail.label = label
        thumbnail.fullRes = fullRes
        
        // save the new objects
        do {
            try moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        
        // clear the moc
        moc.refreshAllObjects()
    }
}

extension UIImageView {
    func getFaceImage() -> ([CIFaceFeature]?, UIImage?) {
        let faceDetectorOptions: [String: AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh as AnyObject]
        
        let faceDetector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: faceDetectorOptions)!
        
        let viewScreenShotImage = generateScreenShot(scaleTo: 1.0)
        
        if viewScreenShotImage.cgImage != nil {
            let sourceImage = CIImage(cgImage: viewScreenShotImage.cgImage!)
            
            //Add
            let faceFeatures = faceDetector.features(in: sourceImage) as! [CIFaceFeature]

            let features = faceDetector.features(in: sourceImage)
            if features.count > 0 {
                var faceBounds = CGRect.zero
                var faceImage: UIImage?
                for feature in features as! [CIFaceFeature] {
                    faceBounds = feature.bounds
                    let faceCroped: CIImage = sourceImage.cropped(to: faceBounds)
                    let cgImage: CGImage = {
                        let context = CIContext(options: nil)
                        return context.createCGImage(faceCroped, from: faceCroped.extent)!
                    }()
                    faceImage = UIImage(cgImage: cgImage)
                }
                return (faceFeatures, faceImage)
            } else {
                return (nil, nil)
            }
        } else {
            return (nil, nil)
        }
    }
    func generateScreenShot(scaleTo: CGFloat = 3.0) -> UIImage {
        let rect = self.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        self.layer.render(in: context!)
        let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let aspectRatio = screenShotImage.size.width / screenShotImage.size.height
        let resizedScreenShotImage = screenShotImage.scale(toSize: CGSize(width: self.bounds.size.height * aspectRatio * scaleTo, height: self.bounds.size.height * scaleTo))
        return resizedScreenShotImage
    }
}
