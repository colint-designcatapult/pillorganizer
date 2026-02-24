import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import { Construct } from 'constructs';

interface PlatformStackProps extends cdk.StackProps {
  baseDomain: string
}

/* This stack is configures base AWS resources, and should only be for things 
   that change rarely. Think VPCs, ECR, ECS clusters etc. */
export class PlatformStack extends cdk.Stack {
  public readonly backendContainer: ecr.Repository;
  public readonly backendEcsCluster: ecs.Cluster;
  public readonly vpc: ec2.Vpc;
  public readonly userPool: cognito.UserPool;

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

    // Create container repository
    this.backendContainer = new ecr.Repository(this, 'BackendRepository', {
      repositoryName: 'pillorganizer-backend',
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      emptyOnDelete: false
    });

    // Create backend ECS cluster
    // @relation(INFRA-DSGN-10, scope=range_start)
    this.backendEcsCluster = new ecs.Cluster(this, 'BackendCluster', {
      vpc: this.vpc,
    });
    // @relation(INFRA-DSGN-10, scope=range_end)

    // -- Cognito User Pool --
    this.userPool = new cognito.UserPool(this, 'HealtheUserPool', {
      userPoolName: 'healthe-userpool',
      selfSignUpEnabled: true,
      standardAttributes: {
        email: {
          required: true,
          mutable: true
        }
      },
      customAttributes: {
        'userId': new cognito.StringAttribute({ minLen: 1, maxLen: 24, mutable: false })
      },
      signInAliases: {
        email: true,
        username: false
      },
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    this.userPool.addDomain('HealtheCognitoDomain', {
      cognitoDomain: {
        domainPrefix: 'healthesolutions'
      }
    })

    const flutterAppClient = this.userPool.addClient('CabinetAppClient', {
      userPoolClientName: 'healthe-cabinet-mobile',
      generateSecret: false, 
      oAuth: {
        flows: {
          authorizationCodeGrant: true, 
        },
        scopes: [
          cognito.OAuthScope.OPENID, 
          cognito.OAuthScope.EMAIL, 
          cognito.OAuthScope.PROFILE
        ],
        // You will need to update these to match your Flutter app's deep link schemes
        callbackUrls: ['jct.pillorganizer.pills://callback'],
        logoutUrls: ['jct.pillorganizer.pills://signout'],
      },
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.COGNITO
      ]
    });

    new cognito.CfnManagedLoginBranding(this, 'DefaultManagedLoginBranding', {
      userPoolId: this.userPool.userPoolId,
      clientId: flutterAppClient.userPoolClientId,
      // This is the magic flag that tells Cognito to use its shiny new default styling
      useCognitoProvidedValues: true, 
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

    githubRole.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEC2ContainerRegistryPowerUser'));
    githubRole.addToPolicy(new iam.PolicyStatement({
        actions: ['ecs:UpdateService', 'ecs:DescribeServices', 'ecs:RegisterTaskDefinition', 'ssm:GetParameter', 'iam:PassRole', 'ecs:DescribeTaskDefinition', 'ecs:DescribeTasks'],
        resources: ['*']
    }));
  }
}
