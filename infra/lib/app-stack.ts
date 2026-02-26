import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import { HttpLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import { Construct } from 'constructs';

interface AppStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  dbCluster: rds.DatabaseCluster;
  dbProxy: rds.DatabaseProxy;
  removalPolicy: cdk.RemovalPolicy;
  environmentName: string;
  baseDomain: string;
  subdomain: string;
  zone: route53.IHostedZone;
}

/* This stack configures the actual application. */
export class AppStack extends cdk.Stack {
  public readonly api: apigwv2.HttpApi;

  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);

    const fullDomainName = `${props.subdomain}.${props.baseDomain}`;

    // -- Lambda --

    const appFunction = new lambda.Function(this, 'AppFunction', {
      runtime: lambda.Runtime.JAVA_21,
      handler: 'io.micronaut.function.aws.proxy.payload2.APIGatewayV2HTTPEventFunction',
      code: lambda.Code.fromAsset("../backend/tenant/target/tenant-0.1.jar"),
      memorySize: 1024,
      timeout: cdk.Duration.seconds(30),
      snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
      vpc: props.vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      environment: {
        MICRONAUT_ENVIRONMENTS: `tenant,${props.environmentName}`,
        DB_HOST: props.dbProxy.endpoint,
        DB_PORT: '5432',
        DB_NAME: 'pillorganizer'
      },
    });

    // -- IAM & Security --

    // Grant access to DB Secret
    props.dbCluster.secret?.grantRead(appFunction);

    // Allow access to RDS Proxy
    props.dbProxy.grantConnect(appFunction, 'postgres');

    // Manually create ingress rule to avoid cyclic dependency (DataStack -> AppStack)
    const ingressRule = new ec2.CfnSecurityGroupIngress(this, 'DbProxyIngress', {
      groupId: props.dbProxy.connections.securityGroups[0].securityGroupId,
      sourceSecurityGroupId: appFunction.connections.securityGroups[0].securityGroupId,
      ipProtocol: 'tcp',
      fromPort: 5432,
      toPort: 5432,
      description: 'Allow Lambda access to DB Proxy',
    });

    // Ensure the Lambda function waits for the ingress rule to be created
    // This is critical for SnapStart, as the app tries to connect to the DB during init
    (appFunction.node.defaultChild as lambda.CfnFunction).addDependency(ingressRule);

    // Micronaut must be able to list secrets
    // This isn't a security risk because listing doesn't imply access
    appFunction.addToRolePolicy(new iam.PolicyStatement({
      actions: ['secretsmanager:ListSecrets'],
      resources: ['*'], 
    }));

    // -- API Gateway --

    const version = appFunction.currentVersion;
    const alias = new lambda.Alias(this, 'AppAlias', {
      aliasName: `live-${props.environmentName}`,
      version: version,
    });

    const certificate = new acm.Certificate(this, 'AppCertificate', {
      domainName: fullDomainName,
      validation: acm.CertificateValidation.fromDns(props.zone),
    });

    const domainName = new apigwv2.DomainName(this, 'AppDomainNameV2', {
      domainName: fullDomainName,
      certificate: certificate,
    });

    this.api = new apigwv2.HttpApi(this, 'AppHttpApi', {
      apiName: `PillOrganizer Tenant Backend (${props.environmentName})`,
      defaultIntegration: new HttpLambdaIntegration('ControlPlaneIntegration', alias),
      defaultDomainMapping: {
        domainName: domainName,
      },
    });

    new route53.ARecord(this, 'AppAliasRecord', {
      zone: props.zone,
      recordName: props.subdomain,
      target: route53.RecordTarget.fromAlias(new targets.ApiGatewayv2DomainProperties(domainName.regionalDomainName, domainName.regionalHostedZoneId))
    });
  }
}
