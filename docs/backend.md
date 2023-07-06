# Backend

The backend API server is written in Java using the Micronaut framework.

It is a web server, but only serves API requests (there are no "views" or templates).

**WARNING:** the backend has not gone through an exaustive security audit of all endpoints and thus is **not production ready**.

## Database

PostgreSQL is the main database for this project.
Effort was made to avoid Postgres-specific features but there's no strong rationale anymore.
Generally, constraints are avoided to enable more rapid development.

The backend only interacts with the database through the framework's Hibernate integration.
The Hibernate session is never used directly, only through the framework's repository classes.

Migrations are handled by Flyway with the files in `resources/db.migration`.
They can create the schema on a clean database.

## AuthN & AuthZ

(see the [section below](#consuming-the-api))

Authentication is provided by Micronaut Security.
The backend has 3 different authentication providers for each user type.

BCrypt is used for password hashing (see AuthService).

We also use annotation-based ABAC to authorize a specific user to a specific resource.
There is currently only one such annotation: `@DeviceABAC`. 
This annotation ensures that the currently logged-in user has access to a specific device.

## Device State Transitions

(see `DeviceStateJob`).

The backend is responsible for monitoring **all** bin states for every device in the system.
To send accurate push notifications and to accurately manage state on the backend, the backend transitions bin state statuses when appropriate.

Every ten seconds, the following is run: 

* Bin statuses that are "PENDING" that are due to be taken are moved to "TAKE NOW".
* Bin statuses that are "TAKE NOW" and it's been longer than 10 minutes since scheduled are moved to "MISSED".

Each one of these state transitions fires off a push notification.

**Note that because there is no mutual exclusion on the state job, the backend is unsuitable for more than one instance running at any given time**.
This must be fixed before production.

## Building, Deploying, and CI/CD

The backend uses the Maven build system.
The backend can be built (for testing) with `mvn package`.

### CI/CD

Github Actions are used for CI/CD, located in the `backend.yml` workflow file.
It is configured to automatically build and deploy the backend to production on every push to the Github repository.
Each release is tested to make sure it compiles and passes some automated regression testing.

### Deploying

Micronaut supports Docker packaging, which is quite convenient.
We use the default configuration Micronaut provides for us, so we don't have a Dockerfile.
A Docker image is built with `mvn --batch-mode --update-snapshots package -Dpackaging=docker`.
We push this Docker image directly to the cloud provider.

#### Environment Variables

A number of environment variables are required for operation. 

* DB_DATABASE
* DB_HOSTNAME
* DB_PASSWORD
* DB_PORT
* DB_USERNAME
* FIREBASE_CLIENT_EMAIL
* FIREBASE_PRIVATE_KEY
* FIREBASE_PROJECT_ID
* PORT (port to bind HTTP)
* SIGNING_JWK (used to protect JWT)

Secrets are typically stored in the hosting provider's secret store.

### Automated Testing

Put simply, the backend is not *unit* tested.
There are, however, a battery of automated tests against certain components known to cause breakage and regressions.
Maven Surefire kicks off a Spock spec test (currently there's only one: UserOnboardSpec).
The tests use an HTTP client and call the HTTP endpoints directly.

Testcontainers are used to automatically spin up a real Postgres database on the testing machine to test against.
All of this should happen automatically by Maven.

## Consuming the API

The API has auto-generated OpenAPI/Swagger documentation.

### User Types

The backend has 3 different user types for authentication and authorization.

* Users (standard users) have a username and password. 
   These are accounts are explicitly created by an actual human user.
   They have an email and a password.
* Anonymous users are created generally without the human user realizing it.
   It is designed for mobile app users who don't want to explicitly create an account.
* Device users are actual pill organizer devices.
   They use a shared secret, generated during provisioning, to log in.
   Their access is restricted to only API resources a device should use.

### Authentication

Most API endpoints are authenticated.

* As a standard user, login at `/api/v1/auth/login` with your email and password (JSON).
* As an anonymous user, login at `/api/v1/auth/login_anonymous` with your ID and secret (JSON).
* As a device, login at `/api/v1_2/device/auth` with a protobuf `AuthorizeRequest`.

All of these endpoints return a JWT token.
Present a JWT token in the "Authorization" header when making requests. 
It is your responsibility as an API consumer to store your JWT token securely - the backend doesn't use cookies.

