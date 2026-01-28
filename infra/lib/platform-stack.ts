import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import { Construct } from 'constructs';

interface PlatformStackProps extends cdk.StackProps {
  removalPolicy: cdk.RemovalPolicy;
  autoDeleteObjects: boolean;
}

/* This stack is configures base AWS resources, and should only be for things 
   that change rarely. Think VPCs, ECR, ECS clusters etc. */
export class PlatformStack extends cdk.Stack {
  public readonly backendContainer: ecr.Repository;
  public readonly backendEcsCluster: ecs.Cluster;
  public readonly vpc: ec2.Vpc;

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
      removalPolicy: props.removalPolicy,
      emptyOnDelete: props.autoDeleteObjects
    });

    // Create backend ECS cluster
    this.backendEcsCluster = new ecs.Cluster(this, 'BackendCluster', {
      vpc: this.vpc,
    });
  }
}
