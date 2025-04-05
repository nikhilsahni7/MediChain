<!-- # MediChain: Privacy-First Medicine Sharing for Hospitals

## The Problem

Hospitals in busy regions like Delhi NCR face a critical challenge: localized medicine shortages lead to preventable patient harm, while nearby hospitals might simultaneously have expiring surpluses. The lack of a secure, efficient system for inter-hospital sharing costs time, resources, and tragically, lives.

## Our Solution: MediChain

**MediChain is a secure, decentralized platform connecting hospitals for efficient, privacy-preserving medicine sharing.**

Built with a focus on real-world healthcare needs, MediChain allows hospitals to:

- **Check Availability Anonymously:** Find urgently needed medicines at nearby facilities without revealing sensitive inventory details.
- **Order Seamlessly:** Request drugs via secure peer-to-peer communication.
- **Pay Flexibly:** Use familiar methods like UPI (Razorpay) or modern options like cryptocurrency (Coinbase Commerce).
- **Optimize Inventory:** Visualize stock levels, track expiry dates, and get smart substitution suggestions.

We achieve this through a unique blend of modern tech, emphasizing **privacy through encryption and pseudonymity** and **trust through tamper-evident logging**, mimicking key benefits of decentralized systems without the full complexity of blockchain (yet!).

---

## Core Features

- **⚕️ Check Medicine Availability:**
  - Input: Drug name & quantity.
  - Output: List of _anonymous_ hospital IDs (e.g., `HOSP-XYZ`) showing availability.
  - Mechanism: Verifies availability against encrypted inventory commitments (HMACs) stored in a shared ledger (Firebase Storage JSON).
- **🛒 Order Drugs:**
  - Select a hospital from availability results.
  - Initiate a secure Peer-to-Peer (P2P) request using FCM.
  - Confirm order upon successful payment (Razorpay UPI, Coinbase Crypto QR, Mock Cash).
- **🗺️ Hospital Map Integration (Google Maps):**
  - Visualize locations of participating hospitals (seeded with real NCR coordinates).
  - Sort nearby hospitals by proximity.
- **📊 Graphs & Data Visualization:**
  - **Bar Chart:** Current stock levels of key medicines.
  - **Line Chart:** Trends of expiring medicines (e.g., count expiring within 30/60 days).
  - Data sourced from a backend `/stats` endpoint.
- **⚠️ Expiry Alerts & Priority Tags:**
  - Drugs expiring within 30 days are flagged (e.g., red text).
  - Critical drugs (e.g., antibiotics) can be tagged as "High Priority" in the UI.
- **💡 Dynamic Drug Substitution:**
  - Suggests clinically relevant alternatives (e.g., Ibuprofen for Paracetamol) if the primary drug is unavailable nearby. (Based on a predefined substitution list).
- **🔄 Real-Time Stock Updates:**
  - Inventory changes pushed via FCM update UI elements (like graphs) live.

## Security & Decentralization Highlights

- **🔒 Encrypted Inventory Commitments (HMACs):** Hospitals generate HMACs of their inventory counts locally using a secret key. Only these HMACs are stored publicly in the Firebase Storage ledger. This allows availability checks _without_ revealing exact stock numbers to other hospitals.
- **👻 Anonymous Hospital IDs:** Real hospital names are masked with pseudonyms (e.g., `HOSP-001`) during availability checks. Identities are only revealed upon order confirmation.
- **🤝 Peer-to-Peer (P2P) Order Requests:** Order requests are sent directly between hospitals using Firebase Cloud Messaging (FCM), reducing reliance on a central intermediary.
- **✍️ Tamper-Proof Audit Log:** Key order details are hashed (SHA256) and appended to a separate audit log file in Firebase Storage, creating a verifiable trail of transactions.

## Optional "Wow" Feature (If Time Allows)

- **🗣️ Voice Command Search:** (using `speech_to_text`)
  - Allows users to initiate medicine checks via voice (e.g., "Check Paracetamol 50").
  - _Appeal: "Hands-free convenience for busy medical professionals!"_

---

## Tech Stack

- **Frontend:** Flutter (iOS, Android, Web)
  - State Management: `flutter_riverpod`
  - Routing: `go_router`
  - UI: `google_fonts`, `charts_flutter`, `google_maps_flutter`, `google_nav_bar`, `introduction_screen`, `lottie`
  - Payments: `razorpay_flutter`
  - Crypto: `qr_flutter` (for Coinbase QR display)
  - P2P/Real-time: `firebase_messaging`
  - (Optional) Voice: `speech_to_text`
