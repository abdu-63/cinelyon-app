//
//  MainTabView.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible (NavigationView, pas NavigationStack)
//

import SwiftUI

/// Vue principale avec TabBar de navigation
struct MainTabView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Onglet Accueil
            NavigationView {
                MovieListView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Films", systemImage: "film")
            }
            .tag(0)
            
            // MARK: - Onglet Favoris
            NavigationView {
                FavoritesView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Favoris", systemImage: "heart.fill")
            }
            .tag(1)
            
            // MARK: - Onglet Calendrier
            NavigationView {
                CalendarView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Calendrier", systemImage: "calendar")
            }
            .tag(2)
            
            // MARK: - Onglet Réglages
            NavigationView {
                SettingsView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Réglages", systemImage: "gear")
            }
            .tag(3)
        }
        .accentColor(.orange)
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(MovieDataService.shared)
            .environmentObject(FavoritesViewModel())
    }
}
