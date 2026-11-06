# 🎙️ Sovereign Voice Ledger

### AI-Powered Voice-Based Digital Bookkeeping for Indian MSMEs

Sovereign Voice Ledger is a multilingual, voice-first digital bookkeeping application designed to simplify daily financial management for small businesses, particularly local shops and kirana stores.

Instead of manually recording every purchase and repayment, shop owners can simply speak in **English or Tamil**. The application processes the spoken request, identifies transaction details, and updates customer account balances after confirmation.

Our goal is to make digital bookkeeping simpler, more accessible, and less time-consuming for small business owners.

---

## 🚀 Key Features

### 1. Voice-Based Transactions
- Record customer purchases using voice commands.
- Support for English and Tamil.
- Speech-to-text processing and AI-powered natural language understanding.
- Extract customer names, products, quantities, and payment details.
- Review and confirm transactions before saving.

### 2. Intelligent Customer Management
- Automatically identify existing customers within a shop.
- Create customer records when a new customer is encountered.
- Maintain individual customer account balances.
- Handle duplicate customer names through clarification.

### 3. Product Management
- Add and manage shop products.
- Configure product prices and measurement units.
- Retrieve product prices from the database for transaction calculations.
- Update and deactivate products.

### 4. Automated Account Management
- Automatically calculate outstanding balances.
- Record purchases and repayments.
- Maintain transaction and account ledger records.
- Support advance payments and settled accounts.

### 5. Dashboard
- View total outstanding balances.
- Monitor customer count.
- Track daily sales and collections.
- View recent transactions.

### 6. Transaction History
- Maintain records of purchases and repayments.
- Review previous customer transactions.
- Keep financial activity organized.

---

## 🛠️ Technology Stack

| Component | Technologies |
|---|---|
| Frontend | Flutter, Dart |
| Backend | Python, Flask |
| Database | MySQL |
| Speech Recognition | Speech-to-Text |
| Natural Language Understanding | AI-powered NLU |
| Voice Output | Text-to-Speech |
| API Communication | REST API |
| Mobile Platform | Android |

---

## 🏗️ System Architecture

The application follows a modular architecture separating the frontend, backend, AI processing, and database layers.

```text
             Flutter Android App
                     |
                     |
                REST API
                     |
              Flask Backend
                     |
          -----------------------
          |          |          |
        Routes    Services    Models
          |          |          |
          -----------------------
                     |
                MySQL Database


             Voice Processing
                     |
             Speech-to-Text
                     |
              NLU Processing
                     |
          Transaction Validation
                     |
             User Confirmation
                     |
             Database Storage
                     |
              Text-to-Speech
                     |
              Flutter App
```

### Backend Architecture

The Flask backend follows a Route → Service → Model structure.

- **Routes:** Handle incoming HTTP requests.
- **Services:** Implement business logic and validation.
- **Models:** Handle database operations using MySQL.

### Voice Processing Workflow

1. The user records a voice command.
2. Audio is sent to the Flask backend.
3. Speech recognition converts audio into text.
4. NLU extracts transaction information.
5. Backend validation checks customer, product, quantity, and price details.
6. The application prepares the transaction for confirmation.
7. Once confirmed, the transaction is stored in MySQL.
8. The updated result is returned to the Flutter application with voice feedback.

---

## 📂 Project Structure

```text
VoiceAiLedger/
│
├── Backend/
│   ├── Routes/
│   ├── Services/
│   ├── Models/
│   ├── Utils/
│   ├── config/
│   ├── app.py
│   └── .env.example
│
├── Voice/
│   └── App/
│       └── Services/
│           ├── stt.py
│           ├── nlu.py
│           ├── validation.py
│           ├── tts.py
│           └── ai_pipeline.py
│
├── sovereign_voice_ledger/
│   ├── lib/
│   │   ├── config/
│   │   ├── screens/
│   │   ├── services/
│   │   └── main.dart
│   ├── android/
│   ├── pubspec.yaml
│   └── pubspec.lock
│
├── .gitignore
└── README.md
```

---

## ⚙️ Installation and Setup

### Prerequisites

Install the following:

- Python 3.10 or later
- Flutter SDK
- Dart SDK
- MySQL Server
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/Lurker2005/sovereign_voice_ledger.git

cd sovereign_voice_ledger
```

### 2. Set Up the Python Backend

Create and activate a virtual environment:

**Windows PowerShell**

```powershell
python -m venv venv

.\venv\Scripts\Activate.ps1
```

Install the required Python dependencies:

```powershell
pip install -r requirements.txt
```

Configure the environment variables using your local `.env` file.

Example configuration:

```env
DB_HOST=localhost
DB_USER=your_mysql_username
DB_PASSWORD=your_mysql_password
DB_NAME=sovereign_voice_ledger
```

Configure any additional credentials required by your speech recognition, NLU, and text-to-speech services.

### 3. Configure MySQL

Create the database:

```sql
CREATE DATABASE sovereign_voice_ledger;
```

Set up the required database tables before running the application.

### 4. Start the Flask Backend

From the project root:

```bash
python -m Backend.app
```

The backend will run on the configured local address and port.

For mobile testing, make sure the phone and computer are connected to the same Wi-Fi network and configure the Flutter API base URL with your computer's local IP address.

### 5. Set Up the Flutter Application

Navigate to the Flutter project:

```bash
cd sovereign_voice_ledger
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## 📊 Database and Business Logic

The application uses MySQL to maintain shop information, products, customers, transactions, payments, and account balances.

Important account rules:

- Positive balance: Customer owes money to the shop.
- Zero balance: Customer account is settled.
- Negative balance: Customer has an advance balance.

**Purchase calculation:**

```text
New Balance = Previous Balance + Purchase Total - Amount Paid
```

**Repayment calculation:**

```text
New Balance = Previous Balance - Repayment Amount
```

Product prices are retrieved from the database rather than relying on AI-generated values.

Transactions are saved only after confirmation, with database transaction handling to maintain consistency.

---

## 🌐 Multilingual Support

Sovereign Voice Ledger is designed to support natural voice interactions in:

- English
- Tamil

The system aims to understand everyday spoken transaction descriptions and convert them into structured financial records.

---

## 🎯 Project Objective

The primary objective is to bridge the gap between traditional bookkeeping and modern AI-powered technology.

By combining voice interaction, multilingual processing, and automated accounting, Sovereign Voice Ledger aims to help small businesses manage customer credit more efficiently.

---

## 🔮 Future Enhancements

- Additional Indian language support.
- Improved multilingual speech recognition.
- Advanced financial reports and analytics.
- Cloud synchronization and secure backups.
- Multi-user shop management.
- Improved conversational transaction handling.

---

## 👨‍💻 Developer

**Project:** Sovereign Voice Ledger

**GitHub:** [Lurker2005](https://github.com/Lurker2005)

---

## 📄 License

License and usage terms will be specified separately.

---

**Sovereign Voice Ledger — Smarter Bookkeeping, Powered by Your Voice.**