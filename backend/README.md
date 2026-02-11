# Backend

The backend handles core server-side business logic, data persistence (CRUD), and provides an HTTP/REST API.
It's written in Java using the [Micronaut](https://micronaut.io/) framework.

## Dev Quick Start

### Prerequisites

* OpenJDK 21
  * The project uses [Amazon Corretto](https://docs.aws.amazon.com/corretto/latest/corretto-21-ug/downloads-list.html) for deployment but it doesn't matter too much what OpenJDK distribution is used for development.  
  * [Adoptium Temurin](https://adoptium.net/temurin/releases?version=21&os=any&arch=any) is known to work too. 
* [Apache Maven 3.9.x](https://maven.apache.org/install.html)
* [Podman](https://podman.io/) or [Docker](https://www.docker.com/products/docker-desktop/) (Desktop)
  * Podman - make sure you install the Compose and Docker extensions and go through the whole setup process.
  * Docker - should work but not tested.

### Start Dev Containers

* Use `$ docker-compose up -d` to start local development containers (Postgres, AWS/LocalStack) using Podman/Docker.
  * It may take a 30 seconds to 1 minute for all required services to finish initializing before Micronaut can start.
* Use `$ docker-compose down` to stop the dev containers. It's generally fine to leave them running for a long time. You only need to stop them if you want to save resources (free up RAM, etc).
* You can [configure IntelliJ](https://www.jetbrains.com/help/idea/docker-compose.html#create-docker-compose-run-configuration) to integrate `docker-compose` with the IDE.

### Run/Debug Locally

*Requires:* Start Dev Containers.

**With IntelliJ:** 
  * Open `/backend` in IntelliJ as a Maven project.
  * Add new **Run/Debug Configuration**.
    * Select type "Micronaut".
    * Main class: `jct.pillorganizer.tenant.TenantApplication`
    * Environment variables: `MICRONAUT_ENVIRONMENTS=local`

### Build & Test Locally

Does *not* require dev containers to be running -- uses testcontainers to automatically start containers during the Maven Surefire test run.

  * **Compile:** Use `compile` target in IntelliJ or run `$ mvn compile`.
  * **Test:** 
    * To run the full test suite, run the `test` target in IntelliJ or run `$ mvn test`.
    * You can run individual tests in IntelliJ by browing to the test file and using the run buttons.
  * **Build Container:** Run the `jib:buildTar` target in IntelliJ or run `$ mvn jib:buildTar`.
    * This will build a container image and place it in `target/jib-image.tar`.
    * You can import it into Podman/Docker using `$ [podman|docker] import target/jib-image.tar pillorganizer-backend:latest`.

## Cloud Deployment

The backend is deployed as a **container**.
The container image is based on the Amazon Corretto Docker image (`amazoncorretto:21`), which is a full Java 21 runtime environment optimized for deployment on AWS.

The container image is built using [Jib](https://github.com/GoogleContainerTools/jib) directly in the Maven build process.
There is no `Dockerfile`, the container is configured entirely in `pom.xml`.

The deployment into AWS is defined in AWS CDK in `/infra` and automatic deployments through GitHub Actions (`/.github/workflows/backend.yml`).
**DO NOT** deploy or make changes to AWS by clicking buttons in the dashboard (ClickOps) -- all changes must be through CDK or CI/CD.

## Environment, Configuration, Secrets

[Micronaut environments](https://docs.micronaut.io/latest/guide/#environments) are used to switch configurations and modify behaviors at runtime.

Environments are specified either via the `-Dmicronaut.environments=` JVM argument or `MICRONAUT_ENVIRONMENTS` environment variable.
Both accept comma-separated environment values, i.e. `-Dmicronaut.environments=foo,bar` activates both `foo` and `bar` environments.

The following environments are defined in the project (either explicitly or implicitly) and thus have an impact:

| Environment Name | Description |
| ---------------- | ----------- |
| `prod`           | Live production environment. To run in infra deployed by CDK prod stacks. |
| `staging`        | Staging cloud environment. Mirrors `prod` environment in an isolated staging environment. |
| `local`          | Local development use. Will try to connect to PostgreSQL and LocalStack as defined in `docker-compose.yml`. |
| `test`           | Automatically used by Micronaut when unit tests are run. Uses testcontainers (see below). |

### Environment Variables

See `src/main/resources/application.yml`. (todo: refine documentation)

### Secrets

Secrets are stored in AWS Secrets Manager and loaded by Micronaut via [micronaut-aws-secretsmanager](https://micronaut-projects.github.io/micronaut-aws/latest/guide/#distributedconfigurationsecretsmanager).

**Note:** some secrets are still defined in environment variables. There is ongoing effort to move them all to Secrets Manager.

Micronaut will load secrets from `/config/pillorganizer-backend_(environment)` and `/config/pillorganizer-backend`. 

* **Database Credentials.** `/config/pillorganizer-backend_(env)/database`.

## Runtime Dependencies

* PostgreSQL (primary data store)
* AWS Secrets Manager (loads database credentials)
* AWS SQS (IoT data ingest)
* AWS IoT Core (IoT shadow state access)

### Production Deployment

All resources are provided by AWS and defined in AWS CDK (`/infra`).

### Local Development

The `docker-compose.yml` file defines all local development resources.
[LocalStack](https://www.localstack.cloud/) is used to locally simulate AWS services except for PostgreSQL, which a separate container is defined in `docker-compose.yml`.

### Testing

[Testcontainers](https://testcontainers.com/) are used to automatically spin up runtime dependencies during testing.
This is automatically handled by the Maven build system.


### Changing Runtime Dependencies

If runtime dependencies are changed:
* Providion/modify cloud resources only via IaC (`/infra`). 
* Update `docker-compose.yml` and `init-aws.sh` to simulate cloud resources locally for development.
* Update `src/test/groovy/jct/pillorganizer/BaseIntegrationSpec.groovy` to simulate cloud resources locally during automated testing.
