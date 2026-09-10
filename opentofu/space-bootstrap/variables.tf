##
## Connection
##

variable "octopus_address" {
  type        = string
  description = "Base URL of the Octopus Deploy server, e.g. https://my.octopus.app"

  validation {
    condition     = can(regex("^https?://", var.octopus_address))
    error_message = "octopus_address must be a URL starting with http:// or https://."
  }
}

variable "octopus_api_key" {
  type        = string
  description = "Octopus Deploy API key. Needs permission to create spaces (a Space Manager on the new space is granted automatically to the creating user)."
  sensitive   = true
}

##
## The space
##
## `space_name` is the parameter the runbook supplies. Everything else is
## derived from it or has a sensible default.
##

variable "space_name" {
  type        = string
  description = "Name of the space to create. Supplied by the runbook prompted variable."

  validation {
    condition     = length(trimspace(var.space_name)) > 0 && length(var.space_name) <= 20
    error_message = "space_name must be between 1 and 20 characters - Octopus limits space names to 20 characters."
  }
}

variable "space_description" {
  type        = string
  description = "Description applied to the space. Defaults to a generated description when left empty."
  default     = ""
}

variable "space_slug" {
  type        = string
  description = "Optional URL slug for the space. Octopus generates one from the name when left empty."
  default     = ""
}

##
## Environments
##
## Order matters: the list order becomes the environment sort order and the
## phase order of the generated lifecycle.
##

variable "environments" {
  type = list(object({
    name                         = string
    description                  = optional(string, "")
    allow_dynamic_infrastructure = optional(bool, true)
    use_guided_failure           = optional(bool, false)

    # Lifecycle behaviour only - does not affect the environment itself.
    # true  => releases are deployed to this environment automatically when
    #          they reach its phase.
    # false => the deployment is triggered manually (or by a pipeline).
    deploy_automatically = optional(bool, false)
  }))
  description = "Environments to create in the space, in promotion order."

  default = [
    {
      name                         = "Development"
      description                  = "Developer integration environment."
      allow_dynamic_infrastructure = true
      use_guided_failure           = false
      deploy_automatically         = true
    },
    {
      name                         = "Test"
      description                  = "Shared test environment."
      allow_dynamic_infrastructure = true
      use_guided_failure           = false
      deploy_automatically         = false
    },
    {
      name                         = "Production"
      description                  = "Customer facing environment."
      allow_dynamic_infrastructure = false
      use_guided_failure           = true
      deploy_automatically         = false
    },
  ]

  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment is required - the lifecycle phases are generated from this list."
  }

  validation {
    condition     = length(distinct([for e in var.environments : e.name])) == length(var.environments)
    error_message = "Environment names must be unique - they are used as resource keys."
  }
}

##
## Retention
##

variable "release_retention_days" {
  type        = number
  description = "How many days of releases to keep on the generated lifecycles."
  default     = 30
}

variable "tentacle_retention_items" {
  type        = number
  description = "How many deployments' worth of files to keep on deployment targets."
  default     = 10
}
