# NaviUdan 🚀
### AI-Powered Skill & Employment Platform | SDG 1 – No Poverty

> **Flutter (Dart) Mobile App + Python FastAPI Backend**

---

## 📁 Project Structure

```
NaviUdan/
├── backend/                     # Python FastAPI Backend
│   ├── main.py                  # App entry point
│   ├── config.py                # Settings
│   ├── requirements.txt         # Dependencies
│   ├── .env.example             # Environment variables template
│   ├── models/
│   │   ├── user_model.py
│   │   ├── job_model.py
│   │   ├── course_model.py
│   │   └── ai_model.py
│   ├── routers/
│   │   ├── auth.py              # Firebase token verification
│   │   ├── users.py             # Profile management
│   │   ├── jobs.py              # Job CRUD + AI matching
│   │   ├── courses.py           # Course recommendations
│   │   └── ai_bot.py            # Career AI + chatbot
│   └── services/
│       ├── firebase_service.py  # Firestore + Auth
│       └── ai_service.py        # Sentence-transformers AI engine
│
├── naviudan_app/                # Flutter Mobile App
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── constants/           # Colors, theme, strings
│       ├── models/              # Dart data models
│       ├── services/            # API + Auth services
│       ├── providers/           # State management (Provider)
│       ├── widgets/             # Reusable UI widgets
│       └── screens/
│           ├── splash_screen.dart
│           ├── auth/            # Login + OTP
│           ├── onboarding/      # Role selection + surveys
│           ├── job_finder/      # Home, courses, AI chat, weekly plan
│           └── recruiter/       # Dashboard, post job, applications
│
├── start_backend.bat            # Windows: start FastAPI server
└── start_flutter.bat            # Windows: run Flutter app
```

---

## ⚙️ Setup & Run

### 1. Backend (FastAPI)

```bash
cd backend

# Install dependencies
py -m pip install -r requirements.txt

# Copy and fill .env
copy .env.example .env
# Edit .env with your Firebase project ID and credentials path

# Start server
py -m uvicorn main:app --reload --port 8000
```

API Docs: http://localhost:8000/docs

---

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a project → Enable **Phone Authentication**
3. Enable **Firestore Database**
4. Download **google-services.json** → place in `naviudan_app/android/app/`
5. Download **Firebase Admin SDK** JSON → place in `backend/firebase_credentials.json`
6. Update `backend/.env` with `FIREBASE_PROJECT_ID=your-project-id`

---

### 3. Flutter App

```bash
cd naviudan_app

# Get packages
flutter pub get

# Run on connected device / emulator
flutter run

# Build APK
flutter build apk --release
```

> ⚠️ **Physical Device Testing**: Change `baseUrl` in `lib/services/api_service.dart` to your machine's local IP (e.g., `http://192.168.1.x:8000`)

---

## 🤖 AI Features

| Feature | Technology |
|---------|-----------|
| Skill gap detection | Rule-based NLP + Skill-Career mapping |
| Job matching | Sentence-Transformers (`all-MiniLM-L6-v2`) + Cosine similarity |
| Career chatbot | Pattern matching + context-aware responses |
| Weekly plan generation | Personalized 7-day goal planner |
| Course recommendations | Tag-overlap scoring |
| Trending fields | Region-based state-wise field mapping |

---

## 📱 App Screens

### Job Finder
- 🔐 Phone OTP Login
- 🎯 Role selection
- 📝 3-step profile survey (info → education → skills/interests)
- 🏠 Home: AI analysis card, weekly plan, courses, job matches
- 💬 NaviBot AI chat
- 💼 Job listings + Apply + Save
- 📚 Course recommendations (YouTube / Coursera / Udemy)
- 📅 Weekly learning plan

### Recruiter
- 🏢 Dashboard with stats
- ➕ Post Job form
- 👥 View & manage applications (accept/reject)
- 💬 NaviBot for recruiters

---

## 🔗 API Endpoints

| Method | Endpoint | Description |
|--------|---------|-------------|
| POST | `/users/profile` | Create/update user profile |
| GET | `/users/profile/{uid}` | Get user profile |
| GET | `/jobs/match/{uid}` | AI-matched jobs for user |
| POST | `/jobs/post` | Post a new job |
| POST | `/jobs/apply` | Apply for a job |
| POST | `/ai/analyze` | Full career AI analysis |
| POST | `/ai/chat` | AI chatbot response |
| GET | `/ai/weekly-plan/{uid}` | Generate weekly plan |
| GET | `/courses/recommend/{uid}` | Recommended courses |
| GET | `/ai/trending/{state}` | Trending fields by state |

---

## 🌱 SDG 1 Impact
- Bridges skill gaps in underserved communities
- Provides free AI-powered career guidance
- Connects local job seekers with nearby employers
- Multi-language support for wider reach
- Mobile-first design for rural accessibility
