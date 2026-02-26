import * as cdk from 'aws-cdk-lib/core';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';

interface AuthStackProps extends cdk.StackProps {
  postConfirmation: lambda.Function;
  preTokenGeneration: lambda.Function;
}

export class AuthStack extends cdk.Stack {
  public readonly userPool: cognito.UserPool;

  constructor(scope: Construct, id: string, props: AuthStackProps) {
    super(scope, id, props);

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
      lambdaTriggers: {
        postConfirmation: props.postConfirmation,
        preTokenGeneration: props.preTokenGeneration
      },
      customAttributes: {
        // not used
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
  }
}