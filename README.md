# D.R.E.W. Vending Machine UI

A Flutter UI implementation for the D.R.E.W. (Dignity • Respect • Empowerment for Women) feminine hygiene vending machine with a 10" touchscreen interface.

## Project Overview

This Flutter application implements the user interface for a vending machine targeting a 10" touchscreen display on a Raspberry Pi. The application includes:

- Authentication via PIN code or RFID card scanning
- Product selection and dispensing interface
- Inventory management
- Admin panel for stock management and activity logs
- Sound feedback throughout the interface

## Features

### Authentication System
- Dual authentication modes (PIN and RFID)
- Brute-force prevention with lockout after 3 failed attempts
- Session management with auto-logout after 1 minute of inactivity

### Product Management
- Visual display of available products
- Real-time stock tracking
- Dispensing simulation with progress feedback

### Admin Interface
- Inventory management
- Activity logs
- Stock replenishment tools

### User Experience
- Touch-optimized interface for 10" screens
- Sound effects for user interactions
- Visual feedback for all actions

## Project Structure

```
drew_vending_machine/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── screens/                  # Screen components
│   │   ├── lock_screen.dart      # Authentication screen
│   │   ├── product_screen.dart   # Product selection screen
│   │   └── admin_screen.dart     # Admin interface
│   ├── widgets/                  # Reusable UI components
│   │   ├── pin_keypad.dart       # PIN entry keypad
│   │   ├── rfid_scanner.dart     # RFID card scanner
│   │   ├── product_card.dart     # Product display card
│   │   └── dispensing_dialog.dart# Dispensing progress dialog
│   ├── services/                 # Business logic
│   │   ├── authentication_service.dart  # Authentication logic
│   │   ├── inventory_service.dart       # Product inventory
│   │   └── sound_service.dart           # Audio feedback
│   └── models/                   # Data models
├── assets/                       # App resources
│   ├── images/                   # Product images
│   └── sounds/                   # UI sound effects
└── pubspec.yaml                  # Package dependencies
```

## Getting Started

### Prerequisites
- Flutter SDK (installed and added to PATH)
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/drew_vending_machine.git
cd drew_vending_machine
```

2. Get the dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d chrome --web-renderer canvaskit
```

For deployment to a Raspberry Pi, build the application for web or Linux:
```bash
flutter build web --release
```

## Default Authentication Credentials

- **Admin PIN**: `9999`
- **User PIN**: `1234`
- **RFID Cards**: 
  - Admin Card: `A955AF02`
  - User Card: `B7621C45`

## Setting up for Production

For deployment on a Raspberry Pi with a 10" touchscreen:

1. Install Flutter on the Raspberry Pi or use the web build
2. Build the application for the appropriate platform
3. Configure the application to start on boot
4. If using the web build, set up a kiosk browser in fullscreen mode

## Future Enhancements

- Integration with real RFID hardware
- Serial communication with ESP32 for actual dispensing
- Database integration for persistent storage
- Cloud sync capabilities for inventory management
