import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigw from 'aws-cdk-lib/aws-apigateway';
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

    const version = appFunction.currentVersion;
    
    const alias = new lambda.Alias(this, 'ControlPlaneAppAlias', {
      aliasName: 'prod',
      version: version,
    });

    new apigw.LambdaRestApi(this, 'ControlPlaneApiGateway', {
      handler: alias, 
      proxy: true, 
      restApiName: 'Control Plane',
    });
  }
}
