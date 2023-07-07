terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
 
}





# Create a security group for the Ubuntu instance
resource "aws_security_group" "ubuntu_instance_sg" {
  name        = "ubuntu_instance_sg"
  description = "Security group for Ubuntu instance"
  vpc_id = "vpc-55229428"

  # Allow SSH access to the test Ubuntu instance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ubuntu instance with AMI ami-053b0d53c279acc90
resource "aws_instance" "ubuntu_instance" {
  ami           = "ami-053b0d53c279acc90" 
  instance_type = "t2.micro"
  key_name      = "vj-key-pair"
  subnet_id     = "subnet-3b3b0e76" #subnet from console for vpc vpc-55229428 us-east-1c
  vpc_security_group_ids = [aws_security_group.ubuntu_instance_sg.id]

  # Use user data to install OpenSSH server on the instance
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y openssh-server
  
  EOF
}


## RDS Cluster with 2 instance 
resource "aws_rds_cluster" "terraform-rds-cluster" {
  cluster_identifier = "rds-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "13.6"
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password
	skip_final_snapshot = "true"

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "rds_instance" {
  count              = var.dbinstancecount
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.terraform-rds-cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.terraform-rds-cluster.engine
  engine_version     = aws_rds_cluster.terraform-rds-cluster.engine_version
}



# Output the public IP of the Ubuntu instance
output "public_ip" {
 value = aws_instance.ubuntu_instance.public_ip
}





## Lambda function and API gateway
# //terraform-serverless-example-vcf-tf-07-07-23/v1.0.0/serverless-aws-lambda-api-gw.zip
resource "aws_lambda_function" "example" {
  function_name = "ServerlessExample"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "terraform-serverless-example-vcf-tf-07-07-23"
  s3_key    = "v1.0.0/serverless-aws-lambda-api-gw.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs18.x"

  role = "${aws_iam_role.lambda_exec.arn}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.example.invoke_arn}"
}


resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.example.invoke_arn}"
}


resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  stage_name  = "test"
}


resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
