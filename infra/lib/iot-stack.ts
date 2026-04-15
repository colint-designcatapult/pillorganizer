import * as cdk from 'aws-cdk-lib/core';
import * as iot from 'aws-cdk-lib/aws-iot';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';

import { createGlobalLambda } from './lambda-utils';
import { Condition } from 'aws-cdk-lib/aws-stepfunctions';

interface IotStackProps extends cdk.StackProps {
  controlPlaneTable: dynamodb.ITableV2;
  mqttDomain: string;
  mqttWsDomain: string;
  mqttCertificateArn: string;
  mqttWsCertificateArn: string;
}

export class IotStack extends cdk.Stack {

  constructor(scope: Construct, id: string, props: IotStackProps) {
    super(scope, id, props);

    // @relation(INFRA-REQ-11, scope=range_start)
    const domainConfig = new iot.CfnDomainConfiguration(this, 'MqttDomainConfig', {
      domainName: props.mqttDomain,
      serverCertificateArns: [props.mqttCertificateArn],
      serviceType: 'DATA',
      domainConfigurationStatus: 'ENABLED',
      applicationProtocol: "SECURE_MQTT",
      // @relation(INFRA-REQ-12, scope=line)
      authenticationType: "AWS_X509"
    });
    // @relation(INFRA-REQ-11, scope=range_end)
    domainConfig.applyRemovalPolicy(cdk.RemovalPolicy.RETAIN);

    // -- Tenant Isolation Policy --

    // @relation(INFRA-REQ-14, scope=range_start)
    const logicalIsolationPolicy = new iot.CfnPolicy(this, 'TenantTopicIsolationPolicy', {
      policyName: 'Tenant_Topic_Isolation_With_Provisioning',
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Action: 'iot:Connect',
            Resource: `arn:aws:iot:${this.region}:${this.account}:client/\${iot:Connection.Thing.ThingName}`,
            Condition: {
              StringEquals: {
                "iot:DomainName": props.mqttDomain
              }
            }
          },
          {
            Effect: 'Allow',
            Action: ['iot:Publish', 'iot:Receive', 'iot:RetainPublish'],
            Resource: [
              `arn:aws:iot:${this.region}:${this.account}:topic/healthe/things/\${iot:Connection.Thing.ThingName}/*`,
              `arn:aws:iot:${this.region}:${this.account}:topic/$aws/things/\${iot:Connection.Thing.ThingName}/shadow/*`,
              `arn:aws:iot:${this.region}:${this.account}:topic/$aws/things/\${iot:Connection.Thing.ThingName}/jobs/*`
            ]
          },
          {
            Effect: 'Allow',
            Action: 'iot:Subscribe',
            Resource: [
              `arn:aws:iot:${this.region}:${this.account}:topicfilter/healthe/things/\${iot:Connection.Thing.ThingName}/*`,
              `arn:aws:iot:${this.region}:${this.account}:topicfilter/$aws/things/\${iot:Connection.Thing.ThingName}/shadow/*`,
              `arn:aws:iot:${this.region}:${this.account}:topicfilter/$aws/things/\${iot:Connection.Thing.ThingName}/jobs/*`
            ]
          }
        ]
      }
    });
    // @relation(INFRA-REQ-14, scope=range_end)

    // --- WebSocket Domain & Custom Authorizer ---
    const iotAuthorizerFunction = createGlobalLambda(this, 'IotCustomAuthorizer',
          'jct.pillorganizer.global.function.IotCustomAuthorizer', props.controlPlaneTable);

    const authorizerVersion = iotAuthorizerFunction.currentVersion;
    const iotAuthorizer = authorizerVersion;

    iotAuthorizer.addPermission('IotAuthorizerInvocation', {
      principal: new iam.ServicePrincipal('iot.amazonaws.com'),
      sourceAccount: this.account,
    });

    // @relation(INFRA-REQ-16, scope=range_start)
    const mobileAuthorizer = new iot.CfnAuthorizer(this, 'MobileJwtAuthorizer', {
      authorizerName: 'MobileAppJwtAuthorizer',
      authorizerFunctionArn: iotAuthorizer.functionArn,
      status: 'ACTIVE',
      signingDisabled: true, 
    });
    // @relation(INFRA-REQ-16, scope=range_end)

    // Ensure the permission is created before the authorizer tries to use the Lambda
    mobileAuthorizer.node.addDependency(iotAuthorizer);

    // @relation(INFRA-REQ-15, scope=range_start)
    const wsDomainConfig = new iot.CfnDomainConfiguration(this, 'MqttWsDomainConfig', {
      domainName: props.mqttWsDomain,
      serverCertificateArns: [props.mqttWsCertificateArn],
      serviceType: 'DATA',
      domainConfigurationStatus: 'ENABLED',
      applicationProtocol: "MQTT_WSS",
      authenticationType: "CUSTOM_AUTH",
      authorizerConfig: {
        allowAuthorizerOverride: false,
        // @relation(INFRA-REQ-16, scope=line)
        defaultAuthorizerName: "MobileAppJwtAuthorizer"
      }
    });
    wsDomainConfig.applyRemovalPolicy(cdk.RemovalPolicy.RETAIN);

    wsDomainConfig.addDependency(mobileAuthorizer);
    // @relation(INFRA-REQ-15, scope=range_end)

    // --- Fleet Provisioning ---

    const v1ThingGroup = new iot.CfnThingGroup(this, 'V1ThingGroup', {
      thingGroupName: 'v1',
    });
    v1ThingGroup.applyRemovalPolicy(cdk.RemovalPolicy.RETAIN);

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
          // Sent by device
          "SerialNumber": { "Type": "String" }, 
          "ClaimId": { "Type": "String" },
          "ClaimToken": { "Type": "String" },

          // Returned by provision hook
          "TenantId": { "Type": "String" },
          "DeviceId": { "Type": "String" },
          "ThingName": { "Type": "String" }
        },
        DeviceConfiguration: {
          "ThingName": { "Ref": "ThingName" }
        },
        Resources: {
          thing: {
            Type: "AWS::IoT::Thing",
            OverrideSettings: {
              AttributePayload: "MERGE"
            },
            Properties: {
              ThingName: { "Ref": "ThingName" },
              AttributePayload: {
                "tenantId": { "Ref": "TenantId" },
                "deviceId": { "Ref": "DeviceId" },
                "serialNumber": { "Ref": "SerialNumber" }
              },
              ThingGroups: ["v1", { "Ref": "TenantId" }]
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
    // Ensure the v1 thing group exists before the template is created
    provisioningTemplate.addDependency(v1ThingGroup);

  }
}
