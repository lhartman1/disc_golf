# Disc Golf

This is a Flutter app for keeping score of a Disc Golf (or regular Golf) match. It allows multiple players on their own devices to join the same game and update their scores throughout the match. Players join a game via a QR code that is created on one device and scanned on the other devices. Firebase Cloud Firestore is used for the database because it easily allows for each device to keep data in sync in real time.

This project also uses Firebase Authentication for user accounts and Firebase Cloud Storage for storing user account images.

## Getting Started

### Android
- Add an Android app to your Firebase project.
- Firebase will provide a file named `google-services.json`. Place this file in [android/app](android/app).

### Web
- Add a web app to your Firebase project.
- Copy the configuration provided by Firebase to [web/firebase-config.js.TEMPLATE](web/firebase-config.js.TEMPLATE) and rename it to [web/firebase-config.js](web/firebase-config.js).
