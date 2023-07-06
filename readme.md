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


## Project Status

The entire CabiNET codebase is currently transitioning from rapid prototyping to production.
Many components were written as prototypes while requirements were still changing and the vision for the product was in flux.
There is a general effort project-wide to bring components into production-ready status through refactoring, but at this
time quality may be mixed.