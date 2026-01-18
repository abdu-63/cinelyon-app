//
//  DaySchedule.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation

/// Représente les films et séances d'une journée
struct DaySchedule: Identifiable, Codable {
    var id: String { dateString }
    
    let dateString: String
    let movies: [Movie]
    
    enum CodingKeys: String, CodingKey {
        case dateString = "date"
        case movies
    }
    
    /// Date parsée depuis la chaîne ISO8601
    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        return formatter.date(from: dateString) ?? Date()
    }
    
    /// Date formatée pour l'affichage (ex: "Vendredi 17 janvier")
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }
    
    /// Vérifie si c'est aujourd'hui
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Vérifie si c'est demain
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }
}

/// Structure racine du JSON
struct APIResponse: Codable {
    let generatedAt: String
    let days: [DaySchedule]
    
    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case days
    }
}
