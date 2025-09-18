locals {
    config = yamldecode(file("env-config.yaml"))
}

provider "aws" {
    region = local.config.region
    default_tags {
        tags = {
            project = local.config.project
        }
    }
}


module "fis" {
  source = "./modules/fis"
  config = local.config
}