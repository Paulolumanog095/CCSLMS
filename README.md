# 🖥️ Computer Laboratory Inventory System

A full-featured **Flutter Desktop** application for managing computer laboratory equipment, built with **Supabase** as the backend database.

---

## ✨ Features

| Module | Features |
|--------|----------|
| **Dashboard** | Stats overview, status distribution pie chart, recent activity |
| **Equipment** | Full CRUD, search, filter by lab/category/status |
| **Laboratories** | Manage lab rooms with capacity tracking |
| **Categories** | Equipment classification management |
| **Borrowing** | Track lending/returns, overdue management |
| **Maintenance** | Schedule and track repairs, preventive maintenance |
| **Reports** | Inventory summaries, analytics by status/condition/lab |

---

## 🚀 Quick Setup

### 1. Prerequisites
- Flutter SDK (≥ 3.0.0) — [Install Flutter](https://flutter.dev/docs/get-started/install)
- A Supabase account — [Create one free](https://supabase.com)

### 2. Enable Desktop Support
```bash
flutter config --enable-windows-desktop  # for Windows
flutter config --enable-macos-desktop    # for macOS
flutter config --enable-linux-desktop    # for Linux
```

### 3. Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and create a new project
2. In your Supabase dashboard, navigate to **SQL Editor**
3. Open and run the `supabase_schema.sql` file — this creates all tables, indexes, and seed data
4. Go to **Settings > API** and copy:
   - **Project URL**
   - **Anon/Public key**

### 4. Configure Environment

Edit the `.env` file in the project root:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 5. Install Dependencies & Run
```bash
cd lab_inventory
flutter pub get
flutter run -d windows    # or -d macos / -d linux
```

---

## 📁 Project Structure

```
lab_inventory/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── theme.dart                 # Colors, typography, constants
│   ├── models/
│   │   └── models.dart            # Data models (Equipment, Laboratory, etc.)
│   ├── services/
│   │   └── supabase_service.dart  # All Supabase API calls
│   ├── providers/
│   │   └── app_provider.dart      # State management (Provider)
│   ├── screens/
│   │   ├── dashboard_screen.dart  # Dashboard with charts
│   │   ├── equipment_screen.dart  # Equipment management
│   │   ├── borrowing_screen.dart  # Borrowing records
│   │   └── other_screens.dart     # Labs, Categories, Maintenance, Reports
│   └── widgets/
│       ├── sidebar.dart           # Navigation sidebar
│       └── common_widgets.dart    # Reusable UI components
├── .env                           # ⚠️ Add your Supabase credentials here
├── pubspec.yaml                   # Dependencies
└── supabase_schema.sql            # Run this in Supabase SQL Editor
```

---

## 🗄️ Database Schema

| Table | Description |
|-------|-------------|
| `laboratories` | Lab rooms with capacity |
| `categories` | Equipment categories |
| `equipment` | All inventory items |
| `borrowing_records` | Lending/return tracking |
| `maintenance_records` | Repair/maintenance logs |
| `suppliers` | Supplier information |

---

## 🎨 Tech Stack

- **Flutter** — Cross-platform desktop UI framework
- **Supabase** — PostgreSQL backend-as-a-service
- **Provider** — State management
- **fl_chart** — Charts and data visualization
- **google_fonts** — Inter font family
- **intl** — Date/number formatting

---

## 🔒 Security Notes

- Never commit your `.env` file to version control (add it to `.gitignore`)
- For production, configure proper Row Level Security (RLS) policies in Supabase
- Consider setting up Supabase Auth for multi-user access control

---

## 📸 Screens Overview

- **Dashboard** — Key metrics, pie chart for equipment status, recent borrowings
- **Equipment** — Searchable/filterable data table with full CRUD
- **Laboratories** — Card grid view of all labs
- **Categories** — Category management with item counts
- **Borrowing** — Status-filtered list with chip filters
- **Maintenance** — Maintenance schedule and history
- **Reports** — Analytics tables and visual summaries
