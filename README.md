# CinéLyon iOS App

Application iOS officielle pour CinéLyon - Catalogue de films et séances de cinéma à Lyon.

## Fonctionnalités

- **Liste des films** avec affiches, recherche et filtres avancés
- **Favoris** pour films et cinémas
- **Calendrier** style Notion avec indicateurs de séances
- **Notifications locales** pour les rappels de séances
- **Synchronisation calendrier** via EventKit
- **Widget** (Small/Medium) affichant les films populaires
- **Mode hors-ligne** avec cache local

## Stack Technique

- **iOS 15.1+** (Compatible iPhone et iPad)
- **SwiftUI 3.0** avec `NavigationView`
- **CoreData** pour les favoris
- **Combine** pour la réactivité
- **async/await** pour le réseau
- **WidgetKit** pour les widgets
- **EventKit** pour le calendrier
- **UserNotifications** pour les rappels

## Structure du Projet

```
CineLyon/
├── CineLyonApp.swift          # Point d'entrée
├── Models/
│   ├── Movie.swift            # Modèle film
│   ├── Showtime.swift         # Modèle séance
│   ├── DaySchedule.swift      # Programmation journalière
│   └── Cinema.swift           # Modèle cinéma
├── Services/
│   └── MovieDataService.swift # Service réseau + cache
├── CoreData/
│   ├── CoreDataStack.swift    # Gestionnaire CoreData
│   └── CineLyonModel.xcdatamodeld
├── Managers/
│   ├── CalendarManager.swift     # EventKit
│   └── NotificationManager.swift # Notifications locales
├── ViewModels/
│   └── FavoritesViewModel.swift  # Gestion des favoris
├── Views/
│   ├── MainTabView.swift      # TabBar principal
│   ├── MovieListView.swift    # Liste des films
│   ├── MovieDetailView.swift  # Détail d'un film
│   ├── CalendarView.swift     # Calendrier Notion
│   ├── FavoritesView.swift    # Films/Cinémas favoris
│   └── SettingsView.swift     # Réglages
└── Assets.xcassets/

CineLyonWidget/
└── CineLyonWidget.swift       # Extension Widget
```

## Installation

1. Ouvrir Xcode et créer un nouveau projet iOS App
2. Cible: **iOS 15.1+**
3. Interface: **SwiftUI**
4. Copier les fichiers Swift générés dans le projet
5. Ajouter une nouvelle Target **Widget Extension**
6. Configurer les capabilities:
   - **Background Modes** → Background fetch
   - **Push Notifications**
7. Lancer sur simulateur ou device

## Permissions requises (Info.plist)

```xml
<key>NSCalendarsUsageDescription</key>
<string>CinéLyon souhaite accéder à votre calendrier pour ajouter vos séances.</string>
<key>NSUserNotificationsUsageDescription</key>
<string>CinéLyon souhaite vous envoyer des rappels avant vos séances.</string>
```

## API

L'application utilise un fichier JSON statique hébergé sur GitHub :
```
https://raw.githubusercontent.com/abdu-63/cinelyon/main/movies.json
```

## Licence

MIT License
# cinelyon-app
