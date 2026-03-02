import * as cdk from 'aws-cdk-lib/core';
import * as iot from 'aws-cdk-lib/aws-iot';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';

import { createGlobalLambda } from './lambda-utils';

interface IotStackProps extends cdk.StackProps {
  controlPlaneTable: dynamodb.ITableV2;
}

export class IotStack extends cdk.Stack {

  constructor(scope: Construct, id: string, props: IotStackProps) {
    super(scope, id, props);


    // -- Tenant Isolation Policy --

    const logicalIsolationPolicy = new iot.CfnPolicy(this, 'TenantTopicIsolationPolicy', {
      policyName: 'Tenant_Topic_Isolation_With_Provisioning',
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Action: 'iot:Connect',
            Resource: `arn:aws:iot:${this.region}:${this.account}:client/\${iot:Connection.Thing.ThingName}`
          },
          {
            Effect: 'Allow',
            Action: ['iot:Publish', 'iot:Receive'],
            Resource: [
              `arn:aws:iot:${this.region}:${this.account}:topic/tenant/\${iot:Connection.Thing.Attributes[tenantId]}/\${iot:Connection.Thing.Attributes[deviceId]}/*`
            ]
          },
          {
            Effect: 'Allow',
            Action: 'iot:Subscribe',
            Resource: [
              `arn:aws:iot:${this.region}:${this.account}:topicfilter/tenant/\${iot:Connection.Thing.Attributes[tenantId]}/\${iot:Connection.Thing.Attributes[deviceId]}/*`
            ]
          }
        ]
      }
    });

    // --- Fleet Provisioning ---

    // IoT Provisioning
    const iotProvisioner = createGlobalLambda(this, 'IotProvisioningHook',
          'jct.pillorganizer.global.function.IotProvisioningHook', props.controlPlaneTable);
    const hookVersion = iotProvisioner.currentVersion;
    const iotProvisioningHook = hookVersion;

    // For priming IotClient
    iotProvisioner.addToRolePolicy(new iam.PolicyStatement({
      actions: ['iot:DescribeEndpoint'],
      resources: ['*'] 
    }));
    

    iotProvisioningHook.addPermission('IotHookInvocation', {
      principal: new iam.ServicePrincipal('iot.amazonaws.com'),
      sourceAccount: this.account,
    });

    const provisioningRole = new iam.Role(this, 'FleetProvisioningRole', {
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSIoTThingsRegistration')
      ]
    });


    // C. Define the Fleet Provisioning Template
    const provisioningTemplate = new iot.CfnProvisioningTemplate(this, 'DeviceProvisioningTemplate', {
      templateName: 'TenantDeviceProvisioningTemplate',
      description: 'Provisions a device, assigning its Thing Name and Tenant ID',
      provisioningRoleArn: provisioningRole.roleArn,
      enabled: true,
      
      // Wire up the Pre-Provisioning Hook Lambda
      preProvisioningHook: {
        payloadVersion: '2020-04-01',
        targetArn: iotProvisioningHook.functionArn,
      },
      
      // The Template Body: Maps Hook parameters to IoT Registry Resources
      templateBody: JSON.stringify({
        Parameters: {
          "SerialNumber": { "Type": "String" }, 
          "TenantId": { "Type": "String" },
          "DeviceId": { "Type": "String", "Default": "pending-assignment" },
          "ClaimToken": { "Type": "String" }
        },
        DeviceConfiguration: {
          "TenantId": { "Ref": "TenantId" },
          "DeviceId": { "Ref": "DeviceId" }
        },
        Resources: {
          thing: {
            Type: "AWS::IoT::Thing",
            OverrideSettings: {
              AttributePayload: "MERGE" 
            },
            Properties: {
              ThingName: { "Ref": "SerialNumber" },
              AttributePayload: {
                "tenantId": { "Ref": "TenantId" },
                "deviceId": { "Ref": "DeviceId" }
              }
            }
          },
          certificate: {
            Type: "AWS::IoT::Certificate",
            Properties: {
              CertificateId: { "Ref": "AWS::IoT::Certificate::Id" },
              Status: "ACTIVE"
            }
          },
          policy: {
            Type: "AWS::IoT::Policy",
            Properties: {
              PolicyName: logicalIsolationPolicy.policyName
            }
          }
        }
      })
    });

    // Ensure the policy exists before the template tries to reference it
    provisioningTemplate.addDependency(logicalIsolationPolicy);

  }
}
