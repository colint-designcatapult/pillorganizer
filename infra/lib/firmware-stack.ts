import * as cdk from 'aws-cdk-lib/core';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

/* Global stack — deployed once, not per-environment. */
export class FirmwareStack extends cdk.Stack {

  public readonly firmwareBucketArn: string;
  public readonly jobTemplateArn: string;

  constructor(scope: Construct, id: string, props: cdk.StackProps) {
    super(scope, id, props);

    const firmwareBucket = new s3.Bucket(this, 'FirmwareBucket', {
      // Setting this to true automatically creates the public read bucket policy
      publicReadAccess: true, 
      
      // Keep ACLs blocked, but allow the public bucket policy
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ACLS_ONLY, 
      
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      encryption: s3.BucketEncryption.S3_MANAGED,

      bucketName: `healthe-firmware-${this.account}-${this.region}`
    });

    // IoT Job template defining the OTA job document schema.
    // Operators create jobs from this template in the AWS Console,
    // supplying the firmware S3 URL and version string.
    const jobTemplate = new iot.CfnJobTemplate(this, 'OtaJobTemplate', {
      jobTemplateId: 'cabinet-ota-update',
      description: 'OTA firmware update for CabiNET devices. Provide the S3 HTTPS URL and semantic version of the firmware binary.',
      document: JSON.stringify({
        url: '<https://s3.ca-central-1.amazonaws.com/firmware-bucket/firmware/vX.Y.Z/firmware.bin>',
        version: '<X.Y.Z>',
      }),
    });

    this.firmwareBucketArn = firmwareBucket.bucketArn;
    this.jobTemplateArn = jobTemplate.attrArn;

    new cdk.CfnOutput(this, 'FirmwareBucketArn', { value: firmwareBucket.bucketArn });
    new cdk.CfnOutput(this, 'FirmwareBucketName', { value: firmwareBucket.bucketName });
    new cdk.CfnOutput(this, 'OtaJobTemplateArn', { value: jobTemplate.attrArn });
  }
}
