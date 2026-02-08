# Flutter Web Project

This README explains **only how to run the project locally** so anyone can clone it and start it without confusion.

---

## Requirements

Before running the project, make sure you have:

- Flutter SDK installed
- Google Chrome installed nCheck Flutter installation:

```bash
flutter doctor
```

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/your-repo-name.git
```

### 2. Navigate to the project directory

```bash
cd your-repo-name
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the project (Web)

This project is configured to run on **Flutter Web** using Chrome.

```bash
flutter run -d chrome --web-port=5173
```

After running the command, open your browser and go to:

```
http://localhost:5173
```

---

## Notes

- Make sure Chrome is detected by Flutter (`flutter doctor`).
- If the port is already in use, change `--web-port` to another available port.

---

## Flutter Version

You can check the Flutter version used in this project by running:

```bash
flutter --version
```

