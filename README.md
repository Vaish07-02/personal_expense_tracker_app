# Personal Expense Tracker

A Flutter-based mobile application that helps users record, organize,
and manage their daily expenses using Indian Rupees (INR).

## About the Project

Personal Expense Tracker is designed to make everyday expense tracking
simple and convenient. Users can record expenses, categorize spending,
and view their recorded expenses through a dashboard.

The application uses SQLite for local data storage.

## Features

- Add new expenses.
- Edit existing expenses.
- Delete expenses with confirmation.
- Categorize expenses.
- View total recorded expenses.
- View category-wise expense totals.
- View recent transactions.
- Store expense records locally using SQLite.
- Display amounts in Indian Rupees (₹).
- Responsive dashboard for phone and tablet screens.

## Technologies Used

- Flutter
- Dart
- SQLite
- sqflite
- Android Studio
- Git
- GitHub

## Project Structure

```text
personal_expense_tracker_app/
├── android/
├── lib/
│   ├── database/
│   │   └── database_helper.dart
│   ├── models/
│   │   └── expense.dart
│   ├── screens/
│   │   └── add_expense_screen.dart
│   └── main.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
├── pubspec.lock
└── README.md
