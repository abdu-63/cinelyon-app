//
//  MovieDataService.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation
import Combine

/// Service singleton pour récupérer et cacher les données de films
final class MovieDataService: ObservableObject {
    
    static let shared = MovieDataService()
    
    // MARK: - Published Properties
    
    @Published private(set) var schedules: [DaySchedule] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    
    // MARK: - Private Properties
    
    private let apiURL = URL(string: "https://raw.githubusercontent.com/abdu-63/cinelyon/refs/heads/main/movies.json")!
    private let cacheFileName = "movies_cache.json"
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadRevalidatingCacheData
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Charge les films (réseau puis cache si échec)
    @MainActor
    func loadMovies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Essayer le réseau d'abord
            let response = try await fetchFromNetwork()
            schedules = response.days
            lastUpdated = ISO8601DateFormatter().date(from: response.generatedAt) ?? Date()
            
            // Sauvegarder en cache
            try? saveToCache(response)
            
        } catch {
            // Fallback sur le cache local
            if let cached = loadFromCache() {
                schedules = cached.days
                lastUpdated = ISO8601DateFormatter().date(from: cached.generatedAt)
                errorMessage = "Données hors-ligne (dernière mise à jour: \(cached.generatedAt))"
            } else {
                errorMessage = "Impossible de charger les films: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    /// Force le rafraîchissement depuis le réseau
    @MainActor
    func refresh() async {
        await loadMovies()
    }
    
    /// Retourne tous les films uniques (dédupliqués)
    var allMovies: [Movie] {
        var seen = Set<String>()
        return schedules.flatMap { $0.movies }.filter { movie in
            if seen.contains(movie.id) {
                return false
            }
            seen.insert(movie.id)
            return true
        }
    }
    
    /// Retourne les films pour une date donnée
    func movies(for date: Date) -> [Movie] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        return schedules.first(where: { $0.dateString == dateString })?.movies ?? []
    }
    
    /// Retourne les dates avec au moins une séance
    var datesWithShowtimes: Set<String> {
        Set(schedules.filter { !$0.movies.isEmpty }.map { $0.dateString })
    }
    
    /// Recherche de films
    func search(query: String) -> [Movie] {
        guard !query.isEmpty else { return allMovies }
        
        let lowercased = query.lowercased()
        return allMovies.filter { movie in
            movie.title.lowercased().contains(lowercased) ||
            movie.director.lowercased().contains(lowercased) ||
            movie.genres.lowercased().contains(lowercased)
        }
    }
    
    /// Filtres avancés
    func filter(
        genre: String? = nil,
        director: String? = nil,
        minRating: Double? = nil,
        year: String? = nil,
        cinema: String? = nil,
        isReRelease: Bool? = nil
    ) -> [Movie] {
        allMovies.filter { movie in
            // Filtre genre
            if let genre = genre, !movie.genreList.contains(where: { $0.lowercased() == genre.lowercased() }) {
                return false
            }
            
            // Filtre réalisateur
            if let director = director, !movie.director.lowercased().contains(director.lowercased()) {
                return false
            }
            
            // Filtre note minimale
            if let minRating = minRating, movie.ratingValue < minRating {
                return false
            }
            
            // Filtre année
            if let year = year, movie.releaseYear != year {
                return false
            }
            
            // Filtre cinéma
            if let cinema = cinema, !movie.showtimes.keys.contains(where: { $0.lowercased().contains(cinema.lowercased()) }) {
                return false
            }
            
            // Filtre re-sortie
            if let isReRelease = isReRelease, movie.isReRelease != isReRelease {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Network
    
    private func fetchFromNetwork() async throws -> APIResponse {
        let (data, response) = try await session.data(from: apiURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(APIResponse.self, from: data)
    }
    
    // MARK: - Cache
    
    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFileName)
    }
    
    private func saveToCache(_ response: APIResponse) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        try data.write(to: cacheURL, options: .atomic)
    }
    
    private func loadFromCache() -> APIResponse? {
        guard FileManager.default.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }
        
        return try? JSONDecoder().decode(APIResponse.self, from: data)
    }
    
    // MARK: - Errors
    
    enum NetworkError: LocalizedError {
        case invalidResponse
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Réponse serveur invalide"
            case .noData: return "Aucune donnée reçue"
            }
        }
    }
}
