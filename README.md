# Disc Golf

This is a Flutter app for keeping score of a Disc Golf (or regular Golf) match. It allows multiple players on their own devices to join the same game and update their scores throughout the match. Players join a game via a QR code that is created on one device and scanned on the other devices. Firebase Cloud Firestore is used for the database because it easily allows for each device to keep data in sync in real time.

This project also uses Firebase Authentication for user accounts and Firebase Cloud Storage for storing user account images.

## Getting Started

To run this with your own Firebase account, make sure to put the `google-services.json` file in [android/app](android/app).
