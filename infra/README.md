# Infrastructure

[AWS CDK with TypeScript](https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-typescript.html) is used to define, deploy, and manage AWS infrastructure for the project.


## Environments

A command-line parameter switches between environments.
Environments generally refer to a tenant.
Define tenants in `cdk.context.json`.
Pass the `-c (tenant name)` flag to switch between tenants.
This flag is required for all CDK commands.

The environment (`${env}`) impacts the names of stacks (see below).

## Stacks

### HealthePlatformStack

**Note:** this stack is *shared* between environments.

This stack contains resources that don't change often, or that changing may have second- or third-order effects.
Updating this stack should be reserved for when absolutely necessary.
Preference should be to modifying HealtheAppStack instead to the highest extent possible.
Basically, resources defined here are to avoid "chicken and the egg" problems.
For example, we can't define an ECS service until we've pushed an image into ECR, but we can't do this until an ECR repository has been created.

* Defines VPC.
* Creates a container repository (ECR).
* Defines an ECS cluster.
* Sets up GitHub 

### HealtheAuthStack

**Note:** this stack is *shared* between environments.

This stack contains user authentication resources (AWS Cognito) shared between environments.
This stack should only be updated sparingly as it contains the Cognito user pools.
Changes to Cognito may result in a different user pool ID, client credentials, etc. 
Take care to review the diff before deploying changes.

* Defines Cognito user pool.
* Defines a separate Cognito admin user pool.
* Creates a fixed domain for the user pool.
* Creates a Cognito client for the mobile app (Flutter).
* Creates a Cognito client for admin web dashboards (hosted UI).
* Creates an `admin-global` group in the admin pool.
* Creates a default managed login.

### HealtheControlPlaneStack

**Note:** this stack is *shared* between environments.

This stack hosts the control plane, which is a resource shared between all tenants.

* Defines a Lambda function for the control plane, based on the "shadow" fat JAR produced by Micronaut in `backend/global/target`.
* Creates an API gateway for the control plane.
* Configures Route 53 for `control-plane.app.healthesolutions.ca` points to the control plane.
* Generates HTTPS certificates for the domain.

### HealtheDataStack-${env}

Defines persistent data storage.
This should also not be modified very often, as small changes may cause CDK to destroy and then recreate resources causing possible data loss.

* Creates PostgreSQL database credentials.
* Creates an RDS Aurora Serverless v2 (PostgreSQL) database.

### HealtheAppStack-${env}

AWS configuration to run the app itself.
This stack is designed to be changed often.

* Running containers (ECS).
* Network and IAM configuration for apps.
* IoT Core (future)
* SQS queues (future)

## Playbooks

### Prerequisites

* [Node.js](https://nodejs.org/en/download) and npm 
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Install CDK with `$ npm install -g aws-cdk`
* In `/infra` run `$ npm i`.

### Logging in to AWS

1. Run `$ aws configure sso`.
2. Enter a session name (e.g., sso-dc).
3. SSO start URL: https://designcatapult.awsapps.com/start
4. SSO region: `us-east-2`
5. Follow the link and sign in.
6. Default client Region: `ca-central-1`
7. Use the default profile name or set it to something. The default one looks like `AdministratorAccess-xxxxxx`.

Take note of the profile name.

### Deploying Changes

First, run `cdk diff` to preview changes you're applying:

`$ cdk diff $STACK_NAME-$ENV --profile $PROFILE_NAME -c env=$ENV`

**Example (HealtheAppStack staging environment):** `$ cdk diff HealtheAppStack-staging --profile AdministratorAccess-114829892869 -c env=staging`

**WARNING!** Carefully inspect the `diff` output to make sure the changes are what you're expecting. 
Sometimes even small changes can cause CDK to destroy and recreate certain resources. 

Then, deploy the changes with `cdk deploy`:

`$ cdk deploy $STACK_NAME-$ENV --profile $PROFILE_NAME -c env=$ENV`

**Example (HealtheAppStack production environment):** `$ cdk deploy HealtheAppStack-prod --profile AdministratorAccess-114829892869 -c env=prod`

If deployment fails, CDK will by default perform a rollback.

