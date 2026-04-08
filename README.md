Installer :

https://github.com/VirzaPixel/Alfal-Streaming-Music-Application/releases/tag/v1.0/app-release.apk

---

# 🎵 ALFAL — Music Without Limits

ALFAL is a high-performance, aesthetically pleasing music streaming ecosystem. It features a robust **Flutter** frontend, a scalable **Supabase** backend, and high-quality media delivery via **Cloudinary**.

---

## 🚀 Key Features

- **🎧 Seamless Streaming**: High-fidelity audio playback using `just_audio` with advanced buffering and gapless support.
- **✨ Magic Import**: One-click "Magic Import" workflow that leverages `youtube_explode_dart` to automatically extract song metadata, synced lyrics, and high-quality audio streams from YouTube and Spotify sources.
- **🤝 Social Synergy**: Connect with fellow music lovers through a real-time follow/unfollow system and profile discovery.
- **📊 Insights & Stats**: Detailed listening history and performance analytics powered by Supabase edge integration.
- **🖼️ Smart Caching**: Ultra-fast image loading and UI responsiveness using `cached_network_image`.
- **🔐 Secure & Serverless**: Managed authentication and Row Level Security (RLS) ensuring data privacy at scale.

---

## 🛠️ Technology Stack

| Layer | Technology | Role |
| :------- | :----------- | :---------- |
| **Frontend** | **Flutter** (Dart ^3.0.0) | Production-ready cross-platform UI. |
| **State Mgt** | **Riverpod** | Reactive, compile-safe state providers. |
| **Animation** | **flutter_animate** | For professional, high-end micro-animations. |
| **Engine** | **just_audio** | Feature-rich audio player with session management. |
| **Backend** | **Supabase** | PostgreSQL Database, Realtime, and Auth. |
| **CDN** | **Cloudinary** | Global delivery for audio, artwork, and profiles. |
| **Automation** | **Python** | Advanced metadata enrichment and library migration scripts. |

---

## 📂 Project Architecture

```
ALFAL/
├── frontend/           # Flutter Mobile Application
│   ├── lib/services/   # Logic (Auth, Audio, Magic Import, Connection, Stats)
│   ├── lib/providers/  # Riverpod State Management
│   ├── lib/screens/    # Feature-sliced UI (Home, Player, Social, Search)
│   └── lib/widgets/    # Reusable modern UI components
├── scripts/            # Python backend utilities & automated seeders
└── setup/              # Database schema migrations & SQL setup files
```

---

## 🏁 Getting Started

### 1. Prerequisites
- **Flutter SDK**: `^3.0.0`
- **Supabase**: Active project with URL and Anon Key.
- **Cloudinary**: Account for media hosting.

### 2. Configuration
Copy `.env_example` to `.env` in the `frontend/` directory and fill in your keys:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset_name
```

### 3. Running the App
```powershell
cd frontend
flutter pub get
# Run build_runner if you're using codegen
dart run build_runner build
flutter run
```

---

## 💎 Design Philosophy

ALFAL focuses on **Visual Excellence**:
- **Modern Micro-animations**: Every transition is polished with `flutter_animate`.
- **Optimized Performance**: Smooth scrolling and zero-lag streaming.
- **Elite Dark Mode**: Deep contrast and vibrant highlights for a premium vibe.
- **Reactive UI**: State changes are instantaneous and flicker-free.

---

## 🛡️ License & Contributors
ALFAL is an open-source project. Developed with a passion for music and high-end engineering.

---
*Created with ❤️ by the ALFAL Team.*