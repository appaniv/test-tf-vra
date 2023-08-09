# Aria Automation Integration with Terraform 

## Objective
Use of this code is to deploy cloud components  on AWS cloud 
## Assumptions 
* Terraform is already installed
* GitHub Intergration is configured on Aria Automation
* Cloud account is configure with AWS credentails and tested
## What will happen when deployment calls terraform code? 

* A security group is configured
* EC2 instance is configured
* AWS Transit Gateway is configured
* Aurora database is configured
* A lambda function is created with nodejs function. Reaching lambda function on public interface will provide classic 'hello world' output
