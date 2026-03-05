import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

interface PlatformStackProps extends cdk.StackProps {
  baseDomain: string;
  mqttSubdomain?: string;
}

/* This stack is configures base AWS resources, and should only be for things 
   that change rarely. Think VPCs, ECR, ECS clusters etc. */
export class PlatformStack extends cdk.Stack {
  public readonly zone: route53.IHostedZone;
  public readonly controlPlaneDomainName: apigwv2.IDomainName;

  public readonly mqttDomain: string;
  public readonly mqttCertificateArn: string;

  public readonly mqttWsDomain: string;
  public readonly mqttWsCertificateArn: string;


  constructor(scope: Construct, id: string, props: PlatformStackProps) {
    super(scope, id, props);

    this.zone = route53.HostedZone.fromLookup(this, 'HostedZone', {
      domainName: props.baseDomain
    });

    const cpDomainName = `control-plane.${props.baseDomain}`;

    const certificate = new acm.Certificate(this, 'ControlPlaneCertificate', {
      domainName: cpDomainName,
      validation: acm.CertificateValidation.fromDns(this.zone),
    });

    this.controlPlaneDomainName = new apigwv2.DomainName(this, 'ControlPlaneDomainName', {
      domainName: cpDomainName,
      certificate: certificate,
    });

    new route53.ARecord(this, 'ControlPlaneAliasRecord', {
      zone: this.zone,
      recordName: 'control-plane',
      target: route53.RecordTarget.fromAlias(new targets.ApiGatewayv2DomainProperties(this.controlPlaneDomainName.regionalDomainName, this.controlPlaneDomainName.regionalHostedZoneId))
    });

    // -- IoT Domain --

    const mqttSubdomain = props.mqttSubdomain || 'mqtt';
    const fullMqttDomainName = `${mqttSubdomain}.${props.baseDomain}`;
    this.mqttDomain = fullMqttDomainName;

    const mqttCertificate = new acm.Certificate(this, 'MqttCertificate', {
      domainName: fullMqttDomainName,
      validation: acm.CertificateValidation.fromDns(this.zone),
      allowExport: false
    });
    this.mqttCertificateArn = mqttCertificate.certificateArn;

    const endpoint = new cr.AwsCustomResource(this, 'IotEndpoint', {
      onCreate: {
        service: 'Iot',
        action: 'describeEndpoint',
        parameters: {
          endpointType: 'iot:Data-ATS',
        },
        physicalResourceId: cr.PhysicalResourceId.of('IotEndpoint'),
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE,
      }),
    });

    const iotEndpointAddress = endpoint.getResponseField('endpointAddress');

    new route53.CnameRecord(this, 'MqttCname', {
      zone: this.zone,
      recordName: mqttSubdomain,
      domainName: iotEndpointAddress,
      ttl: cdk.Duration.minutes(5),
    });

    // -- MQTT over Websocket --

    const mqttWsSubdomain = `ws-${mqttSubdomain}`;
    const fullMqttWsDomainName = `${mqttWsSubdomain}.${props.baseDomain}`;
    this.mqttWsDomain = fullMqttWsDomainName;

    const mqttWsCertificate = new acm.Certificate(this, 'MqttWsCertificate', {
      domainName: fullMqttWsDomainName,
      validation: acm.CertificateValidation.fromDns(this.zone),
      allowExport: false
    });
    this.mqttWsCertificateArn = mqttWsCertificate.certificateArn;

    new route53.CnameRecord(this, 'MqttWsCname', {
      zone: this.zone,
      recordName: mqttWsSubdomain,
      domainName: iotEndpointAddress,
      ttl: cdk.Duration.minutes(5),
    });

    // -- GitHub OIDC --
    
    // Used so IAM credentials aren't hard-coded in GitHub
    // ** todo: need to restrict resource access to this project only

    const provider = new iam.OpenIdConnectProvider(this, 'GithubOidc', {
      url: 'https://token.actions.githubusercontent.com',
      clientIds: ['sts.amazonaws.com'],
    });

    const githubRole = new iam.Role(this, 'GithubDeployRole', {
      assumedBy: new iam.WebIdentityPrincipal(provider.openIdConnectProviderArn, {
        StringLike: {
          'token.actions.githubusercontent.com:sub': 'repo:DesignCatapult/pillorganizer:*'
        },
      }),
      roleName: 'GitHubActionDeployRole', 
      description: 'Role assumed by GitHub Actions to deploy the app',
    });

    githubRole.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess'));
  }
}
