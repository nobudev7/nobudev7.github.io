---
layout: post
categories: aws
---
## AWS Serverless Sump Chart

I have developed my own Sump Chart website, that involves Raspi for monitoring, Java server for processing and storing data, and Streamlit for data visualization. Those are all meant to imitate a large scale IoT data processing system. This is all good, however, after learning various AWS capability, I decided to attempt to make the whole system run serverless. It will heavily rely on AWS capability, but will be cost less for a relatively simple data visualization project.

Key AWS Capability:
- S3 as a static web site
- Lambda for data processing and charting

### The plan
(To be updated as necessary)

#### IoT --> S3
The current [Sump Data](https://github.com/nobudev7/sumpdata) system used a RaspberryPi as a monitoring device, and sends the current water level every minutes to a server. On top, it sends 1 day worth of data to the same server in case there was any missing data points.
I will replace this with either IoT --> S3 directly. However, I might create a small Lambda Function if I find some processing necessary.
This needs a proper IAM setting for API access and permission. (To be documented later)


#### Lambda Function
I'll set up a Lambda function that is triggered by the new data on S3. It'll be a process that takes the new data, and update the water level chart for the day. I might set this up such a way that it runs every time the new data is uploaded (= every minute), or perhaps only every 10 minutes, depending on the processing time and cost of Lambda.

### Website
[The current website](https://sumpdata.nobudev7.com/) is hosted on a Nginx server with Streamlit as a frontend visualization. The plan is to replace it with static S3 based website. The above Lambda Function creates charts, and static HTML and CSS will be placed in a same folder that is exposed as a website. A small JavaScript code will get the most up-to-date list of charts, and show the year and month as the table of contents on the web page. It will look similar to the current website, however, everything will be statistically saved on S3, so where will be no server to maintain.


