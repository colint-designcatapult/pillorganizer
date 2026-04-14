import * as cdk from 'aws-cdk-lib/core';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iot from 'aws-cdk-lib/aws-iot';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

/* Global stack — deployed once, not per-environment. */
export class FirmwareStack extends cdk.Stack {

  public readonly firmwareBucketArn: string;
  public readonly jobTemplateArn: string;

  constructor(scope: Construct, id: string, props: cdk.StackProps) {
    super(scope, id, props);

    const firmwareBucket = new s3.Bucket(this, 'FirmwareBucket', {
      versioned: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
    });

    // IAM Role: Allows AWS IoT Core to generate pre-signed URLs
    const presignRole = new iam.Role(this, 'IotPresignRole', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
      description: 'Role used by IoT Jobs to presign firmware S3 URLs',
      // FIX: Use inline policies to prevent CloudFormation race conditions
      inlinePolicies: {
        S3ReadAccess: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              actions: [
                's3:GetObject', 
                's3:GetBucketLocation' // Often required by IoT Core for validation
              ],
              resources: [
                firmwareBucket.bucketArn,
                `${firmwareBucket.bucketArn}/*`
              ],
            }),
          ],
        }),
      },
    });

    const dummyDeployment = new cr.AwsCustomResource(this, 'DeployDummyFirmware', {
      // Tie the execution strictly to the CloudFormation "Create" event
      onCreate: {
        service: 'S3',
        action: 'putObject', 
        parameters: {
          Bucket: firmwareBucket.bucketName,
          Key: 'firmware/latest.bin',
          Body: 'dummy placeholder payload',
        },
        // A static ID ensures CloudFormation knows this resource hasn't changed on future deploys
        physicalResourceId: cr.PhysicalResourceId.of('dummy-firmware-deployment'),
      },
      
      // Automatically generates the IAM policy for the underlying Lambda to write to the bucket
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: [`${firmwareBucket.bucketArn}/firmware/latest.bin`],
      }),
    });

    // Job Template: Rollout config AND Base Document
    const jobTemplate = new iot.CfnJobTemplate(this, 'CabinetOtaTemplate', {
      jobTemplateId: 'cabinet-custom-ota',
      description: 'Standard rollout rules for CabiNET. Points to latest.bin in S3.',
      
      // 1. DYNAMIC BUCKET URL
      document: JSON.stringify({
        url: `\${aws:iot:s3-presigned-url:https://${firmwareBucket.bucketRegionalDomainName}/firmware/latest.bin}`
      }),

      // 2. THE ROLE FIX (Workaround for CDK casing bug)
      presignedUrlConfig: {
        RoleArn: presignRole.roleArn,
        ExpiresInSec: 3600,
      } as any,
      
      // Workaround for AWS CloudFormation Backend Null-Pointer Bug
      jobExecutionsRolloutConfig: {
        MaximumPerMinute: 10, 
        ExponentialRolloutRate: {
          BaseRatePerMinute: 10,
          IncrementFactor: 1.2,
          RateIncreaseCriteria: {
            NumberOfNotifiedThings: 1,
          }
        }
      } as any,
      
      // Workaround for CDK casing bug
      abortConfig: {
        CriteriaList: [{
          Action: 'CANCEL',
          FailureType: 'FAILED',
          MinNumberOfExecutedThings: 10,
          ThresholdPercentage: 20, 
        }],
      } as any,
    });

    jobTemplate.node.addDependency(dummyDeployment);
    
    // Output the role ARN so it's easy to find in the console later
    new cdk.CfnOutput(this, 'PresignRoleArn', { value: presignRole.roleArn });
  }
}
