//
//  FavoritesViewModel.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation
import CoreData
import Combine

/// ViewModel pour gérer les favoris (Films, Cinémas, Séances)
final class FavoritesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var favoriteMovieIds: Set<String> = []
    @Published private(set) var favoriteCinemaNames: Set<String> = []
    @Published private(set) var upcomingShowtimes: [FavoriteShowtime] = []
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        loadFavorites()
        
        // Observer les changements CoreData
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadFavorites()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load
    
    private func loadFavorites() {
        // Charger les films favoris
        let movies = FavoriteMovie.fetchAll(context: context)
        favoriteMovieIds = Set(movies.compactMap { $0.movieId })
        
        // Charger les cinémas favoris
        let cinemas = FavoriteCinema.fetchAll(context: context)
        favoriteCinemaNames = Set(cinemas.compactMap { $0.name })
        
        // Charger les séances à venir
        upcomingShowtimes = FavoriteShowtime.fetchUpcoming(context: context)
    }
    
    // MARK: - Movies
    
    /// Vérifie si un film est en favoris
    func isMovieFavorite(_ movie: Movie) -> Bool {
        favoriteMovieIds.contains(movie.id)
    }
    
    /// Ajoute ou supprime un film des favoris
    func toggleMovieFavorite(_ movie: Movie) {
        if isMovieFavorite(movie) {
            removeMovie(movie)
        } else {
            addMovie(movie)
        }
    }
    
    private func addMovie(_ movie: Movie) {
        _ = FavoriteMovie.createOrUpdate(
            movieId: movie.id,
            title: movie.title,
            posterURL: movie.posterURL,
            context: context
        )
        CoreDataStack.shared.save()
        favoriteMovieIds.insert(movie.id)
    }
    
    private func removeMovie(_ movie: Movie) {
        FavoriteMovie.delete(movieId: movie.id, context: context)
        CoreDataStack.shared.save()
        favoriteMovieIds.remove(movie.id)
    }
    
    /// Récupère les films favoris depuis la liste complète
    func getFavoriteMovies(from allMovies: [Movie]) -> [Movie] {
        allMovies.filter { favoriteMovieIds.contains($0.id) }
    }
    
    // MARK: - Cinemas
    
    /// Vérifie si un cinéma est en favoris
    func isCinemaFavorite(_ name: String) -> Bool {
        favoriteCinemaNames.contains(name)
    }
    
    /// Ajoute ou supprime un cinéma des favoris
    func toggleCinemaFavorite(_ name: String) {
        if isCinemaFavorite(name) {
            removeCinema(name)
        } else {
            addCinema(name)
        }
    }
    
    private func addCinema(_ name: String) {
        _ = FavoriteCinema.createOrUpdate(name: name, context: context)
        CoreDataStack.shared.save()
        favoriteCinemaNames.insert(name)
    }
    
    private func removeCinema(_ name: String) {
        FavoriteCinema.delete(name: name, context: context)
        CoreDataStack.shared.save()
        favoriteCinemaNames.remove(name)
    }
    
    // MARK: - Showtimes
    
    /// Ajoute une séance favorite avec rappel
    func addShowtimeReminder(
        movie: Movie,
        cinema: String,
        showtime: Showtime,
        date: Date,
        reminderDate: Date?
    ) {
        guard let showtimeDate = showtime.dateTime(for: date) else { return }
        
        _ = FavoriteShowtime.create(
            movieId: movie.id,
            movieTitle: movie.title,
            cinema: cinema,
            showtimeDate: showtimeDate,
            reminderDate: reminderDate,
            context: context
        )
        CoreDataStack.shared.save()
        loadFavorites()
    }
    
    /// Supprime une séance favorite
    func removeShowtimeReminder(_ showtime: FavoriteShowtime) {
        guard let id = showtime.id else { return }
        FavoriteShowtime.delete(id: id, context: context)
        CoreDataStack.shared.save()
        loadFavorites()
    }
}
