import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import { Construct } from 'constructs';

interface PlatformStackProps extends cdk.StackProps {
  removalPolicy: cdk.RemovalPolicy;
  autoDeleteObjects: boolean;
}

/* This stack is configures base AWS resources, and should only be for things 
   that change rarely. Think VPCs, S3, ECR etc. */
export class PlatformStack extends cdk.Stack {
  public readonly ecr: ecr.Repository;
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: PlatformStackProps) {
    super(scope, id, props);


    // Create VPC with minimal resources 
    this.vpc = new ec2.Vpc(this, 'AppVpc', {
      maxAzs: 2,
      natGateways: 1,
    });

    // Create container repository
    this.ecr = new ecr.Repository(this, 'ContainerRepository', {
      repositoryName: 'pillorganizer',
      removalPolicy: props.removalPolicy,
      emptyOnDelete: props.autoDeleteObjects
    });

  }
}
