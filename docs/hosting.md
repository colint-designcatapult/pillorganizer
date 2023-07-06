# Servers & Hosting Infrastructure

The backend (and its Postgres database) needs to be hosted somewhere in the cloud.
It's cloud-agnostic, we aren't tied to any particular provider and can switch fairly easily.

## Heroku

The backend is currently hosted on Heroku, using their container hosting platform.
It is accessible on the web from [jctbackend.herokuapp.com](https://jctbackend.herokuapp.com/).
A Docker image is created using Micronaut (see [Deploying](#deploying)) and uploaded to Heroku via the Heroku CLI.

This is a managed container hosting service.
There shouldn't be any need to do any sort of maintenance, etc.
There is an automatic health check that restarts the container if it goes down.

The backend is automatically built and deployed to Heroku on every push to master using Github Actions.
See `.github/workflows/backend.yml` for details.

### Logs

It may be helpful for debugging to view live logs as it is running in production.
In the top left corner of the dashboard, click "More" and select "View Logs".

### Database

We use Heroku's managed PostgreSQL addon.
The database credentials are automatically injected into our container.

## fly.io

The current tentative plan is to use fly.io for production.
Current phase is experimentation, we have no assets currently deployed to fly.io.
