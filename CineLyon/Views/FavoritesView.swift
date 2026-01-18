//
//  FavoritesView.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import SwiftUI

/// Vue des favoris avec segmentation Films / Cinémas
struct FavoritesView: View {
    
    @EnvironmentObject var dataService: MovieDataService
    @EnvironmentObject var favorites: FavoritesViewModel
    
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Segment Control
            Picker("Favoris", selection: $selectedSegment) {
                Text("Films").tag(0)
                Text("Cinémas").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // MARK: - Content
            if selectedSegment == 0 {
                favoriteMoviesSection
            } else {
                favoriteCinemasSection
            }
        }
        .navigationTitle("Favoris")
    }
    
    // MARK: - Favorite Movies
    
    private var favoriteMoviesSection: some View {
        Group {
            let movies = favorites.getFavoriteMovies(from: dataService.allMovies)
            
            if movies.isEmpty {
                emptyStateView(
                    icon: "heart",
                    title: "Aucun film favori",
                    subtitle: "Appuyez sur ❤️ pour ajouter des films"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                FavoriteMovieRow(movie: movie)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Favorite Cinemas
    
    private var favoriteCinemasSection: some View {
        Group {
            let cinemas = Array(favorites.favoriteCinemaNames).sorted()
            
            if cinemas.isEmpty {
                emptyStateView(
                    icon: "building.2",
                    title: "Aucun cinéma favori",
                    subtitle: "Ajoutez des cinémas depuis les détails d'un film"
                )
            } else {
                List {
                    ForEach(cinemas, id: \.self) { cinema in
                        FavoriteCinemaRow(cinemaName: cinema)
                    }
                    .onDelete(perform: deleteCinema)
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty State
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Actions
    
    private func deleteCinema(at offsets: IndexSet) {
        let cinemas = Array(favorites.favoriteCinemaNames).sorted()
        for index in offsets {
            favorites.toggleCinemaFavorite(cinemas[index])
        }
    }
}

// MARK: - Favorite Movie Row

struct FavoriteMovieRow: View {
    let movie: Movie
    @EnvironmentObject var favorites: FavoritesViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Affiche
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
            }
            .frame(width: 70, height: 105)
            .cornerRadius(8)
            
            // Infos
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(movie.director)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(movie.rating)
                    }
                    
                    Text(movie.duration)
                        .foregroundColor(.secondary)
                    
                    Text(movie.releaseYear)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                
                // Genres
                Text(movie.genreList.prefix(2).joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            // Bouton supprimer
            Button(action: {
                withAnimation {
                    favorites.toggleMovieFavorite(movie)
                }
            }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Favorite Cinema Row

struct FavoriteCinemaRow: View {
    let cinemaName: String
    @EnvironmentObject var favorites: FavoritesViewModel
    
    private var cinema: Cinema {
        Cinema(name: cinemaName)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cinemaName)
                    .font(.headline)
                
                if cinema.coordinates != nil {
                    Button(action: openMaps) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                            Text("Voir sur la carte")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                favorites.toggleCinemaFavorite(cinemaName)
            }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func openMaps() {
        if let url = cinema.mapsURL {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritesView()
        }
        .environmentObject(MovieDataService.shared)
        .environmentObject(FavoritesViewModel())
    }
}
