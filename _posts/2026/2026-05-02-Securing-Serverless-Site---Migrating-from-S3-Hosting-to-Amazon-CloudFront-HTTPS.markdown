---
layout: post
categories: aws
---
Building a static site is easy, but making it professional and secure requires moving beyond basic S3 hosting. As part of my [AWS Serverless Sump Chart](https://www.nobudev7.com/aws/2026/02/14/AWS-Serverless-Sump-Chart.html) project, I recently migrated my site to a CloudFront-driven architecture to support HTTPS and a custom domain.
Here is the breakdown of how I structured the setup and the critical "gotchas" I discovered along the way.
## Architecture
The setup follows a secure, serverless pattern:

**User → HTTPS → CloudFront → OAC → S3 Bucket (Private)**

In this configuration, S3 is no longer acting as a web server; it functions purely as private storage. CloudFront handles the heavy lifting of security, SSL termination, and content delivery.
## Implementation Steps

   1. Request SSL Certificate: I used AWS Certificate Manager (ACM) to obtain a free SSL certificate. Note that for CloudFront usage, the certificate must be requested in the us-east-1 (N. Virginia) region.
   2. Configure S3 Storage: I used my existing S3 bucket containing the website files. I ensured "Block Public Access" was enabled to keep the data private from the open web.
   3. Create CloudFront Distribution: I set up a new distribution and selected the S3 bucket as the origin.
   4. Implement Origin Access Control (OAC): This is the modern way to secure the connection between CloudFront and S3. It ensures that users cannot bypass CloudFront to access your files directly.
   5. Apply Bucket Policy: To allow CloudFront to fetch files from my private bucket, I applied a specific policy that grants s3:GetObject permissions only to my specific CloudFront distribution ARN.
```json
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::sump-water-level/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "{{CLOUDFRONT_ARN}}"
                }
            }
        }
    ]
}
```

## Key Lessons
While standard tutorials cover the basics, these specific steps were crucial for a working production environment:

* Disable S3 Static Website Hosting: Once you move to CloudFront with OAC, you should disable the "Static Website Hosting" feature in the S3 properties. Since S3 is now just a storage layer, leaving hosting enabled creates an unnecessary (and unencrypted) public endpoint.
* Set the Default Root Object: This is the most common reason for a "403 Forbidden" or "Access Denied" error. Because CloudFront is fetching from a storage bucket rather than a web server, it doesn't know to look for index.html automatically. You must manually define index.html as the Default Root Object in your CloudFront settings.
* Redirect HTTP to HTTPS: To ensure a seamless user experience, I configured the CloudFront distribution behavior "Viewer Protocol Policy" to automatically redirect all insecure HTTP requests to HTTPS.

------------------------------
If you are following along and hitting a wall, check your IAM policy ARN and Default Root Object first—those are usually the culprits.

