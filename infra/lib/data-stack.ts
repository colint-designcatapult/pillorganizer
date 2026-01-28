import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

interface DataStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  removalPolicy: cdk.RemovalPolicy;
}

/* This stack is configures persistent data stores. */
export class DataStack extends cdk.Stack {
  public readonly dbCluster: rds.DatabaseCluster;

  constructor(scope: Construct, id: string, props: DataStackProps) {
    super(scope, id, props);

    const dbSecret = new secretsmanager.Secret(this, 'DbSecret', {
      secretName: '/config/pillorganizer-backend/database',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'postgres' }),
        generateStringKey: 'password',
        excludeCharacters: ' %+~`#$&*()|[]{}:;<>?!@/"\'\\',
      },
    });

    // todo: change parameters for production
    this.dbCluster = new rds.DatabaseCluster(this, 'AuroraDb', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({ version: rds.AuroraPostgresEngineVersion.VER_17_6 }),
      writer: rds.ClusterInstance.provisioned('writer', {
        publiclyAccessible: false
      }),
      serverlessV2MinCapacity: 0,   // change params in prod
      serverlessV2MaxCapacity: 1.0,
      vpc: props.vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      removalPolicy: props.removalPolicy,
      defaultDatabaseName: "pillorganizer",
      credentials: rds.Credentials.fromSecret(dbSecret),
    });
  }
}
