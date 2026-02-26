import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

interface PlatformStackProps extends cdk.StackProps {
  baseDomain: string
}

/* This stack is configures base AWS resources, and should only be for things 
   that change rarely. Think VPCs, ECR, ECS clusters etc. */
export class PlatformStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;
  public readonly zone: route53.IHostedZone;


  constructor(scope: Construct, id: string, props: PlatformStackProps) {
    super(scope, id, props);

    // Create VPC with minimal resources 
    this.vpc = new ec2.Vpc(this, 'AppVpc', {
      //
      // WARNING: changes to VPC may destroy dependent services!
      //
      maxAzs: 2,
      natGateways: 1,
    });

    this.zone = route53.HostedZone.fromLookup(this, 'HostedZone', {
      domainName: props.baseDomain
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
