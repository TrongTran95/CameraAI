//
//  MenuVC.swift
//  CameraAI
//
//  Created by Trong Tran on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit

class MenuVC: UIViewController {
    @IBOutlet weak var tbMenu: UITableView!
    
    let arrImageName: [String] = ["camera", "train", "predict", "stream"]
    let arrTitle: [String] = ["Camera", "Train", "Predict", "Stream"]
    
    var flagStream: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPredictVC" {
            if let predictVC = segue.destination as? PredictVC {
                predictVC.flagStream = self.flagStream
            }
        }
    }
}

extension MenuVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrImageName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as! MenuTVC
        let currentIndex = indexPath.row
        cell.setData(imgName: arrImageName[currentIndex], title: arrTitle[currentIndex])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "showCameraVC", sender: self)
        case 1:
            self.performSegue(withIdentifier: "showTrainVC", sender: self)
        case 2:
            flagStream = false
            self.performSegue(withIdentifier: "showPredictVC", sender: self)
        case 3:
            flagStream = true
            self.performSegue(withIdentifier: "showPredictVC", sender: self)
        default:
            break
        }
    }
}
