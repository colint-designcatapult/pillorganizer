import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import { HttpLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';

interface ControlPlaneStackProps extends cdk.StackProps {
  baseDomain: string,
  zone: route53.IHostedZone
}

/* This stack configures the "control plane" backend. */
export class ControlPlaneStack extends cdk.Stack {
  public readonly postConfirmation: lambda.Function;
  public readonly preTokenGeneration: lambda.Function;

  createGlobalLambda(scope: Construct, id: string, handler: string, table: dynamodb.TableV2): lambda.Function {
    const func = new lambda.Function(scope, id, {
      runtime: lambda.Runtime.JAVA_21,
      handler: handler,
      code: lambda.Code.fromAsset("../backend/global/target/global-0.1.jar"),
      memorySize: 1024,
      timeout: cdk.Duration.seconds(30),
      snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
      environment: {
        'MICRONAUT_ENVIRONMENTS': 'global',
      },
    });
    table.grantReadWriteData(func);
    return func;
  }

  constructor(scope: Construct, id: string, props: ControlPlaneStackProps) {
    super(scope, id, props);

    const domainName = `control-plane.${props.baseDomain}`;

    const table = new dynamodb.TableV2(this, 'DeviceControlPlaneTable', {
      tableName: 'DeviceControlPlane',
      partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
      billing: dynamodb.Billing.onDemand(),
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      deletionProtection: true,
      globalSecondaryIndexes: [
        {
          indexName: 'GSI1',
          partitionKey: { name: 'GSI1_PK', type: dynamodb.AttributeType.STRING },
          sortKey: { name: 'GSI1_SK', type: dynamodb.AttributeType.STRING },
          projectionType: dynamodb.ProjectionType.ALL,
        },
        {
          indexName: 'GSI2',
          partitionKey: { name: 'GSI2_PK', type: dynamodb.AttributeType.STRING },
          sortKey: { name: 'GSI2_SK', type: dynamodb.AttributeType.STRING },
          projectionType: dynamodb.ProjectionType.ALL,
        }
      ]
    });

    // Create the Control Plane Lambda function using the shared utility
    const appFunction = this.createGlobalLambda(this, 'ControlPlaneAppFunction',
       'io.micronaut.function.aws.proxy.payload2.APIGatewayV2HTTPEventFunction', table);

    // Cognito triggers
    this.postConfirmation = this.createGlobalLambda(this, 'PostConfirmation',
       'jct.pillorganizer.global.function.CognitoPostConfirmationHandler', table);
    this.preTokenGeneration = this.createGlobalLambda(this, 'PreTokenGeneration',
       'jct.pillorganizer.global.function.CognitoPreTokenGenerationHandler', table);

    const version = appFunction.currentVersion;
    
    const alias = new lambda.Alias(this, 'ControlPlaneAppAlias', {
      aliasName: 'prod',
      version: version,
    });

    const certificate = new acm.Certificate(this, 'ControlPlaneCertificate', {
      domainName: domainName,
      validation: acm.CertificateValidation.fromDns(props.zone),
    });

    const dn = new apigwv2.DomainName(this, 'ControlPlaneDomainName', {
      domainName: domainName,
      certificate: certificate,
    });

    const api = new apigwv2.HttpApi(this, 'ControlPlaneHttpApi', {
      apiName: 'Control Plane',
      defaultIntegration: new HttpLambdaIntegration('ControlPlaneIntegration', alias),
      defaultDomainMapping: {
        domainName: dn,
      },
    });

    new route53.ARecord(this, 'ControlPlaneAliasRecord', {
      zone: props.zone,
      recordName: 'control-plane',
      target: route53.RecordTarget.fromAlias(new targets.ApiGatewayv2DomainProperties(dn.regionalDomainName, dn.regionalHostedZoneId))
    });
  }
}
