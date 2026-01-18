//
//  CalendarView.swift
//  CineLyon
//
//  Created for CinéLyon iOS App
//  iOS 15.1+ Compatible
//

import SwiftUI

/// Vue calendrier style Notion avec grille mensuelle
struct CalendarView: View {
    
    @EnvironmentObject var dataService: MovieDataService
    
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var showDaySheet = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header mois
            monthHeader
            
            // MARK: - Jours de la semaine
            weekdayHeader
            
            // MARK: - Grille du calendrier
            calendarGrid
            
            Spacer()
        }
        .navigationTitle("Calendrier")
        .sheet(isPresented: $showDaySheet) {
            DayMoviesSheet(date: selectedDate)
        }
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
        }
        .padding()
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth).capitalized
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasShowtimes: hasShowtimes(for: date)
                    ) {
                        selectedDate = date
                        showDaySheet = true
                    }
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        // Ajuster pour commencer le lundi
        var startDate = monthFirstWeek.start
        let weekday = calendar.component(.weekday, from: startDate)
        if weekday == 1 { // Dimanche
            startDate = calendar.date(byAdding: .day, value: -6, to: startDate)!
        } else if weekday > 2 {
            startDate = calendar.date(byAdding: .day, value: 2 - weekday, to: startDate)!
        }
        
        var days: [Date?] = []
        var currentDate = startDate
        
        // 6 semaines maximum
        for _ in 0..<42 {
            if calendar.isDate(currentDate, equalTo: displayedMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private func hasShowtimes(for date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return dataService.datesWithShowtimes.contains(dateString)
    }
    
    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }
    
    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasShowtimes: Bool
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                // Indicateur de séances
                if hasShowtimes {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 44, height: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .orange }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isSelected { return .orange }
        if isToday { return Color.orange.opacity(0.15) }
        return .clear
    }
}

// MARK: - Day Movies Sheet

struct DayMoviesSheet: View {
    let date: Date
    
    @EnvironmentObject var dataService: MovieDataService
    @Environment(\.dismiss) var dismiss
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }
    
    private var movies: [Movie] {
        dataService.movies(for: date)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if movies.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Aucune séance ce jour")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: MovieDetailView(movie: movie)) {
                                    DayMovieRow(movie: movie)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Day Movie Row

struct DayMovieRow: View {
    let movie: Movie
    
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
            .frame(width: 60, height: 90)
            .cornerRadius(8)
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(movie.director)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(movie.rating)
                    }
                    Text(movie.duration)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                
                // Nombre de séances
                Text("\(movie.totalShowtimes) séances")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CalendarView()
        }
        .environmentObject(MovieDataService.shared)
    }
}
