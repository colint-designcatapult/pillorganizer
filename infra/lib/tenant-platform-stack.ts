import * as cdk from 'aws-cdk-lib/core';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';

export interface TenantPlatformStackProps extends cdk.StackProps {
  baseDomain: string;
  subdomain: string;
  zone: route53.IHostedZone;
  removalPolicy: cdk.RemovalPolicy;
  environmentName: string;
}

/**
 * This stack configures environment-specific platform resources that are 
 * intended to be permanent (or at least have a longer lifecycle than the app).
 */
export class TenantPlatformStack extends cdk.Stack {
  public readonly domainName: apigwv2.DomainName;
  public readonly tenantThingGroupName: string;

  constructor(scope: Construct, id: string, props: TenantPlatformStackProps) {
    super(scope, id, props);

    const fullDomainName = `${props.subdomain}.${props.baseDomain}`;

    const certificate = new acm.Certificate(this, 'AppCertificate', {
      domainName: fullDomainName,
      validation: acm.CertificateValidation.fromDns(props.zone),
    });
    certificate.applyRemovalPolicy(props.removalPolicy);

    this.domainName = new apigwv2.DomainName(this, 'AppDomainNameV2', {
      domainName: fullDomainName,
      certificate: certificate,
    });
    this.domainName.applyRemovalPolicy(props.removalPolicy);

    new route53.ARecord(this, 'AppAliasRecord', {
      zone: props.zone,
      recordName: props.subdomain,
      target: route53.RecordTarget.fromAlias(new targets.ApiGatewayv2DomainProperties(this.domainName.regionalDomainName, this.domainName.regionalHostedZoneId))
    });

    const tenantThingGroup = new iot.CfnThingGroup(this, 'TenantThingGroup', {
      thingGroupName: props.environmentName,
    });
    tenantThingGroup.applyRemovalPolicy(props.removalPolicy);

    this.tenantThingGroupName = props.environmentName;

    // Tenant admin Cognito group
    const adminUserPoolId = this.node.tryGetContext('globals')?.adminUserPoolId;
    if (!adminUserPoolId) {
      throw new Error('Context "globals.adminUserPoolId" not found in cdk.context.json');
    }

    const tenantAdminGroup = `admin-tenant-${props.environmentName}`;
    new cognito.CfnUserPoolGroup(this, 'TenantAdminGroup', {
      groupName: tenantAdminGroup,
      userPoolId: adminUserPoolId,
      description: `Tenant admin role for ${props.environmentName}`,
    });
  }
}