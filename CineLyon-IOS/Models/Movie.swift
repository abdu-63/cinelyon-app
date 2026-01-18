//
//  Movie.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation

/// Représente un film avec ses séances
struct Movie: Identifiable, Codable, Hashable {
    var id: String { title + releaseYear }
    
    let title: String
    let releaseYear: String
    let duration: String
    let rating: String
    let genres: String
    let director: String
    let synopsis: String
    let posterURL: String
    let wantToSee: Int
    let letterboxdURL: String
    
    /// Séances groupées par cinéma
    let showtimes: [String: [Showtime]]
    
    // Clés JSON personnalisées
    enum CodingKeys: String, CodingKey {
        case title
        case releaseYear = "release_year"
        case duration = "duree"
        case rating
        case genres
        case director = "realisateur"
        case synopsis
        case posterURL = "affiche"
        case wantToSee
        case letterboxdURL = "url"
        case showtimes = "seances"
    }
    
    // MARK: - Computed Properties
    
    /// Liste des genres sous forme de tableau
    var genreList: [String] {
        genres.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    /// Note numérique (pour le tri)
    var ratingValue: Double {
        Double(rating) ?? 0.0
    }
    
    /// Durée en minutes (pour le filtrage)
    var durationMinutes: Int {
        let components = duration.replacingOccurrences(of: "min", with: "")
            .replacingOccurrences(of: "h", with: " ")
            .split(separator: " ")
        
        var minutes = 0
        if components.count >= 1, let hours = Int(components[0]) {
            minutes += hours * 60
        }
        if components.count >= 2, let mins = Int(components[1]) {
            minutes += mins
        }
        return minutes
    }
    
    /// Liste des cinémas où le film est projeté
    var cinemas: [String] {
        Array(showtimes.keys).sorted()
    }
    
    /// Nombre total de séances
    var totalShowtimes: Int {
        showtimes.values.reduce(0) { $0 + $1.count }
    }
    
    /// Vérifie si c'est une re-sortie (film ancien avec séance récente)
    var isReRelease: Bool {
        guard let year = Int(releaseYear) else { return false }
        let currentYear = Calendar.current.component(.year, from: Date())
        return (currentYear - year) >= 5
    }
    
    // MARK: - Hashable
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Helpers

extension Movie {
    static let preview = Movie(
        title: "Avatar : de Feu et de Cendres",
        releaseYear: "2025",
        duration: "3h 17min",
        rating: "7.4",
        genres: "Science Fiction, Aventure, Action, Fantastique",
        director: "James Cameron",
        synopsis: "Après la mort de Neteyam, Jake et Neytiri affrontent leur chagrin...",
        posterURL: "https://fr.web.img6.acsta.net/img/52/fb/52fb8f0345af2b0940557aa049ca19fd.jpg",
        wantToSee: 9322,
        letterboxdURL: "https://letterboxd.com/search/Avatar/",
        showtimes: [
            "Pathé Bellecour": [
                Showtime(time: "20:35", language: "VO", format: "3D", ticketingURL: nil)
            ],
            "UGC Part-Dieu": [
                Showtime(time: "11:00", language: "VO", format: nil, ticketingURL: nil),
                Showtime(time: "15:15", language: "VF", format: "3D", ticketingURL: nil)
            ]
        ]
    )
}
