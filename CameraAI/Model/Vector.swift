//
//  Vector.swift
//  CameraAI
//
//  Created by Trong Tran on 12/18/19.
//  Copyright © 2019 Trong Tran. All rights reserved.
//

import Foundation

struct Vector {
    var name: String
    var vector: [Double]
    var distance: Double
}

extension Vector {
    init(name: String, vector: [Double]) {
        self.init(name: name,
                  vector: vector,
                  distance: 0)
    }
}

