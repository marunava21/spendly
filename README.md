![alt text](<Spendly Final.gif>)
# Spendly

I built Spendly because I wanted a simpler, smarter way to track my finances without spending hours entering data manually. It's a personal finance tracker built with Flutter that lets you manage your daily expenses, keep track of who owes you money (and who you owe), and monitor your investments all in one place. 

The coolest part is that you can just toss it a PDF of your bank statement, and it uses Gemini to parse out all your debits and turn them into structured records. No more typing out long receipts.

## Features

![Spendly Showcase](showcase/showcase.gif)

- **Multi-type tracking**: Keep tabs on standard expenses, investments, and IOUs.
- **AI statement parsing**: Upload a PDF bank statement, and the app uses Gemini 1.5 Pro to extract the transactions automatically.
- **CSV & text parsing**: You can also paste raw text or import a CSV. The built-in parser guesses the categories and dates.
- **Bulk import review**: Before anything gets saved to your database, you get a staging screen to review, edit, and categorize everything.
- **Calendar & analytics**: Check your spending daily, weekly, or monthly, and see it laid out on a calendar.

## Why I built this

I was tired of juggling multiple apps for budgeting, splitting bills with friends, and watching my investments. Most trackers either had way too many features I didn't need or completely lacked the ability to parse my local bank statements accurately. I wanted something clean that just worked, especially when it came to importing data. Wiring up Gemini to handle the PDF parsing was a fun experiment that turned out to be incredibly practical for cutting down manual data entry.

## Installation

You'll need Flutter installed on your machine.

1. Clone the repository:
   ```bash
   git clone https://github.com/marunava21/spendly.git
   ```
2. Navigate into the directory and grab the dependencies:
   ```bash
   cd spendly
   flutter pub get
   ```
3. Set up your environment variables. Create a `.env` file in the root directory and add your Gemini API key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

## Usage

To run the app locally on your emulator or device:

```bash
flutter run
```

If you want to run the unit tests (which cover the custom statement parsing and categorization logic):

```bash
flutter test
```
