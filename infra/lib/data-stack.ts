import * as cdk from 'aws-cdk-lib/core';
import * as dsql from 'aws-cdk-lib/aws-dsql';
import { Construct } from 'constructs';

interface DataStackProps extends cdk.StackProps {
  removalPolicy: cdk.RemovalPolicy;
  environmentName: string;
}

/* This stack is configures persistent data stores. */
export class DataStack extends cdk.Stack {
  public readonly clusterId: string;
  public readonly clusterEndpoint: string;

  constructor(scope: Construct, id: string, props: DataStackProps) {
    super(scope, id, props);

    const cluster = new dsql.CfnCluster(this, 'AuroraDsqlCluster', {
      deletionProtectionEnabled: props.removalPolicy === cdk.RemovalPolicy.RETAIN,
        //"Name": `pillorganizer-${props.environmentName}`
    });

    this.clusterId = cluster.attrIdentifier;
    this.clusterEndpoint = `${this.clusterId}.dsql.${this.region}.on.aws`;
  }
}
