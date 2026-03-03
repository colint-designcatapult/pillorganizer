# app

JCT Pill Organizer App

## Getting Started

You need to [install Flutter](https://docs.flutter.dev/get-started/install)

Make sure you are in the `/app` folder and run

`flutter run`

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Code Generation

This project uses code generation for freezed, json_serializable, and retrofit.
The project will not build successfully until you manually run code generation.

To generate code, run:

`dart run build_runner build --delete-conflicting-outputs`

This is required every time you modify a file that uses code generation (ends in `.g.dart` or `.freezed.dart`).

There is also a dev command that will automatically generate code when you save a file:

`dart run build_runner watch --delete-conflicting-outputs`

This command will run in the background and automatically generate code when you save a file.
It will also watch for changes in the `lib/api` folder and regenerate code when needed.