# Variables for configuration:
variable "region2_vpc_cidr" {
  description = "CIDR block for the Region 2 VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "region1_vpc_id" {
  description = "ID of the existing Region 1 VPC"
  type        = string
  default     = "vpc-XXX"
}
