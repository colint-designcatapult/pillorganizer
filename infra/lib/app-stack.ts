import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { Construct } from 'constructs';

interface AppStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  ecr: ecr.Repository;
  ecsCluster: ecs.Cluster;
  dbCluster: rds.DatabaseCluster;
  removalPolicy: cdk.RemovalPolicy;
  environmentName: string;
}

/* This stack configures the actual application. */
export class AppStack extends cdk.Stack {
  public readonly apiService: ecs.Cluster;

  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);

    // -- Logging --

    const logGroup = new logs.LogGroup(this, 'AppLogGroup', {
      logGroupName: `/ecs/pillorganizer-${props.environmentName}`, 
      retention: logs.RetentionDays.ONE_WEEK, // todo: change in prod
      removalPolicy: props.removalPolicy 
    });

    // -- API Container & Service --

    const apiTaskDef = new ecs.FargateTaskDefinition(this, 'ApiTaskDef', {
      memoryLimitMiB: 512,
      cpu: 256,

    });

    const apiContainer = apiTaskDef.addContainer('ApiContainer', {
        image: ecs.ContainerImage.fromEcrRepository(props.ecr, 'latest'),
        logging: ecs.LogDrivers.awsLogs({
          streamPrefix: 'api',
          logGroup
        }),
        portMappings: [{ containerPort: 8080 }],
        environment: {
          DB_HOST: props.dbCluster.clusterEndpoint.hostname,
          DB_PORT: props.dbCluster.clusterEndpoint.port.toString(),
          DB_NAME: 'pillorganizer'
        },
        healthCheck: {
          command: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
        },
    });

    const apiService = new ecsPatterns.ApplicationLoadBalancedFargateService(this, "ApiService", {
      cluster: props.ecsCluster,
      taskDefinition: apiTaskDef,
      desiredCount: 1,
      circuitBreaker: { rollback: true },
      publicLoadBalancer: true,
      minHealthyPercent: 0 // todo: change in production
    });

    // -- IAM --

    // Grant service ability to fetch DB secrets
    props.dbCluster.secret?.grantRead(apiTaskDef.taskRole);

    // Micronaut must be able to list secrets
    // This isn't a security risk because listing doesn't imply access
    apiTaskDef.addToTaskRolePolicy(new iam.PolicyStatement({
      actions: ['secretsmanager:ListSecrets'],
      resources: ['*'], 
    }));

    // -- Networking --

    // Allow access to Aurora from our container. Workaround for circular dependencies.
    // Done this way so the security can be defined in AppStack
    const appSg = apiService.service.connections.securityGroups[0];
    const dbSg = props.dbCluster.connections.securityGroups[0];
    new ec2.CfnSecurityGroupIngress(this, 'DbIngressRule', {
      groupId: dbSg.securityGroupId,
      ipProtocol: 'tcp',
      fromPort: 5432,
      toPort: 5432,
      sourceSecurityGroupId: appSg.securityGroupId 
    });

    // -- ALB --

    // Configure the ALB Target Group Health Check to use Micronaut Management /health endpoint
    apiService.targetGroup.configureHealthCheck({
      path: '/health',
      port: '8080', 
      healthyHttpCodes: '200',
    });

    // Block Public Access to /health
    apiService.listener.addAction('BlockHealthEndpoint', {
      priority: 10, // High priority (runs before the default "Forward" rule)
      conditions: [
        elbv2.ListenerCondition.pathPatterns(['/health', '/health/*'])
      ],
      action: elbv2.ListenerAction.fixedResponse(403, {
        contentType: 'text/plain',
        messageBody: 'Access Denied',
      }),
    });

    // -- Output names to SSM for CI/CD --

    new ssm.StringParameter(this, 'ParamClusterName', {
      parameterName: `/pillorganizer/${props.environmentName}/backend/cluster-name`,
      stringValue: props.ecsCluster.clusterName,
    });

    new ssm.StringParameter(this, 'ParamServiceName', {
      parameterName: `/pillorganizer/${props.environmentName}/backend/service-name`,
      stringValue: apiService.service.serviceName,
    });

    new ssm.StringParameter(this, 'ParamContainerName', {
      parameterName: `/pillorganizer/${props.environmentName}/backend/container-name`,
      stringValue: apiContainer.containerName,
    });

  }
}
