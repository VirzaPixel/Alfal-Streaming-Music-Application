# 🎵 ALFAL - Premium Music Experience

ALFAL is a high-end, serverless music streaming application built with **Flutter** and **Supabase**. It focuses on a premium user experience through modern design principles like **Glassmorphism**, **Dynamic Mesh Gradients**, and smooth **Micro-animations**.

![ALFAL Preview](https://github.com/VirzaPixel/Alfal-Streaming-Music-Application/raw/main/preview.png)

## ✨ Key Features

### 💎 Premium Interface
- **Glassmorphic Design:** A consistent, modern UI with frosted glass effects and dynamic blur.
- **Dynamic Headers:** The Liked Songs and Playlist pages feature animated mesh gradients and pulsing interactions.
- **Staggered Animations:** Beautiful entrance animations for lists and cards using `flutter_animate`.

### 🎧 Intelligent Playback
- **Smart Triple-State Repeat:** Seamlessly cycle between *Off*, *Repeat All*, and *Repeat One*.
- **Smart Shuffle Toggle:** Initiate randomized sessions directly from playlist headers with persistent visual state feedback.
- **Persistent Audio Service:** Background playback support using `audio_service` and `just_audio`.

### 📚 Library & Organization
- **Premium Playlist Manager:** Create and edit playlists with custom artwork (powered by Cloudinary).
- **Advanced Add-to-Playlist:** A dedicated options menu available on every song tile, Suggested Cards, and the Now Playing screen.
- **Optimized Profile:** Clean dashboard with limited playlist previews and full library access via "See All" sheets.

## 🛠 Tech Stack

- **Frontend:** Flutter (Riverpod for State Management)
- **Backend:** Supabase (Auth, Database, Storage)
- **Media Hosting:** Cloudinary (Dynamic Images)
- **Audio Engine:** `just_audio` & `audio_service`
- **Animations:** `flutter_animate` & `google_fonts`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Supabase account & project
- Cloudinary account (for image uploads)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/VirzaPixel/Alfal-Streaming-Music-Application.git
   ```

2. **Configure Environment Variables:**
   Create a `.env` file in the root directory and add your keys:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_UPLOAD_PRESET=your_upload_preset
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Built with ❤️ by Antigravity AI for a Premium Music Journey.*