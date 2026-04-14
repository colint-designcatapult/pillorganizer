import * as cdk from 'aws-cdk-lib/core';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

/* Global stack — deployed once, not per-environment. */
export class FirmwareStack extends cdk.Stack {

  public readonly firmwareBucketArn: string;
  public readonly firmwareBucketName: string;
  public readonly presignRoleArn: string;

  constructor(scope: Construct, id: string, props: cdk.StackProps) {
    super(scope, id, props);

    /* The bucket is fully private. AWS IoT Jobs presigns firmware URLs
     * per-device at job document fetch time using the presignRole below.
     * The bucket name is fixed so the push-ota.sh --bucket argument is stable
     * across deployments and doesn't require looking up CDK outputs. */
    const firmwareBucket = new s3.Bucket(this, 'FirmwareBucket', {
      bucketName: `healthe-firmware-${this.account}-${this.region}`,
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
    });

    /* IAM role assumed by AWS IoT Jobs to generate per-device presigned URLs.
     * The job document uses ${aws:iot:s3-presigned-url:<url>} placeholders;
     * IoT substitutes a fresh signed URL each time a device fetches the document. */
    const presignRole = new iam.Role(this, 'IotPresignRole', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
      description: 'Allows AWS IoT Jobs to presign firmware S3 URLs per device',
      inlinePolicies: {
        S3ReadAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              actions: ['s3:GetObject'],
              resources: [`${firmwareBucket.bucketArn}/*`],
            }),
            new iam.PolicyStatement({
              actions: ['s3:GetBucketLocation'],
              resources: [firmwareBucket.bucketArn],
            }),
          ],
        }),
      },
    });

    /* Upload a placeholder on first deploy to confirm the bucket and policy
     * are operational before any real firmware is pushed. */
    new cr.AwsCustomResource(this, 'DeployDummyFirmware', {
      onCreate: {
        service: 'S3',
        action: 'putObject',
        parameters: {
          Bucket: firmwareBucket.bucketName,
          Key: 'firmware/placeholder.bin',
          Body: 'placeholder',
        },
        physicalResourceId: cr.PhysicalResourceId.of('dummy-firmware-deployment'),
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: [`${firmwareBucket.bucketArn}/firmware/placeholder.bin`],
      }),
    });

    this.firmwareBucketArn = firmwareBucket.bucketArn;
    this.firmwareBucketName = firmwareBucket.bucketName;
    this.presignRoleArn = presignRole.roleArn;
    new cdk.CfnOutput(this, 'FirmwareBucketArn', { value: this.firmwareBucketArn });
    new cdk.CfnOutput(this, 'FirmwareBucketName', { value: this.firmwareBucketName });
    new cdk.CfnOutput(this, 'PresignRoleArn', { value: this.presignRoleArn });
  }
}
