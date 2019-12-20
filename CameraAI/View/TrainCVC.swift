//
//  TrainCVC.swift
//  CameraAI
//
//  Created by Trong Tran on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import UIKit

class TrainCVC: UICollectionViewCell {
    
    @IBOutlet weak var imgThumbnail: UIImageView!
    
    @IBOutlet weak var lblLabel: UILabel!
    
    func setData(imgData: Data, labelTitle: String) {
        imgThumbnail.image = UIImage(data: imgData)
        lblLabel.text = labelTitle
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
