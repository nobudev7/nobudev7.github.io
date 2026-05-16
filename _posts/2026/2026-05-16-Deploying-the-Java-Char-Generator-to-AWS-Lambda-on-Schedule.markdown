---
layout: post
categories: aws Raspi
---

This blog post provides a minimal, step-by-step procedure for deploying the [ChartGeneratorLambdaFunction](https://github.com/nobudev7/ChartGeneratorLambdaFunction) Java JAR as an AWS Lambda function and scheduling it to run every 5 minutes.

Every 5 minutes is enough to generate up-to-date chart, although data points are uploaded every minute. If AWS cost is not a question, it can be every minute, or the lambda function can be run by each data point upload to DynamoDB.

The system design idea is described in my previous post - [Migrating To Serverless: Raspberry Pi To Dynamodb Plus Lambda Function For Chart Generation](https://www.nobudev7.com/aws/raspi/2026/05/12/Migrating-to-Serverless-Raspberry-Pi-to-DynamoDB-plus-Lambda-Function-for-Chart-Generation.html)

### 1. Build the Deployment Package
Compile the "fat JAR" containing all dependencies:
```bash
mvn clean package
```
Result: `target/ChartGeneratorLambdaFunction-1.0-SNAPSHOT.jar`

### 2. Create the Lambda Function
1. Open the **AWS Lambda Console**.
2. Click **Create function** > **Author from scratch**.
3. Function name: **ChartGenerator** (or your preferred name).
4. **Runtime**: **Java 21**.
5. (Optional) **Architecture**: Turn on `ARM64 architecture`.



### 3. Upload to S3 and Configure Lambda
AWS suggests to use S3 for files larger than 10MB. Because the Chart Generator JAR is 17MB, it is best to upload via S3:

1.  **Upload to S3**:
    -   Go to your S3 bucket (e.g., `chart-generator`).
    -   Upload `target/ChartGeneratorLambdaFunction-1.0-SNAPSHOT.jar`.
    -   Copy the **S3 URI** (e.g., `s3://chart-generator/ChartGeneratorLambdaFunction-1.0-SNAPSHOT.jar`).

2.  **Configure Lambda**:
    -   In the **Code** tab, click **Update** > **Update from a file in Amazon S3**.
    -   Paste the **S3 URI** you copied.
    -   In **Runtime settings**, click **Edit** and set the **Handler** to:
        `com.nobudev7.ChartGeneratorHandler::handleRequest`


### 4. Configure IAM Permissions
The Lambda function must be authorized to read from DynamoDB and write to S3. Follow these steps to attach the necessary permissions:

1.  **Navigate to Permissions**: In the Lambda function console, click on the **Configuration** tab and select **Permissions** from the left-hand menu.
2.  **Access the Role**: Click on the link under **Role name** (e.g., `ChartGenerator-role-xxxx`). This will open the IAM Console in a new tab.
3.  **Create Inline Policy**:
    -   In the IAM Console, click **Add permissions** on the right side and select **Create inline policy**.
    -   Switch to the **JSON** editor tab.
4.  **Apply the Policy**: Paste the following JSON block, replacing `<REGION>`, `<ACCOUNT_ID>`, and `<BUCKET_NAME>` with your actual values:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DynamoDBRead",
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query"
            ],
            "Resource": "arn:aws:dynamodb:us-east-1:<YOUR_ACCOUNT_ID>:table/Sump_Water_Level"
        },
        {
            "Sid": "LambdaCodeRead",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::sump-chart-generator/*"
        },
        {
            "Sid": "ChartOutputWrite",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::sump-water-level/output/*"
        }
    ]
}
```

### 5. Adjust Resources
JFreeChart requires sufficient memory and time for image processing:
- **Memory**: 512 MB to 384 MB.
- **Timeout**: 30 seconds.

### 6. Schedule Execution
1. Click **Add trigger** > **EventBridge (CloudWatch Events)**.
2. Select **Create a new rule**.
3. **Rule type**: **Schedule expression**.
4. **Schedule expression**: `rate(5 minutes)`.
5. Click **Add**.

### 7. Verify and Monitor Execution
To confirm your Lambda is running every 5 minutes, you can check the **AWS CloudWatch Logs**:

1.  **Monitor Tab**: In the Lambda console, click the **Monitor** tab at the top.
2.  **View CloudWatch Logs**: Click the **View CloudWatch logs** button. This opens the CloudWatch console in a new tab.
3.  **Log Streams**: You will see a list of **Log streams**. Each time the Lambda container starts or runs, it logs to these streams.
4.  **Check Timestamps**: Open the latest log stream. You should see entries like `START RequestId: ...` and `END RequestId: ...`. 
    - Verify that the **Event time** for these entries occurs every 5 minutes.
    - Look for the output from the Java code (e.g., `Processing data for date: ...`) to ensure the logic is executing successfully.
5.  **Troubleshooting**: If you don't see logs or see `ERROR` entries, check the logs for specific Java exceptions (like `AccessDeniedException` if IAM permissions are wrong).
