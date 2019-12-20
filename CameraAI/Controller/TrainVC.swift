//
//  TrainVC.swift
//  CameraAI
//
//  Created by Trong Tran on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit
import CoreData

class TrainVC: UIViewController {
    let loadQueue = DispatchQueue(label: "loadQueue", attributes: .concurrent)
    
    var managedContext : NSManagedObjectContext?
    
    var arrTNImages: [Thumbnail] = []
    
    var arrFRImages: [FullRes] = []

    @IBOutlet weak var viewContainerLoading: UIView!
    @IBOutlet weak var progressTraining: UIProgressView!
    
    
    @IBOutlet weak var lblConvertImage: UILabel!
    @IBOutlet weak var imgViewCheckMark1: UIImageView!
    @IBOutlet weak var aiLoading1: UIActivityIndicatorView!
    
    @IBOutlet weak var viewClassification: UIView!
    @IBOutlet weak var lblClassification: UILabel!
    @IBOutlet weak var imgViewCheckMark2: UIImageView!
    @IBOutlet weak var aiLoading2: UIActivityIndicatorView!
    
    @IBOutlet weak var viewAverage: UIView!
    @IBOutlet weak var lblAverage: UILabel!
    @IBOutlet weak var imgViewCheckMark3: UIImageView!
    @IBOutlet weak var aiLoading3: UIActivityIndicatorView!
    
    @IBAction func actTrainingImage(_ sender: Any) {
        if viewContainerLoading.isHidden == true {
            viewContainerLoading.isHidden = false
            
            //Load data
            arrFRImages = loadFullResImages()
            
            //Train image and update slider, training label
            trainImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async {
            fnet.load(modelName: "modelFacenet.pb")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        coreDataSetup()
        arrTNImages = loadThumbnailImages()
    }
    
    func coreDataSetup() {
        loadQueue.sync {
            let moc: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

            self.managedContext = moc
        }
    }
    
    func convertImagesToVectors(imgList: [FullRes]) -> [Vector]{
        var vectors:[Vector] = []
        //Set data for progress view
        DispatchQueue.main.async {
            self.progressTraining.progress = 0
        }
        let total = self.arrFRImages.count
        let progressValueBy1 = 1.0/Float(total)
        //Update data and UI
        for i in 0..<total{
            let image = UIImage(data: self.arrFRImages[i].imageData!)
            let features = fDetector.extractFaces(frame: CIImage(image: image!)!)
            //Update data
            if (features.count != 0) {
                vectors.append(Vector(name: self.arrTNImages[i].label!, vector: fnet.run(image: features.first!)))
            }
            //Update UI
            DispatchQueue.main.async {
                self.progressTraining.progress += progressValueBy1
            }
        }
        //Update UI
        DispatchQueue.main.async {
            self.aiLoading1.isHidden = true
            self.imgViewCheckMark1.isHidden = false
            self.viewClassification.isHidden = false
        }
        return vectors
    }
    
    func classification(vectors: [Vector]) -> [String:[Vector]]{
        var faceClasses:[String:[Vector]] = [:]
        //Set data for progress view
        DispatchQueue.main.async {
            self.progressTraining.progress = 0
        }
        let progressValueBy1 = 1.0/Float(arrFRImages.count)
        //Devive to multy class by its vector's label
        for i in 0..<vectors.count {
            if (faceClasses[vectors[i].name] == nil) {
                faceClasses[vectors[i].name] = []
            }
            faceClasses[vectors[i].name]?.append(vectors[i])
            //Update UI
            DispatchQueue.main.async {
                self.progressTraining.progress += progressValueBy1
                self.lblClassification.text = "Found \(faceClasses.count) label"
            }
        }
        //Update UI
        DispatchQueue.main.async {
            self.aiLoading2.isHidden = true
            self.imgViewCheckMark2.isHidden = false
            self.viewAverage.isHidden = false
        }
        return faceClasses
    }
    
    func getAverageVectorObjects(faceClasses: [String:[Vector]]) -> [Vector]{
        var averageVectorObjects:[Vector] = []
        //Set data for progress view
        DispatchQueue.main.async {
            self.progressTraining.progress = 0
        }
        let progressValueBy1 = 1.0/Float(arrFRImages.count)
        //Get face class
        for faceClass in faceClasses{
            //Get vectors (images) in face class
            let imgVectors = faceClass.value
            var sumVector: [Double] = []
            //Sum
            for vector in imgVectors {
                if (sumVector == []) {
                    sumVector = vector.vector
                } else {
                    sumVector = zip(sumVector, vector.vector).map { v1, v2 in v1 + v2 }
                }
                //Update UI
                DispatchQueue.main.async {
                    self.progressTraining.progress += progressValueBy1
                }
            }
            //Average
            let averageVector = sumVector.map { v1 -> Double in
                return v1/Double(imgVectors.count)
            }
            //Create new vector
            let newVectorObject = Vector(name: faceClass.key, vector: averageVector)
            averageVectorObjects.append(newVectorObject)
        }
        //Update UI
        DispatchQueue.main.async {
            self.aiLoading3.isHidden = true
            self.imgViewCheckMark3.isHidden = false
            self.progressTraining.isHidden = true
        }
        return averageVectorObjects
    }
    
    func resetLoadingUI(){
        viewClassification.isHidden = true
        viewAverage.isHidden = true
        
        imgViewCheckMark1.isHidden = true
        imgViewCheckMark2.isHidden = true
        imgViewCheckMark3.isHidden = true
        
        aiLoading1.isHidden = false
        aiLoading2.isHidden = false
        aiLoading3.isHidden = false
        
        progressTraining.isHidden = false
    }
    
    func trainImage(){
        //Reset data and UI
        resetLoadingUI()
        vectors = []
        averageVectorObjects = []
        
        DispatchQueue.global().async {
            //Training
            vectors = self.convertImagesToVectors(imgList: self.arrFRImages)
            
            DispatchQueue.main.async {
                let faceClasses = self.classification(vectors: vectors)
                
                averageVectorObjects = self.getAverageVectorObjects(faceClasses: faceClasses)
                
                sleep(1)

                //Hide loading view
                self.viewContainerLoading.isHidden = true
            }
        }
    }

    func loadFullResImages() -> [FullRes] {
        guard let moc = self.managedContext else { return [] }
        
        let fetchRequest = NSFetchRequest<FullRes>(entityName: ImageType.FullRes.rawValue)
        
        do {
            return try moc.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    
    func loadThumbnailImages() -> [Thumbnail] {
        guard let moc = self.managedContext else { return [] }
        
        let fetchRequest = NSFetchRequest<Thumbnail>(entityName: ImageType.Thumbnail.rawValue)
        
        do {
            return try moc.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return []
        }
    }
}

extension TrainVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrTNImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrainCVC", for: indexPath) as! TrainCVC
        let currentIndex = indexPath.row
        cell.setData(imgData: arrTNImages[currentIndex].imageData!, labelTitle: arrTNImages[currentIndex].label!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 120)
    }
    
    
}
