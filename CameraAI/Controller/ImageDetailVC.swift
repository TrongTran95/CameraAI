//
//  ImageDetailVC.swift
//  CameraAI
//
//  Created by Trong Tran on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit
import CoreData

class ImageDetailVC: UIViewController {
    
    var image: UIImage!
    
    var managedContext : NSManagedObjectContext?
    
    var arrLabel: [Label] = []
    
    var pickedLabel: String = ""
    
    var pickedLabelIndex: Int = 0
    
    @IBOutlet weak var imgCaptured: UIImageView!
    
    @IBOutlet weak var pickerLabel: UIPickerView!
    
    @IBAction func actAddNewLabel(_ sender: Any) {
        let alert = UIAlertController(title: "Add new label", message: "Enter a text", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.placeholder = "Input image's label"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            self.saveNewLabel(content: textField!.text!)
            self.arrLabel = self.loadLabels()
            DispatchQueue.main.async {
                self.pickerLabel.reloadAllComponents()
                self.pickerLabel.selectRow(self.pickedLabelIndex, inComponent: 0, animated: true)
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coreDataSetup()
        
        imgCaptured.image = image
    }
    
    override func viewWillAppear(_ animated: Bool) {
        arrLabel = loadLabels()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        defaults.set(arrLabel[pickedLabelIndex].content, forKey: DEFAULTS_LABEL)
    }

    func coreDataSetup() {
        let moc: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        self.managedContext = moc
    }
    
    func saveNewLabel(content: String){
        // create new objects in moc
        guard let moc = self.managedContext else {
            return
        }
        
        guard let label = NSEntityDescription.insertNewObject(forEntityName: "Label", into: moc) as? Label else {
            // handle failed new object in moc
            print("moc error")
            return
        }
        
        label.content = content
        pickedLabel = content
        
        // save the new objects
        do {
            try moc.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }

    func loadLabels() -> [Label] {
        guard let moc = self.managedContext else { return [] }
        
        let fetchRequest = NSFetchRequest<Label>(entityName: "Label")
        let contentSort = NSSortDescriptor(key:"content", ascending:true)
        fetchRequest.sortDescriptors = [contentSort]

        do {
            let labels = try moc.fetch(fetchRequest)
            for i in 0..<labels.count {
                if (labels[i].content == pickedLabel){
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

extension ImageDetailVC: UIPickerViewDelegate, UIPickerViewDataSource {
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
