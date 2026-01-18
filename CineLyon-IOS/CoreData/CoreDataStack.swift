//
//  CoreDataStack.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation
import CoreData

/// Gestionnaire CoreData pour iOS 15
final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CineLyonModel")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // En production, gérer l'erreur proprement
                fatalError("CoreData failed to load: \(error), \(error.userInfo)")
            }
        }
        
        // Configuration pour performances
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /// Contexte principal pour les opérations UI
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// Contexte background pour les opérations lourdes
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save
    
    /// Sauvegarde le contexte principal
    func save() {
        let context = viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            // Log l'erreur mais ne crash pas
            print("CoreData save error: \(error)")
        }
    }
    
    /// Sauvegarde un contexte donné
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
    
    // MARK: - Private
    
    private init() {}
}

// MARK: - FavoriteMovie Entity Extension

extension FavoriteMovie {
    
    /// Crée ou met à jour un favori film
    static func createOrUpdate(
        movieId: String,
        title: String,
        posterURL: String,
        context: NSManagedObjectContext
    ) -> FavoriteMovie {
        let request: NSFetchRequest<FavoriteMovie> = FavoriteMovie.fetchRequest()
        request.predicate = NSPredicate(format: "movieId == %@", movieId)
        
        if let existing = try? context.fetch(request).first {
            return existing
        }
        
        let favorite = FavoriteMovie(context: context)
        favorite.movieId = movieId
        favorite.title = title
        favorite.posterURL = posterURL
        favorite.addedAt = Date()
        
        return favorite
    }
    
    /// Supprime un favori par ID
    static func delete(movieId: String, context: NSManagedObjectContext) {
        let request: NSFetchRequest<FavoriteMovie> = FavoriteMovie.fetchRequest()
        request.predicate = NSPredicate(format: "movieId == %@", movieId)
        
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        }
    }
    
    /// Vérifie si un film est en favoris
    static func isFavorite(movieId: String, context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<FavoriteMovie> = FavoriteMovie.fetchRequest()
        request.predicate = NSPredicate(format: "movieId == %@", movieId)
        request.fetchLimit = 1
        
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    /// Récupère tous les favoris triés par date d'ajout
    static func fetchAll(context: NSManagedObjectContext) -> [FavoriteMovie] {
        let request: NSFetchRequest<FavoriteMovie> = FavoriteMovie.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteMovie.addedAt, ascending: false)]
        
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - FavoriteCinema Entity Extension

extension FavoriteCinema {
    
    /// Crée ou met à jour un favori cinéma
    static func createOrUpdate(
        name: String,
        context: NSManagedObjectContext
    ) -> FavoriteCinema {
        let request: NSFetchRequest<FavoriteCinema> = FavoriteCinema.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        if let existing = try? context.fetch(request).first {
            return existing
        }
        
        let favorite = FavoriteCinema(context: context)
        favorite.name = name
        favorite.addedAt = Date()
        
        return favorite
    }
    
    /// Supprime un favori cinéma
    static func delete(name: String, context: NSManagedObjectContext) {
        let request: NSFetchRequest<FavoriteCinema> = FavoriteCinema.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        }
    }
    
    /// Vérifie si un cinéma est en favoris
    static func isFavorite(name: String, context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<FavoriteCinema> = FavoriteCinema.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    /// Récupère tous les cinémas favoris
    static func fetchAll(context: NSManagedObjectContext) -> [FavoriteCinema] {
        let request: NSFetchRequest<FavoriteCinema> = FavoriteCinema.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteCinema.addedAt, ascending: false)]
        
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - FavoriteShowtime Entity Extension

extension FavoriteShowtime {
    
    /// Crée un rappel de séance
    static func create(
        movieId: String,
        movieTitle: String,
        cinema: String,
        showtimeDate: Date,
        reminderDate: Date?,
        context: NSManagedObjectContext
    ) -> FavoriteShowtime {
        let favorite = FavoriteShowtime(context: context)
        favorite.id = UUID()
        favorite.movieId = movieId
        favorite.movieTitle = movieTitle
        favorite.cinema = cinema
        favorite.showtimeDate = showtimeDate
        favorite.reminderDate = reminderDate
        favorite.addedAt = Date()
        
        return favorite
    }
    
    /// Supprime une séance favorite par ID
    static func delete(id: UUID, context: NSManagedObjectContext) {
        let request: NSFetchRequest<FavoriteShowtime> = FavoriteShowtime.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        }
    }
    
    /// Récupère les séances à venir
    static func fetchUpcoming(context: NSManagedObjectContext) -> [FavoriteShowtime] {
        let request: NSFetchRequest<FavoriteShowtime> = FavoriteShowtime.fetchRequest()
        request.predicate = NSPredicate(format: "showtimeDate >= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteShowtime.showtimeDate, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
}
