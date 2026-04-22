#!/usr/bin/env node
// @relation(INFRA-DSGN-1, scope=file)
import * as cdk from 'aws-cdk-lib/core';
import { PlatformStack } from '../lib/platform-stack';
import { DataStack } from '../lib/data-stack';
import { AppStack } from '../lib/app-stack';
import { AuthStack } from '../lib/auth-stack';
import { ControlPlaneStack } from '../lib/control-plane-stack';
import { IotStack } from '../lib/iot-stack';
import { TenantPlatformStack } from '../lib/tenant-platform-stack';
import { ControlPlaneDataStack } from '../lib/control-plane-data-stack';
import { FirmwareStack } from '../lib/firmware-stack';

const app = new cdk.App();

// Load global config
const globals = app.node.tryGetContext('globals');
if (!globals) {
  throw new Error('Context "globals" not found in cdk.context.json');
}

// @relation(INFRA-DSGN-2, scope=range_start)
if (globals.region !== 'ca-central-1') {
  throw new Error(`Region must be 'ca-central-1'. You attempted to use '${globals.region}'.`);
}
// @relation(INFRA-DSGN-2, scope=range_end)

const globalEnv = { account: globals.account, region: globals.region };

// Shared Stacks (Platform, Auth, Control Plane)
// These are deployed once and shared across environments

const platformStack = new PlatformStack(app, `HealthePlatformStack`, {
  env: globalEnv,
  baseDomain: globals.baseDomain,
  mqttSubdomain: 'mqtt'
});

const controlPlaneDataStack = new ControlPlaneDataStack(app, 'HealtheControlPlaneDataStack', {
  env: globalEnv,
});

const authStack = new AuthStack(app, 'HealtheAuthStack', {
  env: globalEnv,
  controlPlaneTable: controlPlaneDataStack.controlPlaneTable,
  baseDomain: globals.baseDomain,
});

const controlPlaneStack = new ControlPlaneStack(app, 'HealtheControlPlaneStack', {
  env: globalEnv,
  domainName: platformStack.controlPlaneDomainName,
  controlPlaneTable: controlPlaneDataStack.controlPlaneTable,
  adminCognitoJwksUrl: authStack.adminUserPoolJwksUrl,
  adminCognitoIssuer: authStack.adminUserPoolIssuer,
  adminGlobalGroup: authStack.adminGlobalGroupName,
});

const iotStack = new IotStack(app, `HealtheIotStack`, {
  env: globalEnv,
  controlPlaneTable: controlPlaneDataStack.controlPlaneTable,
  mqttDomain: platformStack.mqttDomain,
  mqttCertificateArn: platformStack.mqttCertificateArn,
  mqttWsCertificateArn: platformStack.mqttWsCertificateArn,
  mqttWsDomain: platformStack.mqttWsDomain,
});

const firmwareStack = new FirmwareStack(app, 'HealtheFirmwareStack', {
  env: globalEnv,
});

// Environment-specific Stacks (Data, App)
// These require an 'env' context (e.g. -c env=staging)

// @relation(INFRA-DSGN-4, scope=line)
const envKey = app.node.tryGetContext('env');

if (envKey) {
  // Load the specific config from cdk.context.json
  // @relation(INFRA-DSGN-3, scope=line)
  const envConfig = app.node.tryGetContext(envKey);

  if (!envConfig) {
    throw new Error(`Context for environment "${envKey}" not found in cdk.context.json`);
  }

  // Convert string "DESTROY"/"RETAIN" to actual CDK Enum
  const removalPolicy = envConfig.removalPolicy === 'DESTROY' 
    ? cdk.RemovalPolicy.DESTROY 
    : cdk.RemovalPolicy.RETAIN;

  // @relation(INFRA-DSGN-7, scope=range_start)
  const dataStack = new DataStack(app, `HealtheDataStack-${envKey}`, {
    env: globalEnv,
    removalPolicy: removalPolicy,
    environmentName: envKey,
  });
  // @relation(INFRA-DSGN-7, scope=range_end)

  const tenantPlatformStack = new TenantPlatformStack(app, `HealtheTenantPlatformStack-${envKey}`, {
    env: globalEnv,
    baseDomain: globals.baseDomain,
    subdomain: envConfig.subdomain || envKey,
    zone: platformStack.zone,
    removalPolicy: removalPolicy,
    environmentName: envKey,
  });

  const appStack = new AppStack(app, `HealtheAppStack-${envKey}`, {
    env: globalEnv,
    dsqlCluster: dataStack.clusterId,
    dsqlEndpoint: dataStack.clusterEndpoint,
    removalPolicy: removalPolicy,
    environmentName: envKey,
    domainName: tenantPlatformStack.domainName,
    adminUserPool: authStack.adminUserPool,
    adminCognitoJwksUrl: authStack.adminUserPoolJwksUrl,
    adminCognitoIssuer: authStack.adminUserPoolIssuer,
    adminGlobalGroup: authStack.adminGlobalGroupName,
  });

  // Apply config tags to environment stacks
  if (envConfig.tags) {
    for (const [key, value] of Object.entries(envConfig.tags)) {
      cdk.Tags.of(dataStack).add(key, value as string);
      cdk.Tags.of(tenantPlatformStack).add(key, value as string);
      cdk.Tags.of(appStack).add(key, value as string);
    }
  }
}

// Apply global tags
cdk.Tags.of(app).add("Organization", "Health-e")
cdk.Tags.of(app).add("Project", "PillOrganizer")
