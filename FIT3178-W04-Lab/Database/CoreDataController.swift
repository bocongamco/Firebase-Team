//
//  DatabaseProtocol.swift
//  FIT3178-W04-Lab
//
//  Created by Jason Haasz on 4/1/2023.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    let DEFAULT_TEAM_NAME = "Default Team"
    var teamHeroesFetchedResultsController: NSFetchedResultsController<Superhero>?
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var allHeroesFetchedResultsController: NSFetchedResultsController<Superhero>?
    
    // MARK: - Lazy Initilisation of Default Team
    lazy var defaultTeam: Team = {
        var teams = [Team]()
                    
        let request: NSFetchRequest<Team> = Team.fetchRequest()
        let predicate = NSPredicate(format: "name = %@", DEFAULT_TEAM_NAME)
        request.predicate = predicate
                    
        do {
            try teams = persistentContainer.viewContext.fetch(request)
        } catch {
            print("Fetch Request Failed: \(error)")
        }
                    
        if let firstTeam = teams.first {
            return firstTeam
        }
        return addTeam(teamName: DEFAULT_TEAM_NAME)
    }()
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "Week04-DataModel")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error \(error)")
            }
        }
        super.init()
        
        if fetchAllHeroes().count == 0 {
            createDefaultHeroes()
        }
    }
    
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    func addSuperhero(name: String, abilities: String, universe: Universe) -> Superhero {
        let hero = NSEntityDescription.insertNewObject(forEntityName: "Superhero", into: persistentContainer.viewContext) as! Superhero
        hero.name = name
        hero.abilities = abilities
        hero.herouniverse = universe
        
        return hero
    }
    
    func deleteSuperhero(hero: Superhero) {
        persistentContainer.viewContext.delete(hero)
    }
    
    func fetchAllHeroes() -> [Superhero] {
        if allHeroesFetchedResultsController == nil {
            let request: NSFetchRequest<Superhero> = Superhero.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            allHeroesFetchedResultsController = NSFetchedResultsController<Superhero>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            allHeroesFetchedResultsController?.delegate = self
            
            do {
                try allHeroesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let heroes = allHeroesFetchedResultsController?.fetchedObjects {
            return heroes
        }
        return [Superhero]()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allHeroesFetchedResultsController {
            listeners.invoke() { listener in
                if listener.listenerType == .heroes || listener.listenerType == .all{
                    listener.onAllHeroesChange(change: .update, heroes: fetchAllHeroes())
                }
            }
        } else if controller == teamHeroesFetchedResultsController {
            listeners.invoke() { listener in
                if listener.listenerType == .team || listener.listenerType == .all {
                    listener.onTeamChange(change: .update, teamHeroes: fetchTeamHeroes())
                }
            }
        }
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .heroes || listener.listenerType == .all {
            listener.onAllHeroesChange(change: .update, heroes: fetchAllHeroes())
        }
        
        if listener.listenerType == .team || listener.listenerType == .all {
            listener.onTeamChange(change: .update, teamHeroes: fetchTeamHeroes())
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func createDefaultHeroes() {
        let _ = addSuperhero(name: "Bruce Wayne", abilities: "Money", universe: .dc)
        let _ = addSuperhero(name: "Superman", abilities: "Super Powered Alien", universe: .dc)
        let _ = addSuperhero(name: "Wonder Woman", abilities: "Goddess", universe: .dc)
        let _ = addSuperhero(name: "The Flash", abilities: "Speed", universe: .dc)
        let _ = addSuperhero(name: "Green Lantern", abilities: "Power Ring", universe: .dc)
        let _ = addSuperhero(name: "Cyborg", abilities: "Robot Beep Beep", universe: .dc)
        let _ = addSuperhero(name: "Aquaman", abilities: "Atlantian", universe: .dc)
        let _ = addSuperhero(name: "Captain Marvel", abilities: "Superhuman Strength", universe: .marvel)
        let _ = addSuperhero(name: "Spider-Man", abilities: "Spider Sense", universe: .marvel)
        cleanup()
    }
    
    func addTeam(teamName:String) -> Team {
        let team = NSEntityDescription.insertNewObject(forEntityName: "Team", into: persistentContainer.viewContext) as! Team
        team.name = teamName
        
        return team
    }
    
    func deleteTeam(team: Team) {
        persistentContainer.viewContext.delete(team)
    }
    
    func addHeroToTeam(hero: Superhero, team: Team) -> Bool {
        guard let heroes = team.heroes, heroes.contains(hero) == false, heroes.count < 6 else {
            return false
        }
        
        team.addToHeroes(hero)
        return true
    }
    
    func removeHeroFromTeam(hero: Superhero, team: Team) {
        team.removeFromHeroes(hero)
    }
    
    func fetchTeamHeroes() -> [Superhero] {
        if teamHeroesFetchedResultsController == nil {
            let fetchRequest: NSFetchRequest<Superhero> = Superhero.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            let predicate = NSPredicate(format: "ANY teams.name == %@", DEFAULT_TEAM_NAME)
            fetchRequest.sortDescriptors = [nameSortDescriptor]
            fetchRequest.predicate = predicate
                        
            teamHeroesFetchedResultsController =
                NSFetchedResultsController<Superhero>(fetchRequest: fetchRequest,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil, cacheName: nil)

            teamHeroesFetchedResultsController?.delegate = self
                        
            do {
                try teamHeroesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
                    
        var heroes = [Superhero]()
        if teamHeroesFetchedResultsController?.fetchedObjects != nil {
            heroes = (teamHeroesFetchedResultsController?.fetchedObjects)!
        }
                    
        return heroes

    }
}
