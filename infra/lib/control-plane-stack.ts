import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigw from 'aws-cdk-lib/aws-apigateway';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

interface ControlPlaneStackProps extends cdk.StackProps {
  baseDomain: string
}

/* This stack configures the "control plane" backend. */
export class ControlPlaneStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: ControlPlaneStackProps) {
    super(scope, id, props);

    const domainName = `control-plane.${props.baseDomain}`;

    const appFunction = new lambda.Function(this, 'ControlPlaneAppFunction', {
      runtime: lambda.Runtime.JAVA_21, 
      handler: 'io.micronaut.function.aws.proxy.MicronautLambdaHandler',
      code: lambda.Code.fromAsset("../backend/global/target/global-0.1.jar"), 
      memorySize: 1024,
      timeout: cdk.Duration.seconds(30),
      snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
      environment: {
        'MICRONAUT_ENVIRONMENTS': 'global', 
      },
    });

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

    table.grantReadWriteData(appFunction);

    const version = appFunction.currentVersion;
    
    const alias = new lambda.Alias(this, 'ControlPlaneAppAlias', {
      aliasName: 'prod',
      version: version,
    });

    const zone = route53.HostedZone.fromLookup(this, 'HostedZone', {
      domainName: props.baseDomain
    });

    const certificate = new acm.Certificate(this, 'ControlPlaneCertificate', {
      domainName: domainName,
      validation: acm.CertificateValidation.fromDns(zone),
    });

    const api = new apigw.LambdaRestApi(this, 'ControlPlaneApiGateway', {
      handler: alias, 
      proxy: true, 
      restApiName: 'Control Plane',
      domainName: {
        domainName: domainName,
        certificate: certificate,
        endpointType: apigw.EndpointType.REGIONAL,
      }
    });

    new route53.ARecord(this, 'ControlPlaneAliasRecord', {
      zone: zone,
      recordName: 'control-plane',
      target: route53.RecordTarget.fromAlias(new targets.ApiGatewayDomain(api.domainName!))
    });
  }
}
