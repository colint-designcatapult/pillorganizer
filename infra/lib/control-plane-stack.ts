import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import { HttpLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { createGlobalLambda } from './lambda-utils';

interface ControlPlaneStackProps extends cdk.StackProps {
  domainName: apigwv2.IDomainName,
  controlPlaneTable: dynamodb.ITableV2,
  adminCognitoJwksUrl: string,
  adminCognitoIssuer: string,
  adminGlobalGroup: string,
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
    appFunction.addEnvironment('ADMIN_COGNITO_JWKS_URL', props.adminCognitoJwksUrl);
    appFunction.addEnvironment('ADMIN_COGNITO_ISSUER', props.adminCognitoIssuer);
    appFunction.addEnvironment('ADMIN_GLOBAL_GROUP', props.adminGlobalGroup);

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
    });
  }
}
