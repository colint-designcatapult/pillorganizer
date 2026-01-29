#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib/core';
import { PlatformStack } from '../lib/platform-stack';
import { DataStack } from '../lib/data-stack';
import { AppStack } from '../lib/app-stack';

const app = new cdk.App();

const envKey = app.node.tryGetContext('env');
if (!envKey) {
  throw new Error('Please specify an environment context using -c env=staging or -c env=prod');
}

// Load the specific config from cdk.context.json
const envConfig = app.node.tryGetContext(envKey);

if (!envConfig) {
  throw new Error(`Context for environment "${envKey}" not found in cdk.context.json`);
}

// Convert string "DESTROY"/"RETAIN" to actual CDK Enum
const removalPolicy = envConfig.removalPolicy === 'DESTROY' 
  ? cdk.RemovalPolicy.DESTROY 
  : cdk.RemovalPolicy.RETAIN;

// Build standard env object based on config
const env = { account: envConfig.account, region: envConfig.region };

const platformStack = new PlatformStack(app, `HealthePlatformStack`, {
  env
});

const dataStack = new DataStack(app, `HealtheDataStack-${envKey}`, {
  env,
  vpc: platformStack.vpc,
  removalPolicy: removalPolicy,
  environmentName: envKey,
});

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