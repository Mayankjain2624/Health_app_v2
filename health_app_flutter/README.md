# CAL - Health & Fitness Tracking App

A professional-grade Flutter application for real-time health and fitness data synchronization with Health Connect and cloud persistence.

![Flutter](https://img.shields.io/badge/Flutter-3.38.7-blue?style=flat-square)
![Dart](https://img.shields.io/badge/Dart-3.10.7-blue?style=flat-square)
![Android](https://img.shields.io/badge/Android-15%20(API%2035)-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 🎯 Features

- **Real-Time Health Data Sync**
  - Step count tracking with historical data
  - Workout session logging with detailed metrics
  - Heart rate monitoring
  - Calorie burn tracking (active & total)
  - Distance metrics
  
- **Professional UI/UX**
  - Material Design 3 with dark theme
  - Feature-rich home screen with activity cards
  - Detailed health data dashboard
  - Sync history with timezone-aware timestamps (IST)
  - Smooth animations and responsive design

- **Health Connect Integration**
  - Native Android Health Connect permissions
  - Support for multiple fitness activities (Running, Cycling, Swimming, etc.)
  - Automatic activity type formatting and categorization
  - Secure permission management

- **Cloud Synchronization**
  - Real-time data sync to MongoDB
  - Offline-first architecture
  - Sync status logging with timestamps
  - Conflict resolution and data validation

---

## 📱 Tech Stack

### Frontend
- **Framework:** Flutter 3.38.7
- **Language:** Dart 3.10.7
- **State Management:** BLoC (flutter_bloc 9.1.1)
- **Health Data:** health 13.2.1
- **Permissions:** permission_handler 12.0.1
- **HTTP Client:** dio 5.9.0
- **Local Storage:** shared_preferences 2.5.4
- **Date/Time:** intl 0.20.2
- **UI/UX:** Material Design 3

### Backend
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB
- **API:** RESTful endpoints
- **Validation:** Joi schema validation

### Android
- **Target:** Android 15 (API 35)
- **Min SDK:** API 21
- **Health Connect:** Latest version

---

## 🏗️ Architecture

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── workout_session.dart           # Workout data model
│   └── step_summary.dart              # Steps data model
├── services/
│   ├── health_service.dart            # Health Connect integration
│   └── api_service.dart               # Backend API calls
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart           # Landing page with feature cards
│   │   └── health_data_screen.dart    # Main health dashboard
│   └── widgets/                       # Reusable components
└── bloc/                              # State management
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.38.7+
- Dart SDK 3.10.7+
- Android SDK (API 35+)
- Device with Health Connect installed

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/cal-health-app.git
cd cal-health-app

# Install dependencies
flutter pub get

# Run on device
flutter run
```

### Android Device Setup

```bash
# Check connected devices
flutter devices

# Enable port forwarding for backend (once per session)
adb reverse tcp:3000 tcp:3000

# Run app
flutter run -d <device-id>
```

---

## ⚙️ Configuration

### Health Connect Permissions

Auto-requested on first launch:

| Permission | Purpose |
|-----------|---------|
| `READ_STEPS` | Daily step count |
| `READ_HEART_RATE` | Heart rate data |
| `READ_DISTANCE` | Distance traveled |
| `READ_ACTIVE_ENERGY_BURNED` | Active calorie burn |
| `READ_TOTAL_ENERGY_BURNED` | Total calorie burn |
| `READ_WORKOUTS` | Fitness activities |

### Backend Connection

Update backend URL in `lib/services/api_service.dart`:

```dart
const String baseUrl = 'http://localhost:3000';
```

---

## 📡 API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/steps` | Sync step data |
| POST | `/api/workouts` | Sync workout sessions |
| GET | `/api/sync/logs` | Fetch sync history |

---

## 💾 Data Models

### WorkoutSession
```json
{
  "type": "RUNNING",
  "activityTypeName": "Running",
  "start": "2025-01-17T06:00:00Z",
  "end": "2025-01-17T06:45:00Z",
  "durationSeconds": 2700,
  "activeCalories": 450,
  "steps": 5200,
  "distance": 4.2,
  "avgHeartRate": 145,
  "peakHeartRate": 165,
  "avgPace": "6:30/km"
}
```

---

## 🧪 Testing

### Manual Checklist

- [ ] App launches without errors
- [ ] Health Connect permissions requested
- [ ] Steps load correctly
- [ ] Workouts sync from Health Connect
- [ ] Sync history displays with IST timezone
- [ ] Refresh updates all data
- [ ] App icon displays as "CAL"

---

## 🐛 Troubleshooting

### Workouts Not Syncing
```bash
# Grant permissions manually
# Settings → Apps → CAL → Permissions → Health Connect
# Enable all scopes
```

### Backend Connection Failed
```bash
# Ensure port forwarding is active
adb reverse tcp:3000 tcp:3000
```

### Timezone Issues
- App automatically converts UTC to IST (UTC+5:30)
- Verify device timezone in Settings → System → Date & time

---

## 📊 Performance

- **App Size:** ~150 MB
- **Memory:** 120-180 MB average
- **Startup:** 2-3 seconds
- **Sync:** < 1 second

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -m 'Add improvement'`)
4. Push to branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

**Made with ❤️ for health-conscious developers**
