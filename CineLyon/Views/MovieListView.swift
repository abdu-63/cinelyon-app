//
//  MovieListView.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import SwiftUI

/// Vue liste des films avec filtres
struct MovieListView: View {
    
    @EnvironmentObject var dataService: MovieDataService
    @EnvironmentObject var favorites: FavoritesViewModel
    
    @State private var searchText = ""
    @State private var selectedGenre: String?
    @State private var showFilters = false
    @State private var filterOnlyReReleases = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // MARK: - Filtres rapides
                filterChipsSection
                
                // MARK: - Liste des films
                if dataService.isLoading {
                    loadingView
                } else if filteredMovies.isEmpty {
                    emptyStateView
                } else {
                    moviesGridSection
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("CinéLyon")
        .searchable(text: $searchText, prompt: "Rechercher un film...")
        .refreshable {
            await dataService.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilters.toggle() }) {
                    Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheetView(
                selectedGenre: $selectedGenre,
                filterOnlyReReleases: $filterOnlyReReleases,
                genres: availableGenres
            )
        }
    }
    
    // MARK: - Subviews
    
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Chip Re-sorties
                FilterChip(
                    title: "Re-sorties",
                    isSelected: filterOnlyReReleases
                ) {
                    filterOnlyReReleases.toggle()
                }
                
                // Chips genres populaires
                ForEach(topGenres, id: \.self) { genre in
                    FilterChip(
                        title: genre,
                        isSelected: selectedGenre == genre
                    ) {
                        selectedGenre = selectedGenre == genre ? nil : genre
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var moviesGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            ForEach(filteredMovies) { movie in
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    MovieCardView(movie: movie)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Chargement des films...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Aucun film trouvé")
                .font(.headline)
            Text("Essayez de modifier vos filtres")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Data
    
    private var filteredMovies: [Movie] {
        var movies = dataService.allMovies
        
        // Filtre recherche
        if !searchText.isEmpty {
            movies = dataService.search(query: searchText)
        }
        
        // Filtre genre
        if let genre = selectedGenre {
            movies = movies.filter { $0.genreList.contains(where: { $0.lowercased() == genre.lowercased() }) }
        }
        
        // Filtre re-sorties
        if filterOnlyReReleases {
            movies = movies.filter { $0.isReRelease }
        }
        
        return movies
    }
    
    private var availableGenres: [String] {
        let allGenres = dataService.allMovies.flatMap { $0.genreList }
        return Array(Set(allGenres)).sorted()
    }
    
    private var topGenres: [String] {
        Array(availableGenres.prefix(5))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Movie Card

struct MovieCardView: View {
    let movie: Movie
    @EnvironmentObject var favorites: FavoritesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Affiche
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "film")
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .aspectRatio(2/3, contentMode: .fit)
            .cornerRadius(12)
            .overlay(
                // Badge favori
                Group {
                    if favorites.isMovieFavorite(movie) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .padding(8)
                    }
                },
                alignment: .topTrailing
            )
            .overlay(
                // Badge note
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(movie.rating)
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(8),
                alignment: .bottomLeading
            )
            
            // Titre
            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Genre
            Text(movie.genreList.prefix(2).joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Binding var selectedGenre: String?
    @Binding var filterOnlyReReleases: Bool
    let genres: [String]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Options") {
                    Toggle("Uniquement les re-sorties", isOn: $filterOnlyReReleases)
                }
                
                Section("Genres") {
                    ForEach(genres, id: \.self) { genre in
                        Button(action: {
                            selectedGenre = selectedGenre == genre ? nil : genre
                        }) {
                            HStack {
                                Text(genre)
                                Spacer()
                                if selectedGenre == genre {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section {
                    Button("Réinitialiser les filtres") {
                        selectedGenre = nil
                        filterOnlyReReleases = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieListView()
        }
        .environmentObject(MovieDataService.shared)
        .environmentObject(FavoritesViewModel())
    }
}
