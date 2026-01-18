//
//  SettingsView.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import SwiftUI

/// Vue des réglages avec gestion des notifications
struct SettingsView: View {
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @EnvironmentObject var dataService: MovieDataService
    
    @State private var selectedReminderType: NotificationManager.ReminderType = .twoHours
    @State private var showClearCacheAlert = false
    
    var body: some View {
        List {
            // MARK: - Notifications
            notificationsSection
            
            // MARK: - Calendrier
            calendarSection
            
            // MARK: - Données
            dataSection
            
            // MARK: - À propos
            aboutSection
        }
        .navigationTitle("Réglages")
        .alert("Vider le cache", isPresented: $showClearCacheAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Vider", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("Les données seront retéléchargées au prochain lancement.")
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section {
            // Status des notifications
            HStack {
                Label("Notifications", systemImage: "bell.fill")
                Spacer()
                statusBadge(isEnabled: notificationManager.isAuthorized)
            }
            
            // Bouton demander permission
            if !notificationManager.isAuthorized {
                Button(action: requestNotificationPermission) {
                    Label("Activer les notifications", systemImage: "bell.badge")
                }
            }
            
            // Type de rappel par défaut
            if notificationManager.isAuthorized {
                Picker("Rappel par défaut", selection: $selectedReminderType) {
                    ForEach(NotificationManager.ReminderType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notificationManager.isAuthorized {
                Text("Ce rappel sera appliqué par défaut lors de l'ajout d'une séance.")
            } else {
                Text("Activez les notifications pour recevoir des rappels avant vos séances.")
            }
        }
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        Section {
            HStack {
                Label("Calendrier", systemImage: "calendar")
                Spacer()
                statusBadge(isEnabled: calendarManager.isAuthorized)
            }
            
            if !calendarManager.isAuthorized {
                Button(action: requestCalendarPermission) {
                    Label("Autoriser l'accès au calendrier", systemImage: "calendar.badge.plus")
                }
            }
        } header: {
            Text("Calendrier")
        } footer: {
            Text("Permet d'ajouter les séances directement à votre calendrier Apple.")
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            // Dernière mise à jour
            if let lastUpdated = dataService.lastUpdated {
                HStack {
                    Label("Dernière mise à jour", systemImage: "clock")
                    Spacer()
                    Text(lastUpdated, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
            
            // Rafraîchir
            Button(action: refreshData) {
                Label("Rafraîchir les données", systemImage: "arrow.clockwise")
            }
            
            // Vider le cache
            Button(action: { showClearCacheAlert = true }) {
                Label("Vider le cache", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Données")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://cinelyon.vercel.app")!) {
                Label("Site web CinéLyon", systemImage: "globe")
            }
            
            Link(destination: URL(string: "https://github.com/abdu-63/cinelyon")!) {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } header: {
            Text("À propos")
        }
    }
    
    // MARK: - Helpers
    
    private func statusBadge(isEnabled: Bool) -> some View {
        Text(isEnabled ? "Activé" : "Désactivé")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isEnabled ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
            .foregroundColor(isEnabled ? .green : .red)
            .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func requestNotificationPermission() {
        Task {
            _ = await notificationManager.requestAuthorization()
        }
    }
    
    private func requestCalendarPermission() {
        Task {
            _ = await calendarManager.requestAccess()
        }
    }
    
    private func refreshData() {
        Task {
            await dataService.refresh()
        }
    }
    
    private func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("movies_cache.json")
        try? FileManager.default.removeItem(at: cacheURL)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
        .environmentObject(MovieDataService.shared)
    }
}
