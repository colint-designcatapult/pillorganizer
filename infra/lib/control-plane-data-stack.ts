import * as cdk from 'aws-cdk-lib/core';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

/**
 * This stack defines the persistent data storage for the global control plane.
 */
export class ControlPlaneDataStack extends cdk.Stack {
  public readonly controlPlaneTable: dynamodb.ITableV2;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    this.controlPlaneTable = new dynamodb.TableV2(this, 'DeviceControlPlaneTable', {
      tableName: 'DeviceControlPlane',
      partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
      billing: dynamodb.Billing.onDemand(),
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      deletionProtection: true,
      globalSecondaryIndexes: [
        {
          indexName: 'GSI1',
          partitionKey: { name: 'GSI1_PK', type: dynamodb.AttributeType.STRING },
          sortKey: { name: 'GSI1_SK', type: dynamodb.AttributeType.STRING },
          projectionType: dynamodb.ProjectionType.ALL,
        },
        {
          indexName: 'GSI2',
          partitionKey: { name: 'GSI2_PK', type: dynamodb.AttributeType.STRING },
          sortKey: { name: 'GSI2_SK', type: dynamodb.AttributeType.STRING },
          projectionType: dynamodb.ProjectionType.ALL,
        }
      ]
    });

    new cdk.CfnOutput(this, 'ControlPlaneTableArn', {
      value: this.controlPlaneTable.tableArn,
    });
  }
}