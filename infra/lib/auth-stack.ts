import * as cdk from 'aws-cdk-lib/core';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';
import { createGlobalLambda } from './lambda-utils';

interface AuthStackProps extends cdk.StackProps {
  controlPlaneTable: dynamodb.ITableV2;
  baseDomain: string;
}

export class AuthStack extends cdk.Stack {
  public readonly adminUserPool: cognito.IUserPool;
  public readonly userPool: cognito.IUserPool;

  constructor(scope: Construct, id: string, props: AuthStackProps) {
    super(scope, id, props);

    // -- Lambda Triggers --
    const postConfirmation = createGlobalLambda(this, 'PostConfirmation',
      'jct.pillorganizer.global.function.CognitoPostConfirmationHandler', props.controlPlaneTable);
    
    const preTokenGeneration = createGlobalLambda(this, 'PreTokenGeneration',
      'jct.pillorganizer.global.function.CognitoPreTokenGenerationHandler', props.controlPlaneTable);

    // -- Cognito User Pool --
    var userPool = new cognito.UserPool(this, 'HealtheUserPool', {
      userPoolName: 'healthe-userpool',
      selfSignUpEnabled: true,
      standardAttributes: {
        email: {
          required: true,
          mutable: true
        }
      },
      lambdaTriggers: {
        postConfirmation: postConfirmation,
        preTokenGeneration: preTokenGeneration
      },
      signInAliases: {
        email: true,
        username: false
      },
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    userPool.addDomain('HealtheCognitoDomain', {
      cognitoDomain: {
        domainPrefix: 'healthesolutions'
      }
    })

    const flutterAppClient = userPool.addClient('CabinetAppClient', {
      userPoolClientName: 'healthe-cabinet-mobile',
      generateSecret: false, 
      authFlows: {
        userPassword: true, 
        userSrp: true,
        custom: true,
        user: true
      },
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
        callbackUrls: ['jct.pillorganizer.pills://callback', 'ca.healthesolutions.cabinet://callback'],
        logoutUrls: ['jct.pillorganizer.pills://signout', 'ca.healthesolutions.cabinet://signout'],
      },
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.COGNITO
      ]
    });

    new cognito.CfnManagedLoginBranding(this, 'DefaultManagedLoginBranding', {
      userPoolId: userPool.userPoolId,
      clientId: flutterAppClient.userPoolClientId,
      // This is the magic flag that tells Cognito to use its shiny new default styling
      useCognitoProvidedValues: true, 
    });

    // -- Admin Cognito User Pool --
    var adminUserPool = new cognito.UserPool(this, 'HealtheAdminUserPool', {
      userPoolName: 'healthe-admin-userpool',
      selfSignUpEnabled: false,
      standardAttributes: {
        email: {
          required: true,
          mutable: true
        }
      },
      signInAliases: {
        email: true,
        username: false
      },
      removalPolicy: cdk.RemovalPolicy.RETAIN
    });

    adminUserPool.addDomain('HealtheAdminCognitoDomain', {
      cognitoDomain: {
        domainPrefix: 'healthesolutions-admin'
      }
    });

    const adminAppClient = adminUserPool.addClient('AdminDashboardClient', {
      userPoolClientName: 'healthe-admin-dashboard',
      generateSecret: false,
      authFlows: {
        userPassword: true,
        userSrp: true
      },
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
        },
        scopes: [
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.PROFILE
        ],
        callbackUrls: [
          'http://localhost:4200/callback',
          `https://admin.${props.baseDomain}/callback`
        ],
        logoutUrls: [
          'http://localhost:4200/logout',
          `https://admin.${props.baseDomain}/logout`
        ],
      },
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.COGNITO
      ]
    });

    new cognito.CfnManagedLoginBranding(this, 'AdminManagedLoginBranding', {
      userPoolId: adminUserPool.userPoolId,
      clientId: adminAppClient.userPoolClientId,
      useCognitoProvidedValues: true,
    });

    new cognito.CfnUserPoolGroup(this, 'AdminGlobalGroup', {
      groupName: 'admin-global',
      userPoolId: adminUserPool.userPoolId,
      description: 'Global admin role for dashboard access'
    });

    this.adminUserPool = adminUserPool;
    this.userPool = userPool;
  }
}
