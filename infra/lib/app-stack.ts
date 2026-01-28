import * as cdk from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';

interface AppStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  ecr: ecr.Repository;
  ecsCluster: ecs.Cluster;
  dbCluster: rds.DatabaseCluster;
  removalPolicy: cdk.RemovalPolicy;
}

/* This stack is configures persistent data stores. */
export class AppStack extends cdk.Stack {
  public readonly apiService: ecs.Cluster;

  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);

    const apiService = new ecsPatterns.ApplicationLoadBalancedFargateService(this, "ApiService", {
      cluster: props.ecsCluster,
      cpu: 256, // .25 vCPU
      memoryLimitMiB: 512, // 512MB RAM
      desiredCount: 1, // How many containers to run
      circuitBreaker: {
        rollback: true,
        enable: true
      },
      taskImageOptions: {
        // Use the image from the existing ECR repository
        // 'latest' is the default tag, change it if you need a specific version
        image: ecs.ContainerImage.fromEcrRepository(props.ecr, 'latest'), 
        containerPort: 8080, // The port your container listens on
        environment: {
          DB_HOST: props.dbCluster.clusterEndpoint.hostname,
          DB_PORT: props.dbCluster.clusterEndpoint.port.toString(),
          DB_NAME: 'pillorganizer'
        }
      },
      healthCheck: {
        command: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
      },
      publicLoadBalancer: true, 
      minHealthyPercent: 0 // todo: change in prod
    });

    // Grant service ability to fetch DB secrets
    props.dbCluster.secret?.grantRead(apiService.taskDefinition.taskRole);

    // Micronaut must be able to list secrets
    // This isn't a security risk because listing doesn't imply access
    apiService.taskDefinition.taskRole.addToPrincipalPolicy(new iam.PolicyStatement({
      actions: ['secretsmanager:ListSecrets'],
      resources: ['*'], 
    }));

    // Ensure ECS service has access to Aurora
    const appSg = apiService.service.connections.securityGroups[0];
    const dbSg = props.dbCluster.connections.securityGroups[0];    

    new ec2.CfnSecurityGroupIngress(this, 'DbIngressRule', {
      groupId: dbSg.securityGroupId,            // The Target (DB Security Group ID)
      ipProtocol: 'tcp',
      fromPort: 5432,
      toPort: 5432,
      sourceSecurityGroupId: appSg.securityGroupId // The Source (App Security Group ID)
    });

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
  }
}
