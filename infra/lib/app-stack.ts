import * as cdk from 'aws-cdk-lib/core';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import { HttpLambdaIntegration } from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources';
import { Construct } from 'constructs';

interface AppStackProps extends cdk.StackProps {
  dsqlCluster: string;
  dsqlEndpoint: string;
  removalPolicy: cdk.RemovalPolicy;
  environmentName: string;
  domainName: apigwv2.IDomainName;
  adminUserPool: cognito.IUserPool;
}

/* This stack configures the actual application. */
export class AppStack extends cdk.Stack {
  public readonly api: apigwv2.HttpApi;
  public readonly fullDomainName: string;

  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);
    const tenantId = props.environmentName;
    const tenantAdminGroup = `admin-tenant-${tenantId}`;

    new cognito.CfnUserPoolGroup(this, 'TenantAdminGroup', {
      groupName: tenantAdminGroup,
      userPoolId: props.adminUserPool.userPoolId,
      description: `Tenant admin role for ${tenantId}`
    });

    // -- SQS --

    const tenantQueue = new sqs.Queue(this, 'TenantQueue', {
      queueName: `tenant-${props.environmentName}`,
      visibilityTimeout: cdk.Duration.seconds(300),
      retentionPeriod: cdk.Duration.days(7),
    });

    // Allow all AWS resources (within this account) to push to the queue
    tenantQueue.addToResourcePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      principals: [new iam.AnyPrincipal()],
      actions: ['sqs:SendMessage', 'sqs:GetQueueUrl'],
      resources: [tenantQueue.queueArn],
      conditions: { StringEquals: { 'aws:PrincipalAccount': this.account } }
    }));

    // -- IoT SQS Integration --
      
    // Create the IAM Role that allows IoT Core to publish to the SQS Queue
    const iotSqsRole = new iam.Role(this, 'IotSqsPublishRole', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
      description: 'Allows AWS IoT Rule to push messages to the SQS queue',
    });
    tenantQueue.grantSendMessages(iotSqsRole);

    const shadowUpdateRule = new iot.CfnTopicRule(this, 'NamedShadowUpdateRule', {
      ruleName: `RouteNamedShadowUpdatesToSQS_${props.environmentName}`, 
      topicRulePayload: {
        awsIotSqlVersion: '2016-03-23',
        // 
        sql: `SELECT *, topic(3) as thingName, topic(6) as shadowName, 'shadow' as type, '${props.environmentName}' as tenant
         FROM '$aws/things/+/shadow/name/+/update/documents' WHERE startswith(topic(3), '${props.environmentName}-')`,
        ruleDisabled: false,
        actions: [
          {
            sqs: {
              queueUrl: tenantQueue.queueUrl,
              roleArn: iotSqsRole.roleArn,
              useBase64: false, 
            },
          },
        ],
      },
    });

    const deviceEventRule = new iot.CfnTopicRule(this, 'DeviceEventRule', {
      ruleName: `RouteDeviceEventsToSQS_${props.environmentName}`,
      topicRulePayload: {
        awsIotSqlVersion: '2016-03-23',
        sql: `SELECT 'deviceEvent' as type, *, topic(3) as thingName, topic(4) as topicName, '${props.environmentName}' as tenant
         FROM 'healthe/things/+/event' WHERE startswith(topic(3), '${props.environmentName}-')`,
        ruleDisabled: false,
        actions: [
          {
            sqs: {
              queueUrl: tenantQueue.queueUrl,
              roleArn: iotSqsRole.roleArn,
              useBase64: false,
            },
          },
        ],
      },
    });

    // -- Lambda --
    const tenantCode = lambda.Code.fromAsset("../backend/tenant/target/tenant-0.1.jar");

    const createTenantFunction = (id: string, handler: string, env: string = "") => {
      const fn = new lambda.Function(this, id, {
        runtime: lambda.Runtime.JAVA_21,
        handler: handler,
        code: tenantCode,
        memorySize: 2048,
        timeout: cdk.Duration.seconds(30),
        snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
        tracing: lambda.Tracing.ACTIVE,
        insightsVersion: lambda.LambdaInsightsVersion.VERSION_1_0_498_0,
        environment: {
          MICRONAUT_ENVIRONMENTS: `tenant,${props.environmentName}${env != '' ? ',' + env : ''}`,
          DB_HOST: props.dsqlEndpoint,
          DB_PORT: '5432',
          DB_NAME: 'pillorganizer',
          TENANT_ID: tenantId,
        },
      });

      // -- IAM & Security --
      fn.addToRolePolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            // Use 'dsql:DbConnectAdmin' to connect as the default admin.
            // If you set up a custom DSQL user/role later, use 'dsql:DbConnect'.
            'dsql:DbConnectAdmin' 
          ],
          resources: [
            // Formulate the DSQL Cluster ARN using the generated cluster ID
            cdk.Stack.of(this).formatArn({
              service: 'dsql',
              resource: 'cluster',
              resourceName: props.dsqlCluster,
            })
          ]
        })
      );

      // Ensure app functions have access to AWS IoT Shadow State operations
      // Lock down IAM based on tenant
      fn.addToRolePolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            'iot:GetThingShadow',
            'iot:UpdateThingShadow'
          ],
          resources: [
            `arn:aws:iot:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:thing/${props.environmentName}-*`
          ]
        })
      );

      // Ensure app functions can publish MQTT commands to devices
      fn.addToRolePolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            'iot:Publish'
          ],
          resources: [
            `arn:aws:iot:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:topic/healthe/things/${props.environmentName}-*/cmd/*`
          ]
        })
      );

      // Ensure app functions can manage SNS topics, subscriptions and publish notifications
      fn.addToRolePolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            'sns:CreateTopic',
            'sns:Publish',
            'sns:SetSubscriptionAttributes'
          ],
          resources: [
            `arn:aws:sns:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:device-*`,
          ],
        })
      );

      fn.addToRolePolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            'sns:Subscribe',
            'sns:Unsubscribe',
          ],
          resources: [
            `arn:aws:sns:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:device-*`,
          ],
        })
      );

      // Grant permission to delete IoT Things scoped to this tenant's prefix
      fn.addToRolePolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            'iot:DeleteThing',
          ],
          resources: [
            `arn:aws:iot:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:thing/${props.environmentName}-*`
          ]
        })
      );

      return fn;
    };

    const appFunction = createTenantFunction('AppFunction', 'io.micronaut.function.aws.proxy.payload2.APIGatewayV2HTTPEventFunction');
    const queueProcessor = createTenantFunction('QueueProcessor', 'jct.pillorganizer.tenant.function.TenantQueueProcessor');

    // Create function to run Flyway migrations
    const flywayFunction = createTenantFunction('FlywayMigrationHandler', 'jct.pillorganizer.tenant.function.MigrationHandler', 'flyway')
    appFunction.node.addDependency(flywayFunction)
    queueProcessor.node.addDependency(flywayFunction)

    // Wire up SQS trigger (using currentVersion to support SnapStart)
    queueProcessor.currentVersion.addEventSource(new lambdaEventSources.SqsEventSource(tenantQueue, {
      batchSize: 10,
      enabled: true,
      reportBatchItemFailures: true,
    }));

    // -- API Gateway --

    const version = appFunction.currentVersion;
    const alias = new lambda.Alias(this, 'AppAlias', {
      aliasName: `live-${props.environmentName}`,
      version: version,
    });

    this.api = new apigwv2.HttpApi(this, 'AppHttpApi', {
      apiName: `PillOrganizer Tenant Backend (${props.environmentName})`,
      defaultIntegration: new HttpLambdaIntegration('ControlPlaneIntegration', alias),
      defaultDomainMapping: {
        domainName: props.domainName,
      },
    });
  }
}
