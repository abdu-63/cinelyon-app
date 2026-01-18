//
//  NotificationManager.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import Foundation
import Combine
import UserNotifications

/// Gestionnaire des notifications locales pour les rappels de séances
final class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    // MARK: - Properties
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Demande l'autorisation pour les notifications
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            await updateAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Met à jour le statut d'autorisation
    @MainActor
    private func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = authorizationStatus == .authorized
    }
    
    // MARK: - Scheduling
    
    /// Types de rappels disponibles
    enum ReminderType: String, CaseIterable {
        case oneDay = "1 jour avant"
        case twoHours = "2 heures avant"
        
        var timeInterval: TimeInterval {
            switch self {
            case .oneDay: return -24 * 60 * 60
            case .twoHours: return -2 * 60 * 60
            }
        }
    }
    
    /// Programme un rappel pour une séance
    /// - Parameters:
    ///   - movie: Film concerné
    ///   - cinema: Nom du cinéma
    ///   - showtime: Séance
    ///   - date: Date de la séance
    ///   - reminderType: Type de rappel
    /// - Returns: L'identifiant de la notification
    func scheduleReminder(
        movie: Movie,
        cinema: String,
        showtime: Showtime,
        date: Date,
        reminderType: ReminderType
    ) async throws -> String {
        // Vérifier l'autorisation
        guard isAuthorized else {
            let granted = await requestAuthorization()
            guard granted else {
                throw NotificationError.notAuthorized
            }
        }
        
        // Parser l'heure de la séance
        guard let showtimeDate = showtime.dateTime(for: date) else {
            throw NotificationError.invalidDate
        }
        
        // Calculer la date du rappel
        let reminderDate = showtimeDate.addingTimeInterval(reminderType.timeInterval)
        
        // Vérifier que le rappel est dans le futur
        guard reminderDate > Date() else {
            throw NotificationError.pastDate
        }
        
        // Créer le contenu
        let content = UNMutableNotificationContent()
        content.title = "🎬 Rappel : \(movie.title)"
        content.body = "\(reminderType.rawValue) • \(showtime.time) à \(cinema)"
        content.sound = .default
        content.categoryIdentifier = "SHOWTIME_REMINDER"
        
        // Données associées
        content.userInfo = [
            "movieId": movie.id,
            "movieTitle": movie.title,
            "cinema": cinema,
            "showtimeDate": showtimeDate.timeIntervalSince1970
        ]
        
        // Créer le trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Identifiant unique
        let identifier = "\(movie.id)-\(cinema)-\(showtime.time)-\(reminderType.rawValue)"
            .replacingOccurrences(of: " ", with: "_")
        
        // Créer la requête
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        return identifier
    }
    
    /// Annule un rappel programmé
    func cancelReminder(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Annule tous les rappels pour un film
    func cancelAllReminders(forMovieId movieId: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let identifiersToRemove = pending
            .filter { $0.identifier.hasPrefix(movieId) }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
    }
    
    /// Récupère les rappels programmés
    func getPendingReminders() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    /// Vérifie si un rappel existe
    func reminderExists(identifier: String) async -> Bool {
        let pending = await notificationCenter.pendingNotificationRequests()
        return pending.contains { $0.identifier == identifier }
    }
    
    // MARK: - Badge Management
    
    /// Réinitialise le badge
    @MainActor
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Badge clear error: \(error)")
            }
        }
    }
    
    // MARK: - Errors
    
    enum NotificationError: LocalizedError {
        case notAuthorized
        case invalidDate
        case pastDate
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized: 
                return "Notifications non autorisées. Activez-les dans Réglages > CinéLyon."
            case .invalidDate: 
                return "Date de séance invalide."
            case .pastDate: 
                return "Impossible de programmer un rappel pour une date passée."
            }
        }
    }
}
