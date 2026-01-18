//
//  Showtime.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation

/// Représente une séance de cinéma
struct Showtime: Identifiable, Codable, Hashable {
    var id: String { "\(time)-\(language)-\(format ?? "standard")" }
    
    let time: String
    let language: String  // "VO" ou "VF"
    let format: String?   // "3D", "IMAX", "4DX", etc.
    let ticketingURL: String?
    
    // Clés JSON personnalisées
    enum CodingKeys: String, CodingKey {
        case time
        case language = "lang"
        case format
        case ticketingURL = "ticketing_url"
    }
    
    /// Séance formatée pour l'affichage (ex: "20:30 - VF 3D")
    var displayText: String {
        var text = "\(time) - \(language)"
        if let format = format, !format.isEmpty {
            text += " \(format)"
        }
        return text
    }
    
    /// Parse l'heure de la séance en Date (pour le jour donné)
    func dateTime(for date: Date) -> Date? {
        let components = time.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return calendar.date(from: dateComponents)
    }
}
