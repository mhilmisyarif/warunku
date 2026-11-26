# Warunku

Manage products, customers and customer debts for a small shop ("warung").

| Part | Folder | Stack |
|------|--------|-------|
| Mobile app | repository root (`lib/`, `test/`, platform folders) | Flutter, flutter_bloc |
| API | [`backend/`](backend/README.md) | Node.js, Express, MongoDB (Mongoose) |

## Run the API

```sh
cd backend
cp .env.example .env   # then set MONGO_URL for your MongoDB
npm install
npm run dev            # http://localhost:3000/api
```

Or with Docker: `cd backend && docker compose up`. Seed sample data with `npm run seed`.

## Run the app

```sh
flutter pub get
flutter run
```

The app calls `http://10.0.2.2:3000/api` by default, which is the host machine as
seen from the Android emulator. For a physical device or web, pass your machine's address:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/api
```

## Tests

```sh
flutter analyze && flutter test
```

## App structure

```
lib/
  config/     API base URL and image URL helper
  models/     JSON models (Product, Customer, DebtRecord)
  services/   ApiClient (HTTP, timeouts, errors) + one service per resource
  blocs/      product/, customer/ (app-wide) and debt/ (one instance per screen)
  screens/    product/, customer/, debt/
  widgets/    shared widgets
  utils/      theme and formatters
```
