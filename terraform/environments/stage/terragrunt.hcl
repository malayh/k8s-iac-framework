terraform {
    source = "${get_terragrunt_dir()}/../../modules/aws-eks"
}

include {
  path = find_in_parent_folders()
}

dependency "network" {
    config_path = "${get_parent_terragrunt_dir()}/common/test-vpc"
}

inputs = {
    name = "stage"
    vpc_id = dependency.network.outputs.vpc_id
    vpc_cidr_block = dependency.network.outputs.vpc_cidr_block
    public_subnet_ids = dependency.network.outputs.public_subnet_ids
    private_subnet_ids = dependency.network.outputs.private_subnet_ids
    node_groups = {
        ng0 = {
            instance_type = "t3.medium"
            count         = 2
        }
    }
}

