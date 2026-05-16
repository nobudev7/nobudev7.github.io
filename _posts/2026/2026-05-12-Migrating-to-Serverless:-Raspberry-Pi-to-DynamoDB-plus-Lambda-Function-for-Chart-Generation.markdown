---
layout: post
categories: aws Raspi
---

Building on the foundation of [SumpDataVisualizerCli](https://github.com/nobudev7/SumpDataVisualizerCli)—my original Java tool designed to generate chart images from local CSV files—I’ve spent this week evolving the project into a fully automated, cloud-native solution. The goal was to take that local visualization logic and migrate it to **AWS Lambda**, transforming a manual process into a seamless serverless pipeline that handles everything from data ingestion to chart delivery. In this post, I’ll walk through how I bridged the gap between a Raspberry Pi and the AWS cloud to create a robust, hands-off monitoring system.

## The Vision: Automated Peace of Mind

The goal was simple - generate water level charts automatically continuously. The system follows a clean, serverless flow:
1.  **Data Collection**: A Raspberry Pi reads water levels and pushes them to AWS DynamoDB.
2.  **Storage**: AWS DynamoDB acts as the high-performance, persistent data store.
3.  **Visualization**: An AWS Lambda function triggers upon data point upload, generate a PNG chart using JFreeChart, and serve it via Amazon S3.

## The Architecture: Java in AWS Lambda

The core of the system is a Lambda function written in **Java 21**. It utilizes the `JFreeChart` library to handle chart generation. Because AWS Lambda has limited filesystem access and is designed for stateless execution, the code is optimized for in-memory processing:

See the code in this GitHub repo - [ChartGeneratorLambdaFunction](https://github.com/nobudev7/ChartGeneratorLambdaFunction).

1.  **Data Retrieval**: The function queries DynamoDB for a specific date's data points.
2.  **In-Memory Generation**: Instead of writing to a temporary file, the chart is generated and stored in memory as a `byte[]`.
3.  **S3 Stream**: The byte array is then uploaded directly to an S3 bucket with the appropriate `Cache-Control` headers.

This approach keeps the function lightweight and avoids the overhead of managing local disk space during execution.

## The Data Pulse: Raspberry Pi Ingestion

The "eyes and ears" of the project remain on-premises. A Raspberry Pi is responsible for the actual data collection. During this session, I developed two specialized Python scripts to ensure the data in my `<TABLE_NAME>` DynamoDB table is both timely and accurate.

### 1. Real-Time Heartbeat (`upload.py`)
This script runs every minute via a cron job. It captures the current date, time, and water level, then pushes a single data point to AWS. This gives us a "near-real-time" view of the sump activity.

### 2. The Fail-Safe Batch (`batch_upload.py`)
My home access point occasionally drops the WiFi connection, and standard minute-by-minute uploads might miss some data point. Also, because I run per-minute upload script using cron with some intentional delay to make sure the measurement is done, there's always a missing "final minute" of a day's dataset. To solve this, I created `batch_upload.py` that upload all data points from the prior day. 

This script is designed to run shortly after midnight. It reads a full day's worth of data from a local CSV file and performs a bulk upload. I implemented a specific rate-limiting strategy here: it writes in batches of 20 items with a mandatory one-second delay between each batch. The one-second rate limit ensures that it doesn't go over the Write Capacity Unit (WCU) allowance under the DynamoDB free tier quota.

## Bridging the Gap: Setting Up the Raspberry Pi

One of the highlights of this session was addressing the unique constraints of older hardware. My Raspberry Pi is running **Raspbian Buster** (Python 3.7), which presents some challenges for modern libraries. 

Here is the approach I took to get `boto3` (the AWS SDK for Python) running smoothly:

### Environment and Versioning
Since `boto3` version 1.30.0 dropped support for Python 3.7, I had to be surgical with my installation. I set up a dedicated virtual environment to keep the system clean:

```shell
# Create a dedicated workspace
mkdir aws-sump
cd aws-sump

# Set up the virtual environment
python3 -m venv myenv
source myenv/bin/activate

# Install a compatible version of boto3
pip3 install 'boto3<1.30.0'
```

Although the installation was successful, I got this warning.
```
s3transfer 0.8.2 has requirement botocore<2.0a.0,>=1.33.2, but you'll have botocore 1.32.7 which is incompatible.
```

Despite the warning about `s3transfer` dependencies, the core DynamoDB functionality works perfectly for my needs, so I figured it's OK.

I then configured the local credentials at `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = <YOUR_ACCESS_KEY_ID>
aws_secret_access_key = <YOUR_SECRET_ACCESS_KEY>
```

### Security First: IAM Policy
Following the principle of least privilege, I created a custom IAM policy for the Raspberry Pi user. This ensures that even if the Pi were compromised, the credentials only allow writing to the specific water level table:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:BatchWriteItem"
            ],
            "Resource": "arn:aws:dynamodb:<YOUR_REGION>:<YOUR_ACCOUNT_ID>:table/<TABLE_NAME>"
        }
    ]
}
```

## Conclusion

This is a part of migration to a serverless system - data point upload and chart generation. By using the power of AWS Lambda and DynamoDB, I’ve created basis of a monitoring system that is both resilient and serverless.
