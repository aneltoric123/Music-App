<div align="center">

# 🎵 music

A native iOS music player built entirely in **SwiftUI** and **SwiftData** — your library, your playlists, your music. No accounts, no ads, no cloud lock-in.

[![Platform](https://img.shields.io/badge/platform-iOS-blue)](#)
[![Language](https://img.shields.io/badge/language-Swift-orange)](#)
[![UI](https://img.shields.io/badge/framework-SwiftUI-brightgreen)](#)
[![Data](https://img.shields.io/badge/persistence-SwiftData-red)](#)

</div>

---

## ✨ Features

### 🎧 Full-Featured Audio Player
- Seamless playback with a global **mini player** that follows you across every view
- Play songs, albums, playlists or a shuffled queue with one tap
- Queue-aware playback: start anywhere in an album and it continues from there
- Beautiful animated play/shuffle controls with a custom gradient design

### 🔍 Smart Unified Search
- Live, debounced search across **songs, artists and albums** as you type
- Intelligent result grouping — tracks are matched by title, artist and album, with a separate section for album-only matches
- Every search is remembered: unified **recent searches** across all four result types, one-tap to re-run, swipe-to-delete to clear
- Tap through to rich artist and album pages straight from the results

### 📚 Your Library
- **12,000+ song local library**, loaded from a single JSON file — fully offline
- Browse artists, albums and songs with async-loaded cover art
- **Liked Songs** with a built-in playlist, plus like/unlike feedback toasts with haptics
- Custom **playlists** with live cover collages built from the songs inside them

### ➕ Playlist Management
- Add any song to multiple playlists from a dedicated picker
- Create brand-new playlists on the fly — the song is already in them
- Visual checkmarks show which playlists already contain a song

### 🎨 Designed with Care
- Dark, ambient interface with layered gradients and soft glows
- Clean typography tuned for long titles (artist – title – album parsing)
- Smooth transitions between keyboard, results and navigation

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Persistence | SwiftData (`@Model`, `@Query`, `FetchDescriptor`) |
| Architecture | MVVM with `@EnvironmentObject` state |
| Audio | `AVFoundation` |
| Concurrency | Swift structured concurrency (`Task`, cancellation) |

---

## 🗄 Data Model

Built on SwiftData with proper relationships:

- `User` → owns playlists and search history
- `Playlist` → ordered `PlaylistSongs` entries
- `Song`, `Artist`, `Album` → full relational graph with inverse relationships
- `SearchHistory`, `SongSearchHistory`, `ArtistSearchHistory`, `AlbumSearchHistory` → per-type search memory with timestamps

---

## 🚀 Getting Started

### Prerequisites
- Xcode 16+
- iOS 17+ (SwiftData requirement)
- A local music library JSON file

### Running

1. Clone the repository
2. Open `music.xcodeproj` in Xcode
3. Add your library JSON to the app bundle (or documents folder, depending on your loader)
4. Build and run on a simulator or device

```bash
git clone <your-repo-url>
cd music
open music.xcodeproj
```

---

## 🏗 Architecture Highlights

- **Debounced search**: every keystroke cancels the previous search task, waits 300 ms, then queries SwiftData with `#Predicate` — no jank even on a 12,000-song library
- **Centralized playback state**: `AudioPlayerManager` owns the queue, current song and mini player visibility, so every screen stays in sync
- **Smart title parsing**: track titles like `Artist - Title - Album` are parsed once and rendered everywhere consistently

---

## 📷 Photos of App

![description] (screenshots/IMG_1660.PNG)
![description] (screenshots/IMG_1661.PNG)
![description] (screenshots/IMG_1662.PNG)
![description] (screenshots/IMG_1663.PNG)
![description] (screenshots/IMG_1664.PNG)
![description] (screenshots/IMG_1665.PNG)
![description] (screenshots/IMG_1666.PNG)
![description] (screenshots/IMG_1667.PNG)
![description] (screenshots/IMG_1668.PNG)
![description] (screenshots/IMG_1669.PNG)
![description] (screenshots/IMG_1670.PNG)
![description] (screenshots/IMG_1671.PNG)

---

## 📄 License

This project is for personal and educational use.

---

<div align="center">
Made with ❤️ and SwiftUI
</div>
