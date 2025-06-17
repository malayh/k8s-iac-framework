variable "name" {
  description = "Name of the cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EKS cluster"
  type        = list(string)
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Node groups configuration"
  type = map(object({
    instance_type = string
    count         = number
    taint = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
}