- **Backend:** Node.js + Express
  - API for check, order, stats, payments.
  - HMAC generation/verification (`crypto`).
- **Database:** PostgreSQL
  - `Hospital`: id, name, location (lat/lng), inventory (JSON), `secretKey`.
  - `Order`: id, drugName, quantity, fromHospitalId, toHospitalId, status, paymentMethod, transactionHash (for audit).
- **Ledger/Storage:** Firebase Storage
  - `inventory_ledger.json`: Stores `{ hospitalId: { hmac: "..." } }`
  - `audit_log.json`: Stores `{ orderId: "...", detailsHash: "..." }`
- **Deployment:**
  - Backend: Heroku (or similar PaaS)
  - Frontend: Firebase Hosting
  - Storage: Firebase Storage

---

## Folder Structure (Simplified)

```
medileger/
├── android/                 # Android specific files
├── ios/                     # iOS specific files
├── lib/
│   ├── app/                 # Core App setup (MaterialApp, main widget)
│   ├── config/              # Configuration files
│   │   ├── router/          # GoRouter setup (app_router.dart)
│   │   └── theme/           # Theme definition (app_theme.dart)
│   ├── core/                # Core utilities, providers, constants
│   │   ├── providers/       # Riverpod providers (e.g., SharedPreferences)
│   │   └── utils/           # Utility functions (e.g., crypto)
│   ├── features/            # Feature modules
│   │   ├── auth/            # Authentication (Login, Signup)
│   │   │   └── presentation/
│   │   │       ├── providers/ # State notifiers/providers for auth
│   │   │       └── screens/   # LoginScreen, etc.
│   │   ├── check_medicines/ # Check Availability feature
│   │   ├── home/            # Main screen with Bottom Nav Bar
│   │   ├── maps/            # Google Maps integration
│   │   ├── onboarding/      # Onboarding screens
│   │   ├── order_drugs/     # Order placement feature
│   │   ├── payments/        # Payment integration logic
│   │   ├── settings/        # Settings screen
│   │   └── stats/           # Graphs and data visualization
│   ├── shared/              # Shared widgets, models, services
│   │   └── widgets/         # Reusable UI components (e.g., PlaceholderScreen)
│   └── main.dart            # App entry point
├── assets/                  # Static assets
│   ├── images/              # PNG, JPG files
│   ├── animations/          # Lottie JSON files
│   └── fonts/               # Custom font files (if any)
├── test/                    # Unit and widget tests
├── pubspec.yaml             # Project dependencies and metadata
└── README.md                # This file!
```

---

## Getting Started

1. **Prerequisites:**
   - Flutter SDK installed (check with `flutter doctor`)
   - Node.js and npm/yarn installed (for potential backend setup)
   - Firebase Project Setup (Authentication, Storage, FCM)
   - PostgreSQL database instance
   - API Keys: Google Maps, Razorpay, Coinbase Commerce (if implementing fully)
2. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd medileger
   ```

3. **Install Flutter dependencies:**

   ```bash
   flutter pub get
   ```

4. **Setup Environment Variables:**
   - Create a `.env` file (and add to `.gitignore`).
   - Add necessary API keys and database connection strings. (Specific variables TBD).
5. **Configure Firebase:**
   - Download your Firebase project's `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the respective `android/app` and `ios/Runner` directories.
   - Ensure Firebase Storage rules allow appropriate read/write access.
6. **Backend Setup:** (If running locally)
   - Navigate to the backend directory (if separate).
   - Install dependencies (`npm install` or `yarn install`).
   - Configure database connection.
   - Run the backend server (`npm start` or `yarn dev`).
7. **Run the Flutter App:**

   ```bash
   flutter run
   ```

---

## Deployment

- **Backend (Node.js):** Deploy to Heroku, Render, or similar Platform-as-a-Service.
- **Frontend (Flutter Web/Mobile):**
  - Web: Build (`flutter build web`) and deploy to Firebase Hosting.
  - Mobile: Build APK/IPA and distribute as needed.
- **Ledger:** Firebase Storage handles this automatically as part of your Firebase project.

---

_For more information on Flutter development, view the [online documentation](https://docs.flutter.dev/)._ -->
