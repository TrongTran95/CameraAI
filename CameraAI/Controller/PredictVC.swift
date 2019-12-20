//
//  PredictVC.swift
//  CameraAI
//
//  Created by ivc on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class PredictVC: UIViewController {
    
    let captureSession = AVCaptureSession()
    
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var captureDevice:AVCaptureDevice!
    
    var capturedImageView: UIImageView!
    
    var takePhoto = false
    
    var capturedImage: UIImage!
    
    var arrLabel: [Label] = []
    
    var pickedLabelIndex: Int = 0
    
    var managedContext : NSManagedObjectContext?
    var buffer: CMSampleBuffer!
    var timer = Timer()
    
    var flagStream: Bool!

    @IBOutlet weak var viewScreenShot: UIView!
    @IBOutlet weak var btnShot: UIButton!
    @IBOutlet weak var viewValidateImage: UIStackView!
    @IBOutlet weak var viewContainerCorrectLabel: UIView!
    @IBOutlet weak var pickerLabel: UIPickerView!
    @IBOutlet weak var viewPredictedLabel: UIView!
    @IBOutlet weak var lblPredictedLabel: UILabel!
    @IBOutlet weak var btnWrong: UIButton!
    @IBOutlet weak var btnCorrect: UIButton!
    
    @IBAction func actTakePhoto(_ sender: Any) {
        takePhoto = true
        viewScreenShot.isHidden = true
        viewValidateImage.isHidden = false
    }
    
    @IBAction func actShowWrongSheet(_ sender: UIButton) {
        //Success case
        if (sender.currentTitle == "WRONG") {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Take New Image", style: .destructive, handler: { alert in
                self.handleAfterCapturedImage()
                self.viewPredictedLabel.isHidden = true
                if (self.lblPredictedLabel.text == "Unidentify object"){
                    self.btnCorrect.isEnabled = true
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Edit Label", style: .default, handler: { alert in
                DispatchQueue.main.async {
                    //Handle UI
                    self.previewLayer.isHidden = true
                    self.view.bringSubviewToFront(self.viewContainerCorrectLabel)
                    self.viewContainerCorrectLabel.isHidden = false
                    
                    //Load label list and choose current position
                    self.arrLabel = self.loadLabels()
                    
                    //Reload data
                    self.pickerLabel.reloadAllComponents()

                    //Select row of picker view
                    self.pickerLabel.selectRow(self.pickedLabelIndex, inComponent: 0, animated: true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
        //Unidentify object
        else {
            btnWrong.setTitle("WRONG", for: .normal)
            btnCorrect.isEnabled = true
            handleAfterCapturedImage()
        }
    }
    
    @IBAction func actSaveImage(_ sender: Any) {
        prepareImageForSaving(image: capturedImage, label: lblPredictedLabel.text!)
        handleAfterCapturedImage()
        viewPredictedLabel.isHidden = true
    }
    
    @IBAction func actCancelCorrectLabel(_ sender: Any) {
        handleAfterCorrectLabel()
    }
    
    @IBAction func actTeachCorrectLabel(_ sender: Any) {
        viewContainerCorrectLabel.isHidden = true
        view.bringSubviewToFront(viewPredictedLabel)
        lblPredictedLabel.text = arrLabel[pickedLabelIndex].content
        btnCorrect.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()
        view.bringSubviewToFront(self.viewPredictedLabel)
        //Streaming
        if (flagStream) {
            viewPredictedLabel.isHidden = false
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(realTimeScanningFace), userInfo: nil, repeats: true)
        }
        //Capture
        else {
            coreDataSetup()
            viewScreenShot.layer.cornerRadius = viewScreenShot.frame.size.width / 2
            btnShot.layer.cornerRadius = btnShot.frame.size.width / 2
            viewPredictedLabel.layer.cornerRadius = 10
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (flagStream) {
            timer.invalidate()
        }
    }
    
    func handleAfterCorrectLabel(){
        previewLayer.isHidden = false
        capturedImageView.isHidden = true
        viewContainerCorrectLabel.isHidden = true
    }
    
    func handleAfterCapturedImage(){
        capturedImageView.isHidden = true
        viewScreenShot.isHidden = false
        viewValidateImage.isHidden = true
        viewPredictedLabel.isHidden = true
        previewLayer.isHidden = false
    }
}

///Predict here
extension PredictVC {
    func predict(image: UIImage) -> String {
        let features = fDetector.extractFaces(frame: CIImage(image: image)!)

        if (features.count == 0) { return "" }
        
        let targetVector = fnet.run(image: features.first!)
        
        
        //Calculate distance between target vector and calculated average vector object
        var smallestDistance:Double = 0
        for index in 0..<averageVectorObjects.count {
            let currentVector = averageVectorObjects[index]
            let distance = self.l2distance(targetVector, currentVector.vector)
            averageVectorObjects[index].distance = distance
            if (smallestDistance < distance) {
                smallestDistance = distance
            }
            print("\(averageVectorObjects[index].name) - \(averageVectorObjects[index].distance)")
        }
        
//        var min = averageVectorObjects.map{$0.distance}.min()
//        let object = averageVectorObjects.first(where: { $0.distance == 0.1})
//        let closest = averageVectorObjects.enumerated().min( by: { abs($0.element.distance - 5) < abs($0.element.distance - 5) } )!
        
        //Find smallest distance (to target vector)
        var result = Vector(name: "",
                            vector: [],
                            distance: 10)
        for vector in averageVectorObjects {
            if (vector.distance < result.distance) {
                result = vector
            }
        }
        return result.name
    }

    func l2distance(_ feat1: [Double], _ feat2: [Double]) -> Double {
        return sqrt(zip(feat1, feat2).map { f1, f2 in pow(f2 - f1, 2) }.reduce(0, +))
    }
}

///Camera handled here
extension PredictVC: AVCaptureVideoDataOutputSampleBufferDelegate {
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
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.layer.frame
        let navHeight = self.navigationController!.navigationBar.frame.size.height
        self.previewLayer.frame.origin.y += navHeight
        if (flagStream == false) {
            self.previewLayer.frame.size.height -= (navHeight + 75)
        } else {
            self.previewLayer.frame.size.height -= navHeight
        }
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
        //Case capture image
        if (!flagStream) {
            if takePhoto {
                takePhoto = false
                if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                    handlerPredictForCaptured(image)
                }
            }
        } else {
            buffer = sampleBuffer
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
    
    @objc func realTimeScanningFace(){
        if (buffer == nil) { return }
        if let image = self.getImageFromSampleBuffer(buffer: buffer) {
            DispatchQueue.main.async {
                //Set and show image
                self.capturedImageView = UIImageView(image: image)
                self.capturedImageView.contentMode = .scaleAspectFit
                self.capturedImageView.frame = self.previewLayer.frame

                //Predict
                self.predictAndShowLabel(of: self.capturedImageView)
            }
        }
    }
    
    func handlerPredictForCaptured(_ image: UIImage){
        DispatchQueue.main.async {
            //Set and show image
            self.capturedImageView = UIImageView(image: image)
            self.capturedImageView.contentMode = .scaleAspectFit
            self.capturedImageView.frame = self.previewLayer.frame
            
            self.view.addSubview(self.capturedImageView)
            self.previewLayer.isHidden = true
            
            //Predict
            self.predictAndShowLabel(of: self.capturedImageView)
        }
    }
    
    func predictAndShowLabel(of imageView: UIImageView){
        //Get face image
        let face = imageView.getFaceImage()
        
        //Have face
        if (face.1 != nil) {
            self.capturedImageView.image = face.1
            self.capturedImage = face.1
            DispatchQueue.global().async {
                //Predict
                let predictedLabel = self.predict(image: face.1!)
                DispatchQueue.main.async {
                    //Predict failed, allow to teach
                    if (predictedLabel == "") {
                        self.lblPredictedLabel.text = "Unidentify object"
                        self.btnCorrect.isEnabled = false
                    }
                    //Predict success
                    else {
                        self.lblPredictedLabel.text = predictedLabel
                    }
                    self.view.bringSubviewToFront(self.viewPredictedLabel)
                    self.viewPredictedLabel.isHidden = false
                }
            }
        }
        //No face
        else {
            self.capturedImage = imageView.image
            self.setUnidentifyObject()
        }
    }
    
    func setUnidentifyObject(){
        self.viewPredictedLabel.isHidden = false
        self.lblPredictedLabel.text = "Unidentify object"
        self.btnCorrect.isEnabled = false
        self.btnWrong.setTitle("TAKE AGAIN", for: .normal)
    }
    
    /*
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }
     */
}

///Picker view here
extension PredictVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrLabel.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return arrLabel[row].content
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickedLabelIndex = row
    }
}

///Core data handler
extension PredictVC {
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
    
    func loadLabels() -> [Label] {
        guard let moc = self.managedContext else { return [] }
        
        let fetchRequest = NSFetchRequest<Label>(entityName: "Label")
        let contentSort = NSSortDescriptor(key:"content", ascending:true)
        fetchRequest.sortDescriptors = [contentSort]

        do {
            let labels = try moc.fetch(fetchRequest)
            for i in 0..<labels.count {
                if (labels[i].content == ""){
                    pickedLabelIndex = i
                    break
                }
            }
            return labels
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return []
        }
    }
}
