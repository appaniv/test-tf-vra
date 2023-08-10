# Aria Automation Integration with Terraform 

## Objective
Use of this code is to deploy cloud components  on AWS cloud 
## Assumptions 
* Terraform is already installed
* GitHub Intergration is configured on Aria Automation
* Cloud account is configure with AWS credentails and tested
## What will happen when deployment calls terraform code? 

* A security group is configured
* EC2 instance is configured and security group is attached with EC2 instance allowing SSH'ing into ubuntu instance with keypair already created 
* AWS Transit Gateway is configured
* Aurora database is configured
* A lambda function is created with nodejs function. Reaching lambda function on public interface will provide classic 'hello world' output

## Testing
* List lambda function:  `aws lambda list-functions --region us-east-1 | jq -r '.Functions[].FunctionName' |cat -n`
* Execute lambda funciton : `aws lambda invoke --region=us-east-1 --function-name=ServerlessExample output.txt`
  Note: lambda function name is : ServerlessExample
* Logging into Ubuntu instance : ssh -i ~/aws-key-pair.pem ubuntu@public-ip-address-of-ec2
  
  
