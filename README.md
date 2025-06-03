# StudySync - Timetable App 📚

![StudySync Banner](assets/banner.png) 

A beautiful Flutter timetable application that helps students track their class schedules with ease. Features include multi-batch support, day-wise view, and offline caching.

## Features ✨

- 🗓️ Weekly timetable view with tab navigation
- 🔄 Pull-to-refresh functionality
- 🌙 Dark/Light mode toggle
- 📱 Offline support with cached data
- 🎨 Color-coded subjects for quick identification
- 🔍 Quick week switching (previous/next week)
- 📲 Splash screen for better user experience
- 🔄 Automatic sync with remote timetable data

## Screenshots 📸

| Light Mode                            | Dark Mode                           |
|---------------------------------------|-------------------------------------|
| ![Light Mode](screenshots/light.jpeg) | ![Dark Mode](screenshots/dark.jpeg) |

## Installation ⚙️

### Prerequisites
- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- Android Studio/Xcode (for emulator/simulator)

### Steps
####1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/studysync.git
   cd studysync
   ```
####2. Install dependencies:
```bash
flutter pub get
```
####3. Generate splash screen (run once):
```bash
flutter pub run flutter_native_splash:create
```
####4. Run the app:
```bash
flutter run
```
## Project Structure 📂
```bash
lib/
├── main.dart          # App entry point
├── screens/
│   └── timetable.dart # Main timetable screen
├── services/
│   ├── api_service.dart # API communication
│   └── cache_service.dart # Local storage
├── models/
│   └── timetable.dart # Data models
└── widgets/
    └── schedule_card.dart # UI components
```
### Dependencies 📦
- http - For API calls

- shared_preferences - For local caching

- flutter_native_splash - For splash screen

- flutter_launcher_icons - For app icons

### Contributing 🤝
1. Contributions are welcome! Please follow these steps:

2. Fork the project

3. Create your feature branch (git checkout -b feature/AmazingFeature)

4. Commit your changes (git commit -m 'Add some amazing feature')

5. Push to the branch (git push origin feature/AmazingFeature)

6. Open a Pull Request

### Support ❤️
If you like this project, please consider giving it a ⭐️ on GitHub!
