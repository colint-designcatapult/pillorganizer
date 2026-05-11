import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import { HttpLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';
import { createGlobalLambda } from './lambda-utils';

interface ControlPlaneStackProps extends cdk.StackProps {
  domainName: apigwv2.IDomainName,
  controlPlaneTable: dynamodb.ITableV2,
  userPool: cognito.IUserPool,
}

/* This stack configures the "control plane" backend. */
export class ControlPlaneStack extends cdk.Stack {
  public readonly controlPlaneTable: dynamodb.ITableV2;

  constructor(scope: Construct, id: string, props: ControlPlaneStackProps) {
    super(scope, id, props);

    this.controlPlaneTable = props.controlPlaneTable;

    // Create the Control Plane Lambda function using the shared utility
    const appFunction = createGlobalLambda(this, 'ControlPlaneAppFunction',
       'io.micronaut.function.aws.proxy.payload2.APIGatewayV2HTTPEventFunction', this.controlPlaneTable);

    // Grant function ability to create provisioning claims
    appFunction.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['iot:CreateProvisioningClaim'],
      resources: [`arn:aws:iot:${this.region}:${this.account}:provisioningtemplate/TenantDeviceProvisioningTemplate`],
    }));

    // Grant function ability to manage SNS platform endpoints and subscribe devices
    appFunction.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'sns:CreatePlatformEndpoint',
        'sns:SetEndpointAttributes',
      ],
      resources: [
        `arn:aws:sns:${this.region}:${this.account}:app/GCM/HealtheCabinetAndroid`,
        `arn:aws:sns:${this.region}:${this.account}:endpoint/GCM/HealtheCabinetAndroid/*`,
      ],
    }));

    appFunction.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'sns:Subscribe',
        'sns:Unsubscribe',
      ],
      resources: [
        `arn:aws:sns:${this.region}:${this.account}:device-*`,
      ],
    }));

    // Grant read-only access to the Cognito admin user pool for listing users and groups
    appFunction.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'cognito-idp:ListUsers',
        'cognito-idp:ListUsersInGroup',
        'cognito-idp:AdminListGroupsForUser',
      ],
      resources: [
        `arn:aws:cognito-idp:${this.region}:${this.account}:userpool/*`,
      ],
    }));

    // Grant permission to delete users from the normal (public) user pool
    appFunction.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'cognito-idp:AdminDeleteUser',
      ],
      resources: [
        props.userPool.userPoolArn,
      ],
    }));

    const version = appFunction.currentVersion;
    
    const alias = new lambda.Alias(this, 'ControlPlaneAppAlias', {
      aliasName: 'prod',
      version: version,
    });

    new apigwv2.HttpApi(this, 'ControlPlaneHttpApi', {
      apiName: 'Control Plane',
      defaultIntegration: new HttpLambdaIntegration('ControlPlaneIntegration', alias),
      defaultDomainMapping: {
        domainName: props.domainName,
      },
      corsPreflight: {
        allowHeaders: ['*'],
        allowMethods: [apigwv2.CorsHttpMethod.ANY],
        allowCredentials: true,
        exposeHeaders: ['*'],
        allowOrigins: ['https://admin.app.healthesolutions.ca', 'http://localhost:4200'],
      },
    });
  }
}
