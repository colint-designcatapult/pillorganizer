import * as cdk from 'aws-cdk-lib/core';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

export function createGlobalLambda(scope: Construct, id: string, handler: string, table: dynamodb.ITableV2): lambda.Function {
  const func = new lambda.Function(scope, id, {
    runtime: lambda.Runtime.JAVA_21,
    handler: handler,
    code: lambda.Code.fromAsset("../backend/global/target/global-0.1.jar"),
    memorySize: 2048,
    timeout: cdk.Duration.seconds(30),
    snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
    environment: {
      'MICRONAUT_ENVIRONMENTS': 'global',
    },
  });
  table.grantReadWriteData(func);
  return func;
}