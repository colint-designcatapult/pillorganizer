# App

The app is written in Dart using the Flutter Framework.

## General design

The app generally follows a typical Flutter app directory structure.
Here's a brief overview:

- **`/api`** models, repositories, providers, and the API client live in here.
  - `api.dart` is where the API client and DTO classes live.
  - `[...].dart` contain models, repositories, and providers for a particular subset of the API (think devices, medications, etc).
  - `provision.dart` contains all the business logic for provisioning a new device
- **`/l10n`** localization files (for translations) - only English is supported right now
- **`/platform`** utility widgets to implement a behavior that has the native look and feel for either Android or iOS
- **`/proto`** contains the generated protocol buffer files, generated from `pill.proto` (used for Bluetooth sync)
- **`/provider`** providers that aren't related to accessing the API
- **`/screens`** pages in the app
  - `auth/` login/create account/invite code pages
  - `device_settings/medication/medication_entry_wizard.dart` contains medication entry/edit wizard (in this weird folder because this used to be a part of a now-removed device settings page)
  - `my_account/my_account.dart` contains the "my account" page (sign out/sign up)
  - `first_launch.dart` This is the first screen that loads every time a user opens the app.
    It checks to see if the user is signed in already, immediately switching to the `index` page.
    If not, it prompts for options (setup new device, sign in, etc).
  - `index.dart` the home page for the app, when a user is signed in. They see their device here.
  - `post_setup_wizard.dart` screens that run after a device has just been provisioned (asking them to create an account, add medications, set times, etc).
  - `provision.dart` screen to guide the user through provisioning (setting up a new device)
- **`/service`** general utility/service classes
- **`/widgets`** general reusable widgets

### API client

The app uses [retrofit](https://pub.dev/packages/retrofit) to automatically generate an API client that makes HTTP requests.
Client functions are defined declarative using annotations (see retrofit docs).

The client has two filters that intercept every request:

- The `JwtAuthInterceptor` adds the `Authorization: Bearer` token to all HTTP requests (if a token exists).
  If the token is expired, the interceptor will attempt to sign in again and acquire another authentication token.
- The `ProblemJsonInterceptor` automatically decodes [Problem JSON](https://datatracker.ietf.org/doc/html/rfc7807)
  bodies from failed HTTP requests. Note that due to some bugs in Dio (the underlying HTTP library), this isn't always
  reliable.

The client is a global variable, access it with `client` (type `RestClient` in `api.dart`).

### Repositories & DTOs

Data from the API is received in JSON form as produced by the backend.
However, this may not be the most efficient format for us to use the data within the app.
JSON data is read in from the API into `[...]DTO` objects, which are then mapped into our actual model object.
For example, a schedule is deserialized into a `SimpleScheduleDTO`, which is then mapped into a `SimpleSchedule` object using the `SimpleSchedule.fromDTO` factory (manual process, use something like [auto_mappr](https://pub.dev/packages/auto_mappr) in the future?).
If the structure can be serialized to be sent back to the API, a static method `toDTO` is provided.

**Repositories** encapsulate the logic for fetching data and converting to and from DTOs.
For example, `ScheduleRepository` provides functions to get a dispense time by ID, which fetches the simple schedule from the backend and automatically converts it into a `SimpleSchedule`.

Current best practices for data flow generally have only providers calling repository methods.
This best practice was not established until late into the development cycle, so this may not be followed everywhere.
Effort should be made to ensure the data flows properly, since direct access to repositories undermines dependency notification.

### State management

The project went through a couple of different state management patterns, starting with simple stateful widgets, Bloc,
to finally [providers](https://pub.dev/packages/provider) using only stateless widgets.
There is a mix state management patterns in the codebase, but all modern code should use providers with stateless widgets.
There is also a mix of how data flows through providers, this is also an area that is being worked on.

`freezed` is used to enforce immutability.

### flutter_esp_ble_prov

The code to provision the WiFi credentials on the firmware is provided by the extension `flutter_esp_ble_prov`.
The stock extension does not provide calling a custom endpoint, so we maintain a fork of the extension in the source tree.
We call custom endpoints with `customEndpoint`.

Maintaining a separate fork is a maintenance burden, and we should probably just contribute our changes upstream.

### flutter_blue_plus

Needed to use a local copy of the library to disable the two notifications that we get when starting onboarding on ios. This is the problem and fix added: https://github.com/boskokg/flutter_blue_plus/issues/119 in FlutterBluePlusPlugin.m changing self.centralManager to disable the second notification.

## Building, Deploying, and CI/CD

Make sure generated sources (.freezed.dart, .g.dart) are up-to-date with `dart pub run build_runner build`.
The app is then built using the standard Flutter toolchain, i.e., `flutter build`.

### CI/CD

We use Github Actions to automatically build the app for Android.
The iOS app is built in Xcode Cloud.
The Android actions runner runs on a Mac Mini located at Brendan's house that has a tendency to go to sleep and stop
responding - it is not set up for other developers to use - sorry!

### Deploying

#### Apple TestFlight

We currently use TestFlight to distribute the app on iOS.
There are two testing tracks, internal and external testing.
The internal testing list is for development versions and has a small distribution list.
The external testing track can be accessed by anyone with a [link to join](https://testflight.apple.com/join/LNereCZK).

Xcode Cloud is configured to automatically distribute builds to internal testing.

#### Google Play Store

We currently deploy our app to the Play Store using the Internal and Closed testing tracks.
The Internal testing track is for development versions (small distribution list - Design Catapult, Pier-Luc, etc).
The Closed testing track has a wider group of testers set up for focus group testing.
So the "closed" track is equivalent to our production environment.

The signing key is located at `app/android/app/brendan.jks`, **this should be rekeyed before production** and done properly.

Anyone can join the closed testers list by joining the [cabinet-testers](https://groups.google.com/g/cabinet-testers) Google Group.
