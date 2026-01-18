//
//  Cinema.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation

/// Représente un cinéma avec ses informations
struct Cinema: Identifiable, Hashable {
    var id: String { name }
    
    let name: String
    
    /// Coordonnées GPS des cinémas lyonnais
    var coordinates: (latitude: Double, longitude: Double)? {
        Cinema.knownCinemas[name]
    }
    
    /// URL Google Maps
    var mapsURL: URL? {
        guard let coords = coordinates else { return nil }
        return URL(string: "https://maps.apple.com/?q=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)&ll=\(coords.latitude),\(coords.longitude)")
    }
    
    // MARK: - Base de données des cinémas connus
    
    static let knownCinemas: [String: (latitude: Double, longitude: Double)] = [
        "Pathé Bellecour": (45.7578, 4.8320),
        "Pathé Carré de Soie": (45.7644, 4.9206),
        "Pathé Vaise": (45.7780, 4.8050),
        "UGC Part-Dieu": (45.7610, 4.8574),
        "UGC Confluence": (45.7430, 4.8180),
        "UGC Internationale": (45.7650, 4.8530),
        "UGC Astoria": (45.7640, 4.8350),
        "CGR Brignais": (45.6730, 4.7540),
        "Ciné Meyzieu": (45.7670, 5.0030),
        "Institut Lumière": (45.7450, 4.8710),
        "Comoedia": (45.7560, 4.8460),
        "Le Zola": (45.7667, 4.8856),
        "Cinéma Opéra": (45.7676, 4.8540),
        "CNP Terreaux": (45.7673, 4.8335),
        "CNP Bellecour": (45.7578, 4.8310)
    ]
    
    /// Tous les cinémas connus
    static var allCinemas: [Cinema] {
        knownCinemas.keys.sorted().map { Cinema(name: $0) }
    }
    
    /// Recherche un cinéma par nom (recherche partielle)
    static func find(matching query: String) -> [Cinema] {
        let lowercased = query.lowercased()
        return allCinemas.filter { $0.name.lowercased().contains(lowercased) }
    }
}
