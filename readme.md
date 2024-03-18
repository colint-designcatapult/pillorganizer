# CabiNET

Welcome to the CabiNET monorepo! All project code lives in here, broken into multiple subdirectories:

- **/app**: mobile app
- **/backend**: backend web/api server
- **/firmware**: firmware that runs on the actual pill organizer (temporarily moved out of monorepo)

See [architecture](#architecture) for a general overview of how the project works.

## Subcomponent Overview

Please view the appropriate pages for in-depth documentation on each component.

### App

The mobile app is written in [Dart](https://dart.dev/) using the [Flutter framework](https://flutter.dev/).
Primary rationale for picking this stack was for ease of cross-platform development, relative maturity of the platform,
and quality community extensions.

The app is generally "dumb". It is a window and a conduit to the backend. All information shown in the app comes
directly from the backend server, even if pill organizers are connected to Bluetooh. Information is pulled from the
server via HTTP, and "live" data is achieved via polling.

See [app documentation](#app).

### Backend

The backend server hosts the API, which physical pill organizers and the mobile app interact with.
It serves as the "source of truth" for all devices, and records all events, manages scheduling, and more.
It is written in Java using the [Micronaut framework](https://micronaut.io/).
Micronaut was picked because it is lightweight, very fast, and enables rapid development of APIs.
Persistence is provided by `micronaut-hibernate-jpa`. The database is PostgreSQL.

The backend is currently hosted on Heroku. As of writing, effort is being made to move to fly.io for production, and use
Heroku for staging/testing.

See [backend documentation](#backend).

### Firmware

The firmware is the software that runs on the pill organizer devices.
It handles all of the business logic that runs on-device, such as lighting LEDs and tracking bins.

See [firmware documentation](#firmware).

## How to run the app

Make sure you are in the `/app` folder and run

`flutter run`

## How to debug the app

In flutter use devtools to debug and you can run the backend using the application.yml dev or staging env that are on 1password.

To debug the firmware, you need to have a dongle like [this](https://www.digikey.ca/en/products/detail/ftdi,-future-technology-devices-international-ltd/C232HD-DDHSP-0/2767783?utm_adgroup=&utm_source=google&utm_medium=cpc&utm_campaign=PMax%20Shopping_Product_New%20Customer%20Acquisition&utm_term=&productid=2767783&utm_content=&utm_id=go_cmp-19909744982_adg-_ad-__dev-c_ext-_prd-2767783_sig-EAIaIQobChMIsM2G04-NhAMVwmRHAR37ZgWeEAQYBiABEgId1PD_BwE&gad_source=1&gclid=EAIaIQobChMIsM2G04-NhAMVwmRHAR37ZgWeEAQYBiABEgId1PD_BwE) that has a txd, rxd, rts, dtr and gnd wire. Install [serial](https://www.decisivetactics.com/products/serial/) and select your usb connected.

## Where to find the .env vars

All the secret environment are on 1password in cabinet's vault and here is the [link to the .env]
(https://start.1password.com/open/i?a=J352PGC7N5ACRJA4MDQNW7BE3E&v=jorc3i6o3zcctg3ydelxq37nhu&i=dskch72fuvha7n6dpdsx5gek2a&h=team-thirdbridge.1password.com)

## Technical limitations

None

## Known problems

None

## External documentation

[Postman api](https://thirdbridge.postman.co/workspace/TGV~ee0876e3-a58a-4671-8bac-8bc0ef0f2015/collection/26916446-9452a619-cee0-4d56-a52f-4698796c76a1?action=share&creator=26916446&active-environment=25728846-65a0e86a-dbe5-4351-82fe-ae6e904ffde8)

## How to deploy application

Change app version in `app/pubspec.yaml`

Run
`flutter build ios --release` and `flutter build appbundle --release`
then manually publish these files on the app store connect and the android store

Backend is run via github actions

Firmware need to follow the OTA protocol in the `cabinet_docs.pdf` also the github actions will build the right folder for it.

## More documentation

Go in the `/docs` folder in the root to see the `cabinet_docs.pdf` and other document.
