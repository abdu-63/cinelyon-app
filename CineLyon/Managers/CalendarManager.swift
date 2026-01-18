//
//  CalendarManager.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation
import Combine
import EventKit

/// Gestionnaire pour ajouter des séances au calendrier Apple
final class CalendarManager: ObservableObject {
    
    static let shared = CalendarManager()
    
    // MARK: - Properties
    
    private let eventStore = EKEventStore()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    
    private init() {
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Demande l'autorisation d'accès au calendrier
    func requestAccess() async -> Bool {
        // iOS 17+ utilise requestFullAccessToEvents, mais pour iOS 15.1 on utilise l'ancienne API
        do {
            let granted = try await eventStore.requestAccess(to: .event)
            await MainActor.run {
                self.isAuthorized = granted
                self.updateAuthorizationStatus()
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    /// Met à jour le statut d'autorisation
    private func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = authorizationStatus == .authorized
    }
    
    // MARK: - Event Creation
    
    /// Ajoute une séance au calendrier
    /// - Parameters:
    ///   - movie: Film concerné
    ///   - cinema: Nom du cinéma
    ///   - showtime: Séance à ajouter
    ///   - date: Date de la séance
    /// - Returns: L'identifiant de l'événement créé
    func addToCalendar(
        movie: Movie,
        cinema: String,
        showtime: Showtime,
        date: Date
    ) async throws -> String {
        // Vérifier l'autorisation
        guard isAuthorized else {
            let granted = await requestAccess()
            guard granted else {
                throw CalendarError.notAuthorized
            }
        }
        
        // Parser l'heure de la séance
        guard let startDate = showtime.dateTime(for: date) else {
            throw CalendarError.invalidDate
        }
        
        // Calculer la durée approximative
        let endDate = startDate.addingTimeInterval(TimeInterval(movie.durationMinutes * 60))
        
        // Créer l'événement
        let event = EKEvent(eventStore: eventStore)
        event.title = "🎬 \(movie.title)"
        event.location = cinema
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Notes avec détails
        var notes = "Film: \(movie.title)\n"
        notes += "Réalisateur: \(movie.director)\n"
        notes += "Durée: \(movie.duration)\n"
        notes += "Format: \(showtime.language)"
        if let format = showtime.format {
            notes += " \(format)"
        }
        if let url = showtime.ticketingURL {
            notes += "\n\nRéserver: \(url)"
        }
        event.notes = notes
        
        // URL vers Letterboxd
        if let letterboxdURL = URL(string: movie.letterboxdURL) {
            event.url = letterboxdURL
        }
        
        // Alarme 2h avant
        event.addAlarm(EKAlarm(relativeOffset: -2 * 60 * 60))
        
        // Sauvegarder
        try eventStore.save(event, span: .thisEvent)
        
        return event.eventIdentifier
    }
    
    /// Supprime un événement par son identifiant
    func removeFromCalendar(eventId: String) throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }
        
        try eventStore.remove(event, span: .thisEvent)
    }
    
    /// Vérifie si un événement existe
    func eventExists(eventId: String) -> Bool {
        eventStore.event(withIdentifier: eventId) != nil
    }
    
    // MARK: - Errors
    
    enum CalendarError: LocalizedError {
        case notAuthorized
        case invalidDate
        case eventNotFound
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized: 
                return "Accès au calendrier non autorisé. Activez-le dans Réglages > CinéLyon."
            case .invalidDate: 
                return "Date de séance invalide."
            case .eventNotFound: 
                return "Événement non trouvé dans le calendrier."
            case .saveFailed: 
                return "Impossible de sauvegarder l'événement."
            }
        }
    }
}
