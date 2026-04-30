import * as cdk from 'aws-cdk-lib/core';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as cloudfrontOrigins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import { Construct } from 'constructs';
import * as path from 'path';

interface DashboardStackProps extends cdk.StackProps {
  baseDomain: string;
}

/**
 * Deploys the Angular SPA (admin web dashboard) to S3 and distributes it
 * via CloudFront at `admin.${props.baseDomain}`.
 *
 * This stack must be deployed to us-east-1 because CloudFront requires
 * ACM certificates to be in that region.
 */
export class DashboardStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: DashboardStackProps) {
    super(scope, id, props);

    const domainName = `admin.${props.baseDomain}`;

    const zone = route53.HostedZone.fromLookup(this, 'HostedZone', {
      domainName: props.baseDomain,
    });

    // Certificate must be in us-east-1 for CloudFront
    const certificate = new acm.Certificate(this, 'Certificate', {
      domainName: domainName,
      validation: acm.CertificateValidation.fromDns(zone),
    });

    // Private S3 bucket — CloudFront accesses it via OAC
    const bucket = new s3.Bucket(this, 'DashboardBucket', {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // CloudFront distribution with HTTPS enforcement and SPA error routing
    const distribution = new cloudfront.Distribution(this, 'DashboardDistribution', {
      defaultBehavior: {
        origin: cloudfrontOrigins.S3BucketOrigin.withOriginAccessControl(bucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
      },
      domainNames: [domainName],
      certificate: certificate,
      defaultRootObject: 'index.html',
      // Route errors to index.html so Angular's client-side router handles them
      errorResponses: [
        {
          httpStatus: 403,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
        },
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
        },
      ],
    });

    // Route53 alias record pointing to the CloudFront distribution
    new route53.ARecord(this, 'DashboardAliasRecord', {
      zone: zone,
      recordName: 'admin',
      target: route53.RecordTarget.fromAlias(new targets.CloudFrontTarget(distribution)),
    });

    // Deploy the Angular SPA build output to S3 and invalidate CloudFront cache
    new s3deploy.BucketDeployment(this, 'DashboardDeployment', {
      sources: [s3deploy.Source.asset(path.join(__dirname, '../../web/dist/sakai-ng/browser'))],
      destinationBucket: bucket,
      distribution: distribution,
      distributionPaths: ['/*'],
    });
  }
}
