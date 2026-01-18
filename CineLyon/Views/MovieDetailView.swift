//
//  MovieDetailView.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import SwiftUI

/// Vue détail d'un film avec séances et actions
struct MovieDetailView: View {
    
    let movie: Movie
    
    @EnvironmentObject var dataService: MovieDataService
    @EnvironmentObject var favorites: FavoritesViewModel
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var selectedCinema: String?
    @State private var selectedDate = Date()
    @State private var showAddedToCalendar = false
    @State private var showReminderSheet = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var expandSynopsis = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header avec affiche
                headerSection
                
                // MARK: - Infos du film
                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    metadataSection
                    synopsisSection
                    
                    Divider()
                    
                    // MARK: - Séances
                    showtimesSection
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                favoriteButton
            }
        }
        .alert("CinéLyon", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showReminderSheet) {
            ReminderSheetView(movie: movie, selectedCinema: selectedCinema ?? "")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Affiche en fond
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color(.systemGray5))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle().fill(Color(.systemGray5))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 350)
            .clipped()
            
            // Gradient pour lisibilité
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 350)
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(movie.title)
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                // Note
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(movie.rating)
                        .fontWeight(.semibold)
                }
                
                // Année
                Text(movie.releaseYear)
                    .foregroundColor(.secondary)
                
                // Durée
                Text(movie.duration)
                    .foregroundColor(.secondary)
                
                // Badge re-sortie
                if movie.isReRelease {
                    Text("Re-sortie")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Metadata
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Réalisateur
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.orange)
                Text(movie.director)
            }
            .font(.subheadline)
            
            // Genres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(movie.genreList, id: \.self) { genre in
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                    }
                }
            }
            
            // Envie de voir
            HStack {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(.green)
                Text("\(movie.wantToSee) envies de voir")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Synopsis
    
    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            
            Text(movie.synopsis)
                .font(.body)
                .lineLimit(expandSynopsis ? nil : 3)
                .animation(.easeInOut, value: expandSynopsis)
            
            Button(action: { expandSynopsis.toggle() }) {
                Text(expandSynopsis ? "Voir moins" : "Voir plus")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Showtimes
    
    private var showtimesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Séances")
                .font(.headline)
            
            if movie.showtimes.isEmpty {
                Text("Aucune séance disponible")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(movie.cinemas, id: \.self) { cinema in
                    CinemaShowtimesCard(
                        cinema: cinema,
                        showtimes: movie.showtimes[cinema] ?? [],
                        onShowtimeTap: { showtime in
                            handleShowtimeTap(cinema: cinema, showtime: showtime)
                        },
                        onCalendarTap: { showtime in
                            addToCalendar(cinema: cinema, showtime: showtime)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Favorite Button
    
    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favorites.toggleMovieFavorite(movie)
            }
        }) {
            Image(systemName: favorites.isMovieFavorite(movie) ? "heart.fill" : "heart")
                .foregroundColor(favorites.isMovieFavorite(movie) ? .red : .primary)
                .font(.title3)
        }
    }
    
    // MARK: - Actions
    
    private func handleShowtimeTap(cinema: String, showtime: Showtime) {
        if let url = showtime.ticketingURL, let ticketURL = URL(string: url) {
            UIApplication.shared.open(ticketURL)
        }
    }
    
    private func addToCalendar(cinema: String, showtime: Showtime) {
        Task {
            do {
                _ = try await calendarManager.addToCalendar(
                    movie: movie,
                    cinema: cinema,
                    showtime: showtime,
                    date: selectedDate
                )
                alertMessage = "✅ Séance ajoutée au calendrier !"
                showAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - Cinema Showtimes Card

struct CinemaShowtimesCard: View {
    let cinema: String
    let showtimes: [Showtime]
    let onShowtimeTap: (Showtime) -> Void
    let onCalendarTap: (Showtime) -> Void
    
    @State private var expanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header cinéma
            Button(action: { withAnimation { expanded.toggle() } }) {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.orange)
                    Text(cinema)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            // Liste des séances
            if expanded {
                FlowLayout(spacing: 8) {
                    ForEach(showtimes) { showtime in
                        ShowtimeChip(
                            showtime: showtime,
                            onTap: { onShowtimeTap(showtime) },
                            onCalendarTap: { onCalendarTap(showtime) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Showtime Chip

struct ShowtimeChip: View {
    let showtime: Showtime
    let onTap: () -> Void
    let onCalendarTap: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(showtime.time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack(spacing: 4) {
                        Text(showtime.language)
                            .font(.caption2)
                        if let format = showtime.format {
                            Text(format)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Button(action: onCalendarTap) {
                Image(systemName: "calendar.badge.plus")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Flow Layout (pour grille flexible de séances)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Reminder Sheet

struct ReminderSheetView: View {
    let movie: Movie
    let selectedCinema: String
    
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Choisir un rappel") {
                    ForEach(NotificationManager.ReminderType.allCases, id: \.self) { type in
                        Button(action: {
                            // Logique de rappel
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "bell")
                                Text(type.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rappel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct MovieDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieDetailView(movie: Movie.preview)
        }
        .environmentObject(MovieDataService.shared)
        .environmentObject(FavoritesViewModel())
    }
}
