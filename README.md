# Disc Golf

This is a Flutter app for keeping score of a Disc Golf (or regular Golf) match. It allows multiple players on their own devices to join the same game and update their scores throughout the match. Players join a game via a QR code that is created on one device and scanned on the other devices. Firebase Cloud Firestore is used for the database because it easily allows for each device to keep data in sync in real time.

This project also uses Firebase Authentication for user accounts and Firebase Cloud Storage for storing user account images.

## Demo

https://user-images.githubusercontent.com/4906016/129418146-a14e3aa6-ea8d-404e-8757-2bb616bcab71.mp4

## Getting Started

### All Platforms

- Run `flutter pub run build_runner build` to create generated dart files.
  - This uses [json_serializable](https://pub.dev/packages/json_serializable) to automate serializing data to/from JSON for files in [lib/models](lib/models).

### Android
- Add an Android app to your Firebase project.
- Firebase will provide a file named `google-services.json`. Place this file in [android/app](android/app).

### Web
- Add a web app to your Firebase project.
- Copy the configuration provided by Firebase to [web/firebase-config.js.TEMPLATE](web/firebase-config.js.TEMPLATE) and rename it to [web/firebase-config.js](web/firebase-config.js).
- [Enable cross-origin access (CORS)](https://firebase.google.com/docs/storage/web/download-files#cors_configuration) for Firebase Storage so that the web app can access the stored images.
  - **OR**: run/build with `--web-renderer html` because the [html renderer can load cross-origin images without extra configuration](https://flutter.dev/docs/development/platform-integration/web-images#cross-origin-images).
