# Femora - AI-Driven Women's Wellbeing Ecosystem

<div align="center">
 
  <p><i>Your intelligent companion for period tracking, pregnancy monitoring, mental wellness, and community support</i></p>
  
  ![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=flat&logo=flutter)
  ![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=flat&logo=node.js)
  ![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=flat&logo=supabase)
  ![License](https://img.shields.io/badge/License-MIT-yellow.svg)
  ![Status](https://img.shields.io/badge/Status-In%20Development-orange)
</div>

---

## Description

Femora is an intelligent mobile application that integrates period tracking, pregnancy monitoring, mental health assessment, safety features, and community support through the **Femora Intelligence Engine (FIE)** - our proprietary AI system that provides predictive analytics and personalized health insights. This platform empowers women to take control of their health journey with data-driven insights and compassionate community support.

---
## Architecture Documentation

- docs/PROJECT_CONTEXT.md
- docs/ARCHITECTURE_GUIDELINES.md
  
---
## Key Features

### **Period Tracker**
- Intelligent cycle prediction with confidence scores
- Flow level and symptom logging
- PMS emotional alerts based on cycle phase
- Exportable cycle history reports

### **Pregnancy Journey**
- Week-by-week pregnancy tracking
- Trimester-specific health support
- Symptom monitoring with AI insights
- Baby development milestones

### **Mental Health Hub**
- Mood tracking with emoji + slider interface
- Sleep quality logging
- ESI (Emotional Stability Index) calculations
- HECS (Hormonal-Emotional Correlation Score)
- Predictive emotional low alerts

### **Safety Center**
- SOS emergency activation
- Trusted contacts management
- Live location sharing
- Quick access to crisis resources

### **Community Platform**
- Anonymous discussion forums
- Category-based feeds (Period, Pregnancy, Mental Health)
- Content library with articles
- Peer support groups

### **Femora Intelligence Engine (FIE)**
Our central AI core that:
- **Analyzes** cross-module data patterns
- **Predicts** period dates, emotional dips, and health events
- **Personalizes** content and interventions
- **Calculates** research-backed metrics (ESI, HECS, SIS, PAR)
- **Detects** risk patterns for preventive care

---

## Technologies Used

### Frontend
- **Flutter 3.16+** - Cross-platform mobile framework
- **Dart 3.0+** - Programming language
- **Supabase Flutter SDK** - Backend integration
- **Provider** - State management
- **Go Router** - Navigation
- **Table Calendar** - Calendar views
- **FL Chart** - Data visualization

### Backend
- **Node.js v18+** - Runtime environment
- **Express.js** - Web framework
- **Supabase** - PostgreSQL database & authentication
- **JWT** - Token-based authentication (via Supabase)

### AI/ML Service
- **Python 3.11+** - ML algorithms
- **FastAPI** - API framework
- **NumPy & Pandas** - Data processing
- **Scikit-learn** - Machine learning

### Development Tools
- **Git & GitHub** - Version control
- **VS Code** - Code editor
- **Android Studio / Xcode** - Mobile development
- **Postman / Thunder Client** - API testing

---

## Setup and Installation

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK 3.16+** ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart 3.0+** (comes with Flutter)
- **Node.js v18+** ([Download](https://nodejs.org/))
- **npm** (comes with Node.js)
- **Python 3.11+** (for AI service)
- **Git** ([Download](https://git-scm.com/))
- **Supabase Account** ([Sign up](https://supabase.com))
- **Android Studio** (for Android) or **Xcode** (for iOS)

### Steps to Set Up

#### 1. Clone the Repository
```bash
git clone https://github.com/djdJANU/femora-app.git
cd femora-app
```

#### 2. Setup Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to Project Settings → API
3. Copy your project URL and anon key
4. Navigate to SQL Editor and run the schema:
```bash
# The schema file is located at: docs/database-schema.sql
# Copy and paste it into Supabase SQL Editor and run
```

#### 3. Setup Mobile App (Flutter)
```bash
# Navigate to mobile directory
cd mobile

# Install dependencies
flutter pub get

# Create .env file from example
cp .env.example .env

# Edit .env with your Supabase credentials
# SUPABASE_URL=your_project_url
# SUPABASE_ANON_KEY=your_anon_key
```

#### 4. Setup Backend API
```bash
# Navigate to backend directory
cd ../backend

# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Edit .env with your Supabase credentials
# SUPABASE_URL=your_project_url
# SUPABASE_ANON_KEY=your_anon_key
# SUPABASE_SERVICE_KEY=your_service_role_key
# PORT=3000
```

#### 5. Setup AI Service (Optional - for FIE algorithms)
```bash
# Navigate to ai-service directory
cd ../ai-service

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
```

### Running the Application

#### Run Mobile App (Development)
```bash
cd mobile

# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios

# For specific device
flutter devices  # List available devices
flutter run -d [device-id]
```

#### Run Backend Server (Development)
```bash
cd backend
npm run dev

# Server runs on http://localhost:3000
```

#### Run AI Service (Development)
```bash
cd ai-service
python main.py

# Service runs on http://localhost:8000
```

### Running in Production

#### Build Mobile App

**Android APK:**
```bash
cd mobile
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

**iOS (macOS only):**
```bash
cd mobile
flutter build ios --release

# Open in Xcode for distribution
open ios/Runner.xcworkspace
```


##  CI/CD

Use **GitHub Actions** for continuous integration and deployment:

- **On Push to `develop`:** Automated tests run
- **On Pull Request:** Build verification and tests
- **On Merge to `main`:** Automatic deployment

### Deployment Platforms
- **Mobile:** Manual APK/IPA distribution (future: Play Store/App Store)
- **Backend:** Vercel / Railway / Heroku
- **Database:** Supabase (managed)

---

## 📂 Common Folder Structure & Guidelines

### Mobile App (Flutter)
```plaintext
📂 mobile/
 ┣ 📂 lib/
 ┃ ┣ 📂 screens/              # All screen components
 ┃ ┃ ┣ 📂 auth/              # Authentication screens
 ┃ ┃ ┃ ┣ 📜 login_screen.dart
 ┃ ┃ ┃ ┣ 📜 signup_screen.dart
 ┃ ┃ ┃ ┗ 📜 splash_screen.dart
 ┃ ┃ ┣ 📂 home/              # Home dashboard
 ┃ ┃ ┣ 📂 period/            # Period tracking screens
 ┃ ┃ ┣ 📂 pregnancy/         # Pregnancy tracking screens
 ┃ ┃ ┣ 📂 mental_health/     # Mental health screens
 ┃ ┃ ┣ 📂 safety/            # Safety center screens
 ┃ ┃ ┗ 📂 community/         # Community screens
 ┃ ┃
 ┃ ┣ 📂 widgets/             # Reusable UI components
 ┃ ┃ ┣ 📂 buttons/          # Button components
 ┃ ┃ ┣ 📂 cards/            # Card components
 ┃ ┃ ┣ 📂 forms/            # Form elements
 ┃ ┃ ┗ 📂 charts/           # Chart widgets
 ┃ ┃
 ┃ ┣ 📂 models/              # Data models
 ┃ ┃ ┣ 📜 user_model.dart
 ┃ ┃ ┣ 📜 period_model.dart
 ┃ ┃ ┗ 📜 mood_model.dart
 ┃ ┃
 ┃ ┣ 📂 services/            # API & business logic
 ┃ ┃ ┣ 📂 api/              # API calls
 ┃ ┃ ┃ ┣ 📜 auth_api.dart
 ┃ ┃ ┃ ┣ 📜 period_api.dart
 ┃ ┃ ┃ ┗ 📜 mood_api.dart
 ┃ ┃ ┣ 📜 supabase_service.dart
 ┃ ┃ ┗ 📜 notification_service.dart
 ┃ ┃
 ┃ ┣ 📂 providers/           # State management (Provider)
 ┃ ┃ ┣ 📜 auth_provider.dart
 ┃ ┃ ┣ 📜 period_provider.dart
 ┃ ┃ ┗ 📜 mood_provider.dart
 ┃ ┃
 ┃ ┣ 📂 utils/               # Utility functions
 ┃ ┃ ┣ 📜 constants.dart    # App constants
 ┃ ┃ ┣ 📜 validators.dart   # Input validators
 ┃ ┃ ┗ 📜 date_helpers.dart # Date utilities
 ┃ ┃
 ┃ ┣ 📂 config/              # Configuration files
 ┃ ┃ ┣ 📜 app_theme.dart    # Theme configuration
 ┃ ┃ ┗ 📜 routes.dart       # Navigation routes
 ┃ ┃
 ┃ ┣ 📜 main.dart            # App entry point
 ┃ ┗ 📜 app.dart             # Main app widget
 ┃
 ┣ 📂 assets/                # Static assets
 ┃ ┣ 📂 images/             # Images
 ┃ ┣ 📂 icons/              # Icons
 ┃ ┗ 📂 fonts/              # Custom fonts
 ┃
 ┣ 📜 pubspec.yaml           # Dependencies
 ┣ 📜 .env.example           # Environment variables template
 ┗ 📜 README.md              # Mobile app documentation
```

### Backend (Node.js)
```plaintext
📂 backend/
 ┣ 📂 src/
 ┃ ┣ 📂 routes/              # API routes
 ┃ ┃ ┣ 📜 authRoutes.js
 ┃ ┃ ┣ 📜 periodRoutes.js
 ┃ ┃ ┣ 📜 moodRoutes.js
 ┃ ┃ ┗ 📜 communityRoutes.js
 ┃ ┃
 ┃ ┣ 📂 controllers/         # Route handlers
 ┃ ┃ ┣ 📜 authController.js
 ┃ ┃ ┣ 📜 periodController.js
 ┃ ┃ ┗ 📜 moodController.js
 ┃ ┃
 ┃ ┣ 📂 services/            # Business logic
 ┃ ┃ ┣ 📜 periodService.js
 ┃ ┃ ┣ 📜 moodService.js
 ┃ ┃ ┗ 📜 fieService.js     # FIE orchestration
 ┃ ┃
 ┃ ┣ 📂 models/              # Database models
 ┃ ┃ ┣ 📜 User.js
 ┃ ┃ ┗ 📜 Period.js
 ┃ ┃
 ┃ ┣ 📂 middleware/          # Express middleware
 ┃ ┃ ┣ 📜 authMiddleware.js
 ┃ ┃ ┣ 📜 validation.js
 ┃ ┃ ┗ 📜 errorHandler.js
 ┃ ┃
 ┃ ┣ 📂 utils/               # Utility functions
 ┃ ┃ ┣ 📜 logger.js
 ┃ ┃ ┗ 📜 helpers.js
 ┃ ┃
 ┃ ┗ 📂 config/              # Configuration
 ┃   ┣ 📜 database.js
 ┃   ┗ 📜 supabase.js
 ┃
 ┣ 📜 server.js              # Entry point
 ┣ 📜 package.json           # Dependencies
 ┣ 📜 .env.example           # Environment variables template
 ┗ 📜 README.md              # Backend documentation
```

### AI Service (Python)
```plaintext
📂 ai-service/
 ┣ 📂 app/
 ┃ ┣ 📂 algorithms/          # FIE algorithms
 ┃ ┃ ┣ 📜 esi_calculator.py # Emotional Stability Index
 ┃ ┃ ┣ 📜 hecs_calculator.py # Hormonal-Emotional Correlation
 ┃ ┃ ┗ 📜 predictor.py      # Prediction algorithms
 ┃ ┃
 ┃ ┣ 📂 models/              # ML models
 ┃ ┃ ┗ 📜 period_predictor.py
 ┃ ┃
 ┃ ┣ 📂 api/                 # FastAPI routes
 ┃ ┃ ┣ 📜 predictions.py
 ┃ ┃ ┗ 📜 analytics.py
 ┃ ┃
 ┃ ┗ 📜 main.py              # FastAPI app
 ┃
 ┣ 📜 requirements.txt       # Python dependencies
 ┣ 📜 .env.example           # Environment variables template
 ┗ 📜 README.md              # AI service documentation
```


## Testing

### Flutter Tests
```bash
cd mobile
flutter test
```

### Backend Tests
```bash
cd backend
npm test
```

### AI Service Tests
```bash
cd ai-service
pytest
```

---

##  Project Roadmap

### Phase 1: Foundation (Weeks 1-2) 
- [x] Project setup and architecture
- [x] Authentication system
- [x] Period tracker module
- [x] Basic home dashboard

### Phase 2: Core Features (Weeks 3-4) 
- [ ] Pregnancy tracker
- [ ] Mental health module (mood + sleep)
- [ ] Community feed
- [ ] Safety center

### Phase 3: Intelligence (Weeks 5-6) 
- [ ] FIE integration
- [ ] Predictive analytics
- [ ] Cross-module intelligence
- [ ] Risk detection

### Phase 4: Polish & Launch (Week 7) 
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Testing and bug fixes
- [ ] Deployment and documentation

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Author

**Meegoda Dilakna**
-  University: Plymouth  University
-  Program: Final Year Software Engineering
-  Project Supervisor: Miss.Dulanjali Wijesekara
-  Email: 10952548@students.plymouth.ac.uk
-  LinkedIn: linkedin.com/in/janudi-meegoda
-  GitHub: @djdJANU(https://github.com/djdJANU)

---

## Acknowledgments

- **Anthropic** for AI development assistance
- **Flutter Team** for excellent framework and documentation
- **Supabase** for powerful backend infrastructure
- **Project Supervisor** for guidance and feedback
- **Beta Testers** for valuable insights
- **Open Source Community** for amazing tools and libraries

---

## Project Status

**Current Version:** v0.1.0 (Development)  
**Status:**  In Active Development  
**Target Completion:** April 20, 2026  
**Last Updated:** February 13, 2026

---

## Support & Contact

For questions, issues, or suggestions:
- Email: janudimeegoda@gmail.com
- Issues: [GitHub Issues](https://github.com/djdJANU/femora-app/issues)
- Discussions: [GitHub Discussions](https://github.com/djdJANU/femora-app/discussions)

---

<div align="center">
  <p>Made with 💜 for women's health and wellbeing</p>
  <p>© 2024 Femora. All rights reserved.</p>
  
  ⭐ Star this repo if you find it helpful!
</div>
