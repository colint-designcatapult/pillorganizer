import * as cdk from 'aws-cdk-lib/core';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';
import { createGlobalLambda } from './lambda-utils';

interface AuthStackProps extends cdk.StackProps {
  controlPlaneTable: dynamodb.ITableV2;
}

export class AuthStack extends cdk.Stack {
  public readonly userPool: cognito.UserPool;

  constructor(scope: Construct, id: string, props: AuthStackProps) {
    super(scope, id, props);

    // -- Lambda Triggers --
    const postConfirmation = createGlobalLambda(this, 'PostConfirmation',
      'jct.pillorganizer.global.function.CognitoPostConfirmationHandler', props.controlPlaneTable);
    
    const preTokenGeneration = createGlobalLambda(this, 'PreTokenGeneration',
      'jct.pillorganizer.global.function.CognitoPreTokenGenerationHandler', props.controlPlaneTable);

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
        postConfirmation: postConfirmation,
        preTokenGeneration: preTokenGeneration
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