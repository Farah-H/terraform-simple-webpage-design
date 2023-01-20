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

## Iteration 3: Collaboration (Stakeholders: Devs / Maintainers)

There are a few things up until this point which naturally made the code easier to maintain and collaborate on, e.g modularisation, it being on Github etc. 

At this stage I also introduced terraform state locking using dynamodb, to protect the state file from corruption due to multiple conflicting writes. 
#### Env seperation
I created a development environment, and used conditional count parameters to ensure this env doesn't have the same level of monitoring that production does. This is for cost saving but also "not getting email spam" reasons. 

It is worth noting that altough terraform workspaces, env variables, and simply having different CIDR ranges can all be used for env seperation, I have found that seperation via different AWS accounts (under the same org) and via seperate directories is the most fool-proof. 

AWS Org at this point should look like: 
- Root Account
  - Management Account
  - rapha-prod (where this infra is being build)
  - rapha-dev 

#### Credentials
In terms of secret / access keys, they can be used as a resource to prevent devs from building infrastructure locally. Groups can be used to manage access to (especially prod) resources, and those permisions will control what actions devs are allowed to take using terraform. Terraform has an `sts assume role` provider support now, which means each dev only needs one set of credentials which they can use to assume prod or dev env. 

1pass, LastPass or something like Hashicorp Vault can be used to improve the security and rotation of those secrets. 

#### Branching and Static Code Analysis
There has been a `main` branch until now, but it has not been protected with branch rules. I've added a few such as `require PR before merge` and `new commits dismiss approvals`. 

This is also a great place to implement some static code analysis tools such as StyleCI, Codacy, or bespoke rules using jenkins pipelines for example, to help protect code quality. (Terraform Cloud has Sentinel, but because that runs policy checks after the code is merged, it's a little redundant)

There is no need for a dedicated "dev" branch because the env seperation is done via directories in this case. 

#### Deployments
It is good practice for TF to be ran using some central, highly visible, resource, rather than locally. Any CI/CD tool will do here, as long as the relevant protections and access is managed. Dependency management is less of a problem in terraform becuase of the `lock.hcl` file, however if there are other dependencies to manage it may be helpful to have a container which can act as a local testing environment for devs. 

Finally, modules can be sourced from GitHub repositories as well, so if this code starts to get too large, or these modules need to be used elsewhere, it can be seperated out into its own repository. It may also be helpful to break it up even further, depending on how much granuality is needed. 
