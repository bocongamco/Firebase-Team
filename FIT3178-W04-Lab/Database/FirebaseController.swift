//
//  FirebaseController.swift
//  FIT3178-W04-Lab
//
//  Created by Phan Thi Quynh on 12/04/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
class FirebaseController: NSObject,DatabaseProtocol {
    
    
    
    let DEFAULT_TEAM_NAME = "Default Team"
    var listeners = MulticastDelegate<DatabaseListener>()
    var heroList: [Superhero]
    var defaultTeam: Team
    
    
    //Firebase Authenticate System.
    var authController: Auth
    var database: Firestore
    var heroesRef: CollectionReference?
    var teamsRef: CollectionReference?
    var currentUser: FirebaseAuth.User?
    
    
    
    override init(){
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        heroList = [Superhero]()
        defaultTeam = Team()
        
        super.init()
        
        Task{
            do{
                let authDataResult = try await authController.signInAnonymously()
                currentUser = authDataResult.user
            }
            catch{
                fatalError("Firebase Authentication failed with Error\(String(describing: error))")
            }
            self.setupHeroListener()
        }
    }
    
    
    
    func cleanup() {
        
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .team || listener.listenerType == .all {
            listener.onTeamChange(change: .update, teamHeroes: defaultTeam.heroes ?? [])
        }
        if listener.listenerType == .heroes || listener.listenerType == .all{
            listener.onAllHeroesChange(change: .update, heroes: heroList)
        }
        
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func addSuperhero(name: String, abilities: String, universe: Universe) -> Superhero {
        let hero = Superhero()
        hero.name = name
        hero.abilities = abilities
        hero.universe = universe.rawValue
        
        do{
            if let heroRef = try heroesRef?.addDocument(from: hero){
                hero.id = heroRef.documentID
            }
        }catch{
            print("Failed to serialize hero")
        }
        return hero
    }
    
    func deleteSuperhero(hero: Superhero) {
        if let heroID = hero.id{
            heroesRef?.document(heroID).delete()
        }
    }
    
    func addTeam(teamName: String) -> Team {
        // We not using codable protocol to serialize the data
        // bc team object in firestore makes use of document references
        let team = Team()
        team.name = teamName
        if let teamRef = teamsRef?.addDocument(data: ["name" : teamName]){
            team.id = teamRef.documentID
        }
        return team
    }
    
    func deleteTeam(team: Team) {
        if let teamID = team.id{
            teamsRef?.document(teamID).delete()
        }
    }
    
    func addHeroToTeam(hero: Superhero, team: Team) -> Bool {
        
        guard let heroId = hero.id,let teamID = team.id, let count = team.heroes?.count, count < 6 else{
            print("Count: \(String(describing: team.heroes?.count))")
            return false
        }
              
               
        if let newHeroRef = heroesRef?.document(heroId){
            teamsRef?.document(teamID).updateData(
                ["heroes" : FieldValue.arrayUnion([newHeroRef])])
        }
        return true
    }
    
    func removeHeroFromTeam(hero: Superhero, team: Team) {
        if ((team.heroes?.contains(hero)) != nil), let teamID = team.id, let heroID = hero.id{
            if let removedHeroRef = heroesRef?.document(heroID){
                teamsRef?.document(teamID).updateData(["heroes": FieldValue.arrayRemove([removedHeroRef])])
            }
        }
    }
    
    //Firebase
    func getHeroById(_ id: String) -> Superhero?{
        print("Id: \(id)")
        for hero in heroList{
            print("HeroId: \(hero.id)")
            if hero.id  == id{
                
                return hero
            }
        }
        return nil
    }
    func setupHeroListener(){
        heroesRef = database.collection("superheroes")
        heroesRef?.addSnapshotListener(){
            (querySnapshot,error) in
            guard let querySnapshot = querySnapshot else{
                print("failed to fetch documents with error: \(String(describing: error))")
                return
            }
            self.parseHeroesSnapshot(snapshot: querySnapshot)
            
            if self.teamsRef == nil{
                self.setupTeamListener()
            }
        }
    }
    func setupTeamListener(){
        teamsRef = database.collection("teams")
        teamsRef?.whereField("name", isEqualTo: DEFAULT_TEAM_NAME).addSnapshotListener{
           (querySnapshot,error) in
            guard let querySnapshot = querySnapshot, let teamSnapshot = querySnapshot.documents.first else{
                print("error fetching teams: \(error!)")
                return
            }
            self.parseTeamSnapShot(snapshot: teamSnapshot)
        }
    }
    func parseHeroesSnapshot(snapshot: QuerySnapshot){
        snapshot.documentChanges.forEach{(change) in
            var parsedHero: Superhero?
            do {
                parsedHero = try change.document.data(as: Superhero.self)
            } catch{
                print("Unable to decode hero. Is the hero Malformed?")
                return
            }
            guard let hero = parsedHero else{
                print("Document doesnt exist")
                //as
                return
            }
            if change.type == .added{
                heroList.insert(hero, at: Int(change.newIndex))
//                let newIndex = Int(change.newIndex)
//                    if newIndex <= heroList.count {
//                        heroList.insert(hero, at: Int(change.newIndex))
//                    }
            }
            if change.type == .modified{
                heroList[Int(change.oldIndex)] = hero
//                let newIndex = Int(change.newIndex)
//                    if newIndex <= heroList.count {
//                        heroList[Int(change.oldIndex)] = hero
//                    }
                
            }
            if change.type == .removed{
                heroList.remove(at: Int(change.oldIndex))
            }
            
            listeners.invoke{ (listeners) in
                if listeners.listenerType == ListenerType.heroes ||
                    listeners.listenerType == ListenerType.all{
                    listeners.onAllHeroesChange(change: .update, heroes: heroList)
                }
                
            }
        }
    }
    func parseTeamSnapShot(snapshot: QueryDocumentSnapshot){
        defaultTeam = Team()
        defaultTeam.name = snapshot.data()["name"] as? String
        defaultTeam.id = snapshot.documentID
        defaultTeam.heroes = []
        if let heroReferences = snapshot.data()["heroes"] as? [DocumentReference]{
            for reference in heroReferences {
                if let hero = getHeroById(reference.documentID){
                    defaultTeam.heroes?.append(hero)
                  
                   
                }
            }
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.team ||
                    listener.listenerType == ListenerType.all {
                    
                    listener.onTeamChange(change: .update, teamHeroes: defaultTeam.heroes ?? [] )
            }
            }
        }
    }
}
