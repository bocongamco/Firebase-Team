//
//  Team.swift
//  FIT3178-W04-Lab
//
//  Created by Phan Thi Quynh on 12/04/2023.
//

import UIKit
import FirebaseFirestoreSwift
class Team: NSObject,Codable {
    @DocumentID var id: String?
    var name: String?
    var heroes: [Superhero]?
}
