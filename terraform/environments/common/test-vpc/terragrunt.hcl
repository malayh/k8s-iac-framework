terraform {
    source = "${get_terragrunt_dir()}/../../../modules/aws-vpc"
}


include {
  path = find_in_parent_folders()
}

inputs = {
    name = "staging-vpc"
    cidr_block = "10.165.0.0/16"
    enable_nat_instance = true
}

generate "provider" {
    path = "provider.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
provider "aws" {
    region = "ap-south-1"
}
EOF
}