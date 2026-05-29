# Spendly 💸

Spendly is a modern, intelligent, and feature-rich personal finance tracker built with Flutter. It helps you manage your expenses, track IOUs, monitor investments, and effortlessly import bank statements using AI.

## 🚀 Key Features

### 1. Smart Transaction Management
- **Multi-Type Transactions**: Support for standard `expenses`, `investments`, money you `owe`, and money you are `owed`.
- **Categorization**: Auto-guess categories for imports and manual categorized entries (Food, Transport, Bills, Shopping, etc.).
- **Multi-Currency Support**: Record transactions with different currencies and conversion rates.
- **Invoice Attachments**: Attach invoice or receipt paths to your expense records.

### 2. AI-Powered Statement Parsing
- **PDF Bank Statements**: Upload your bank statements in PDF format and let the **Gemini 1.5 Pro** Generative AI model automatically extract your debit transactions.
- **CSV & Raw Text Parsing**: Paste raw statement text or import CSVs, and let the robust built-in `StatementParser` extract dates, amounts, categories, and descriptions.
- **Bulk Import Review**: A comprehensive review screen allows you to select, edit, and bulk-import AI-parsed transactions into your database. 

### 3. Comprehensive Analytics & Views
- **Date Filters**: View your expenses on a Daily, Weekly, or Monthly basis.
- **Calendar Integration**: A beautiful calendar view highlighting daily spendings, IOUs, and investments.
- **Search Capabilities**: Instantly find past transactions by searching descriptions/payees.

## 🏗 Workflow & Architecture

Spendly relies on a clean, scalable architecture using the `provider` package for state management. 

### Core Workflow
1. **Adding Transactions**:
   - **Manual Entry**: Users can add transactions manually, selecting type (Expense, Invest, I Owe, Owed), date, category, and amount.
   - **AI Import**: Users upload a PDF. `GeminiParser` sends it to the Gemini API, returning a JSON array of parsed debit transactions.
   - **Text/CSV Import**: Users input raw text/CSV. `StatementParser` reads line-by-line, predicting categories and dates.
2. **Reviewing Imports**:
   - The `ImportReviewScreen` displays all parsed transactions. Users can tweak amounts, dates, types, and categories, or deselect incorrect entries. 
   - Upon confirmation, bulk entries are mapped to `Expense` models and saved to the local database via `ExpenseRepository`.
3. **State Management**:
   - `ExpenseProvider` acts as the source of truth, loading data, caching daily/monthly totals, and exposing them to the UI.
   - `CategoryProvider` supplies the list of available categories (with colors and icons).

### Key Components

- **`Expense` (Model)**: The central data model holding all transaction metadata (amount, currency, type, participants, date, etc.).
- **`ExpenseProvider` (State)**: Manages UI state, filtering logic, calendar data, and communicates with the repository.
- **`GeminiParser` (Utility)**: Interfaces with `google_generative_ai` for AI-based PDF parsing.
- **`StatementParser` (Utility)**: A robust string and regex-based parser for dates, amounts, and automatic categorization.
- **`ImportReviewScreen` (UI)**: The staging ground for finalizing AI/CSV extracted transactions.

## 🛠 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/marunava21/spendly.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Environment Setup**:
   - Create a `.env` file in the root directory.
   - Add your Gemini API Key: `GEMINI_API_KEY=your_api_key_here`.
4. **Run the App**:
   ```bash
   flutter run
   ```

## 🧪 Testing
Run the unit tests to verify parsing logic and other utilities:
```bash
flutter test
```

---
*Built with ❤️ using Flutter.*
