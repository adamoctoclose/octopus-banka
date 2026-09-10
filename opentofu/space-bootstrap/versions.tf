terraform {
  # OpenTofu 1.6 is the first release; 1.6+ gives us `optional()` object
  # attributes, which the `environments` variable relies on.
  required_version = ">= 1.6.0"

  required_providers {
    octopusdeploy = {
      source = "OctopusDeploy/octopusdeploy"
      # Pinned deliberately. 1.19.x is where lifecycle retention moved to the
      # `*_with_strategy` blocks used in lifecycles.tf.
      version = "~> 1.19"
    }
  }

  # State must live somewhere durable when this runs from a runbook - the
  # runbook's working directory is thrown away after every execution, so
  # without a remote backend every run would try to create the space again.
  # Uncomment and configure one of these (or pass `-backend-config` flags from
  # the runbook step).
  #
  # backend "s3" {
  #   bucket = "my-tofu-state"
  #   key    = "octopus/space-bootstrap.tfstate"
  #   region = "us-east-1"
  # }
  #
  # backend "azurerm" {
  #   resource_group_name  = "my-rg"
  #   storage_account_name = "mytofustate"
  #   container_name       = "tfstate"
  #   key                  = "octopus/space-bootstrap.tfstate"
  # }
}
