generate "backend" {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
terraform {
    backend "s3" {
        bucket         = "${get_env("TF_VAR_STATE_BUCKET_NAME")}"
        region         = "${get_env("TF_VAR_STATE_BUCKET_REGION")}"
        key            = "${path_relative_to_include()}/terraform.tfstate"
    }
}
EOF
}