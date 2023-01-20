# Simple Webserver Deployment Using Terraform
### Introduction and Flow 
I've broken this task up into several iterations to address the discussion points. The best way to understand this flow is by navigating the `commits` section in GitHub, where the iterations are labelled. Security is addressed throughout. 
1. Minimum Requirements
2. Stakeholder : Users
3. Stakeholder : Devs / Maintainers
### Pre-requisites 
Note: The following cli commands and code snippets are specific to unix (specifically a Mac) terminal. This workflow is possible on any device, although the syntax may change slightly.

To run this code, you need the following
- [Terraform v1.2.X](https://developer.hashicorp.com/terraform/downloads) installed
- An AWS Account with [Access and Secret keys](https://aws.amazon.com/premiumsupport/knowledge-center/create-access-key/) set up 
- An S3 bucket in the account with the same name `farah-terraform-state-files-rapha`. Alternatively you can comment out this entire `backend` section in the `terraform.tf` file and TF will default to local state management. 

Save your AWS Keys in an `~/.aws/credentials` file (or wherever you keep your `.aws` directory), in the following format: 
```
[rapha-prod]
aws_access_key_id=<your-access-key>
aws_secret_access_key=<your-secret-key>
```
Here, `[rapha-prod]` indicates a *profile*. You need to switch to this profile using the following command. **Note**: this will not be persisted across terminal sessions. 
```bash
export AWS_PROFILE=rapha-prod
```
From this point on, terraform will automatically interact with AWS using these credentials. 

## Iteration 1: Min Requirements

Using Terraform to build and  `user data` to provision a public-facing instance and output its URL. 

The instance resides in a very simple, and mostly open, VPC structure, where there is 1 public subnet, an igw, NACL rules and Security Group rules. 

The AWS Org structure is:
- Root Account
  - Management Account
  - rapha-prod (where this infra is being build)

It's also a pretty ugly "Hello World" page. 

**Security:**
- There are no plaintext secrets in the code
- SGs and NACL are completely open
- No loadbalancing or Auto-Scaling (vulnterable to DoS attacks and failure due to high traffic)
- No monitoring of either the infra or AWS Account
- State file is encrypted at rest
- Using HTTP protocol (no SSL cert or encryption of data in transit)

## Iteration 2: Visibility + Usability (Stakeholder : User)

Two important points here: 
1. Site needs to be highly available
2. SEO is affected by site performance and structure, not just content

High Availability can be hindered by the following: 
- Downtime during deployment 
  - Improved by adding `create_before_destroy` parameter in ASG
- Failure due to high demand
  - Improved by adding auto-scaling across AZs
- Failure due to external DoS attack
  - Improved resilience by adding a load balancer
- AWS-side / Regional outage
  - Improved by scaling across AZs and deploying in multiple regions. 
- Low observability
  - Improved by adding simple monitoring alarms, which trigger scaling actions. 

#### Latency
There are two immediate ways to improve latency and customer experience
- Obtain an SSL certificate and domain to be able to use HTTPS protocol, which enables the traffic to use HTTP2 (newer and faster). 
- Use Route53 (or another DNS routing service) to a) have a user-friendly site url and b) route a user's traffic to their nearest data-centre. 

**Security:** Also closed up the SG slightly, it is still publicly available, but only over ports 80 and 443. Importantly, SSH access is completely closed. 

