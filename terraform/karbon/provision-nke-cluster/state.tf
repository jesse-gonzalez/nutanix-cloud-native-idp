terraform {
  backend "s3" {
    endpoint = "https://ntnx-objects.ntnxlab.local"
    bucket = "terraform"
    key = "terraform.tfstate"
    region = "us-east-1"
    #force_path_style = true
    skip_requesting_account_id = true
    skip_credentials_validation = true
    skip_get_ec2_platforms = true
    skip_metadata_api_check = true
    skip_region_validation = true
  }
}


