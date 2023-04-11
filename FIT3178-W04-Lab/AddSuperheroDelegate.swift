//
//  DatabaseProtocol.swift
//  FIT3178-W04-Lab
//
//  Created by Jason Haasz on 4/1/2023.
//

import Foundation

protocol AddSuperheroDelegate: AnyObject {
    func addSuperhero(_ newHero: Superhero) -> Bool
}
