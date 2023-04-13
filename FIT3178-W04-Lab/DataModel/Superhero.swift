//
//  Superhero.swift
//  FIT3178-W04-Lab
//
//  Created by Phan Thi Quynh on 11/04/2023.
//

import UIKit

import FirebaseFirestoreSwift


class Superhero: NSObject,Codable {
    @DocumentID var id: String?
    var name: String?
    var abilities: String?
    var universe: Int?
    
    
    
    
}

enum Universe: Int {
    case marvel = 0
    case dc = 1
}

extension Superhero{
    var herouniverse: Universe {
        get{
            return Universe(rawValue: self.universe!)!
        }
        set{
            self.universe = newValue.rawValue
        }
        
    }
}

enum CodingKeys: String, CodingKey{
    case id
    case name
    case abilities
    case universe
}
