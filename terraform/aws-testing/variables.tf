variable "aws_region" {
  default = "us-east-2"
}

variable "identifier" {
  default     = "mydb-rds"
  description = "Identifier for your DB"
}

variable "allocated_storage" {
  default     = "20"
  description = "Identifier for your DB"
}

variable "engine" {
  default     = "aurora-mysql"
  description = "Engine type, example values mysql, postgres"
}

variable "engine_version" {
  description = "Engine version"

  default = {
    aurora-mysql    = "5.7.mysql_aurora.2.11.2"
    postgres = "9.6.8"
  }
}

variable "instance_class" {
  default     = "db.t3.small"
  description = "Instance class"
}

variable "db_name" {
  default     = "mydb"
  description = "db name"
}

variable "username" {
  default     = "myuser"
  description = "User name"
}
variable "dbinstancecount" {
  default     = "1"
  description = "Number of DB Instances"
}

variable "password" {
  description = "password, provide through your ENV variables"
  default     = "Hello#123"
}


variable "database_name" {
  type        = string
  description = "Database name"
	default  = "testDB"
}

variable "master_username" {
  type        = string
  description = "DB User ID"
	default  = "username"
}

variable "master_password" {
  type        = string
  description = "DB Password"
	default  = "change_me_2023"
}


