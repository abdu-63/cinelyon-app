//
//  CineLyonWidget.swift
//  CineLyonWidget
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible - WidgetKit Extension
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct MovieWidgetEntry: TimelineEntry {
    let date: Date
    let movies: [WidgetMovie]
    let configuration: ConfigurationIntent
}

struct WidgetMovie: Identifiable {
    let id: String
    let title: String
    let posterURL: String
    let rating: String
    let duration: String
}

// MARK: - Configuration Intent (pour sélection du type)

enum WidgetDisplayType: String, CaseIterable {
    case popular = "Populaires"
    case topRated = "Mieux notés"
    case random = "Aléatoire"
}

struct ConfigurationIntent {
    var displayType: WidgetDisplayType = .popular
}

// MARK: - Timeline Provider

struct CineLyonTimelineProvider: TimelineProvider {
    
    typealias Entry = MovieWidgetEntry
    
    // Placeholder pour le design initial
    func placeholder(in context: Context) -> MovieWidgetEntry {
        MovieWidgetEntry(
            date: Date(),
            movies: [
                WidgetMovie(id: "1", title: "Chargement...", posterURL: "", rating: "0.0", duration: "0h"),
                WidgetMovie(id: "2", title: "Chargement...", posterURL: "", rating: "0.0", duration: "0h"),
                WidgetMovie(id: "3", title: "Chargement...", posterURL: "", rating: "0.0", duration: "0h")
            ],
            configuration: ConfigurationIntent()
        )
    }
    
    // Snapshot pour la galerie de widgets
    func getSnapshot(in context: Context, completion: @escaping (MovieWidgetEntry) -> Void) {
        let entry = MovieWidgetEntry(
            date: Date(),
            movies: sampleMovies(),
            configuration: ConfigurationIntent()
        )
        completion(entry)
    }
    
    // Timeline pour les mises à jour
    func getTimeline(in context: Context, completion: @escaping (Timeline<MovieWidgetEntry>) -> Void) {
        Task {
            let movies = await fetchMoviesForWidget()
            let entry = MovieWidgetEntry(
                date: Date(),
                movies: movies,
                configuration: ConfigurationIntent()
            )
            
            // Rafraîchir toutes les 4 heures
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchMoviesForWidget() async -> [WidgetMovie] {
        let apiURL = URL(string: "https://raw.githubusercontent.com/abdu-63/cinelyon/refs/heads/main/movies.json")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let response = try JSONDecoder().decode(WidgetAPIResponse.self, from: data)
            
            // Extraire les films uniques
            var seenIds = Set<String>()
            let allMovies = response.days.flatMap { $0.movies }.filter { movie in
                let id = movie.title + movie.release_year
                if seenIds.contains(id) { return false }
                seenIds.insert(id)
                return true
            }
            
            // Trier par "want to see" (populaires) et prendre les 3 premiers
            let sortedMovies = allMovies.sorted { $0.wantToSee > $1.wantToSee }
            let topMovies = Array(sortedMovies.prefix(3))
            
            return topMovies.map { movie in
                WidgetMovie(
                    id: movie.title + movie.release_year,
                    title: movie.title,
                    posterURL: movie.affiche,
                    rating: movie.rating,
                    duration: movie.duree
                )
            }
        } catch {
            print("Widget fetch error: \(error)")
            return sampleMovies()
        }
    }
    
    private func sampleMovies() -> [WidgetMovie] {
        [
            WidgetMovie(id: "sample1", title: "Avatar 3", posterURL: "", rating: "7.4", duration: "3h 17min"),
            WidgetMovie(id: "sample2", title: "Film 2", posterURL: "", rating: "8.0", duration: "2h"),
            WidgetMovie(id: "sample3", title: "Film 3", posterURL: "", rating: "7.8", duration: "2h 30min")
        ]
    }
}

// MARK: - Widget API Response (simplifié pour le widget)

struct WidgetAPIResponse: Codable {
    let days: [WidgetDay]
}

struct WidgetDay: Codable {
    let date: String
    let movies: [WidgetMovieData]
}

struct WidgetMovieData: Codable {
    let title: String
    let release_year: String
    let duree: String
    let rating: String
    let affiche: String
    let wantToSee: Int
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: MovieWidgetEntry
    
    var body: some View {
        if let movie = entry.movies.first {
            ZStack(alignment: .bottomLeading) {
                // Image de fond
                if let url = URL(string: movie.posterURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                } else {
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                
                // Gradient overlay
                LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                
                // Titre et note
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    
                    Text(movie.title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(movie.rating)
                            .foregroundColor(.white)
                    }
                    .font(.caption2)
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: MovieWidgetEntry
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(entry.movies.prefix(3)) { movie in
                VStack(spacing: 6) {
                    // Affiche
                    if let url = URL(string: movie.posterURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(2/3, contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 80)
                        .cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
                            .frame(height: 80)
                    }
                    
                    // Titre
                    Text(movie.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    // Note
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(movie.rating)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
            }
        }
        .padding()
    }
}

// MARK: - Widget Configuration

@main
struct CineLyonWidget: Widget {
    let kind: String = "CineLyonWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CineLyonTimelineProvider()) { entry in
            CineLyonWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CinéLyon")
        .description("Découvrez les films à l'affiche à Lyon")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View

struct CineLyonWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MovieWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

struct CineLyonWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = MovieWidgetEntry(
            date: Date(),
            movies: [
                WidgetMovie(id: "1", title: "Avatar 3", posterURL: "", rating: "7.4", duration: "3h"),
                WidgetMovie(id: "2", title: "Film 2", posterURL: "8.0", rating: "8.0", duration: "2h"),
                WidgetMovie(id: "3", title: "Film 3", posterURL: "", rating: "7.8", duration: "2h")
            ],
            configuration: ConfigurationIntent()
        )
        
        Group {
            CineLyonWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            CineLyonWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

