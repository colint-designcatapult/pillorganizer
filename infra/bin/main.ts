#!/usr/bin/env node
// @relation(INFRA-DSGN-1, scope=file)
import * as cdk from 'aws-cdk-lib/core';
import { PlatformStack } from '../lib/platform-stack';
import { DataStack } from '../lib/data-stack';
import { AppStack } from '../lib/app-stack';
import { AuthStack } from '../lib/auth-stack';
import { ControlPlaneStack } from '../lib/control-plane-stack';

const app = new cdk.App();

// @relation(INFRA-DSGN-4, scope=line)
const envKey = app.node.tryGetContext('env');
if (!envKey) {
  throw new Error('Please specify an environment context using -c env=staging or -c env=prod');
}

// Load the specific config from cdk.context.json
// @relation(INFRA-DSGN-3, scope=line)
const envConfig = app.node.tryGetContext(envKey);

if (!envConfig) {
  throw new Error(`Context for environment "${envKey}" not found in cdk.context.json`);
}

// @relation(INFRA-DSGN-2, scope=range_start)
if (envConfig.region !== 'ca-central-1') {
  throw new Error(`Region must be 'ca-central-1'. You attempted to use '${envConfig.region}'.`);
}
// @relation(INFRA-DSGN-2, scope=range_end)

// Convert string "DESTROY"/"RETAIN" to actual CDK Enum
const removalPolicy = envConfig.removalPolicy === 'DESTROY' 
  ? cdk.RemovalPolicy.DESTROY 
  : cdk.RemovalPolicy.RETAIN;

// Build standard env object based on config
const env = { account: envConfig.account, region: envConfig.region };


const platformStack = new PlatformStack(app, `HealthePlatformStack`, {
  env,
  crossRegionReferences: true,
  baseDomain: envConfig.baseDomain
});

const authStack = new AuthStack(app, 'HealtheAuthStack', {
  env,
  baseDomain: envConfig.baseDomain
});

const controlPlaneStack = new ControlPlaneStack(app, 'HealtheControlPlaneStack', {
  env,
  baseDomain: envConfig.baseDomain
});

// @relation(INFRA-DSGN-7, scope=range_start)
const dataStack = new DataStack(app, `HealtheDataStack-${envKey}`, {
  env,
  vpc: platformStack.vpc,
  removalPolicy: removalPolicy,
  environmentName: envKey,
});
// @relation(INFRA-DSGN-7, scope=range_end)

const appStack = new AppStack(app, `HealtheAppStack-${envKey}`, {
  env,
  ecr: platformStack.backendContainer,
  ecsCluster: platformStack.backendEcsCluster,
  dbCluster: dataStack.dbCluster,
  vpc: platformStack.vpc,
  removalPolicy: removalPolicy,
  environmentName: envKey
});

// Apply global tags
cdk.Tags.of(app).add("Organization", "Health-e")
cdk.Tags.of(app).add("Project", "PillOrganizer")

// Apply config tags
if (envConfig.tags) {
  for (const [key, value] of Object.entries(envConfig.tags)) {
    cdk.Tags.of(app).add(key, value as string);
  }
}