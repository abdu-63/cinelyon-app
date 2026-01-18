//
//  CineLyonApp.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import SwiftUI

@main
struct CineLyonApp: App {
    
    // MARK: - State Objects
    
    @StateObject private var dataService = MovieDataService.shared
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    
    // MARK: - Core Data
    
    let coreDataStack = CoreDataStack.shared
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataService)
                .environmentObject(favoritesViewModel)
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .task {
                    await dataService.loadMovies()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    coreDataStack.save()
                }
        }
    }
}
