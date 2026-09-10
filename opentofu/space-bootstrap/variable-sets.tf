##
## Library variable sets
##
## `octopusdeploy_variable` attaches a variable to an owner. For a library
## variable set the owner is the set's own ID, which also makes OpenTofu order
## the set before its variables.
##

variable "shared_api_key" {
  type        = string
  description = "Placeholder secret written into the sensitive variable example. Replace with a value from your secret store."
  sensitive   = true
  default     = "replace-me"
}

##
## Set 1: shared configuration - plain, scoped, and sensitive variables.
##

resource "octopusdeploy_library_variable_set" "shared_configuration" {
  space_id    = octopusdeploy_space.this.id
  name        = "Shared Configuration"
  description = "Values shared by every project in this space."
}

# Unscoped: the same value everywhere.
resource "octopusdeploy_variable" "organisation_name" {
  space_id = octopusdeploy_space.this.id
  owner_id = octopusdeploy_library_variable_set.shared_configuration.id

  name        = "Shared.Organisation.Name"
  type        = "String"
  value       = "Example Organisation"
  description = "Display name used in deployment notifications."
}

# Environment-scoped: one variable resource per environment, same variable
# name, different value. Octopus picks the matching one at deployment time.
resource "octopusdeploy_variable" "base_url" {
  for_each = local.environments

  space_id = octopusdeploy_space.this.id
  owner_id = octopusdeploy_library_variable_set.shared_configuration.id

  name        = "Shared.Application.BaseUrl"
  type        = "String"
  value       = "https://${lower(each.key)}.example.com"
  description = "Base URL of the application in the ${each.key} environment."

  scope {
    environments = [octopusdeploy_environment.this[each.key].id]
  }
}

resource "octopusdeploy_variable" "log_level" {
  for_each = local.environments

  space_id = octopusdeploy_space.this.id
  owner_id = octopusdeploy_library_variable_set.shared_configuration.id

  name  = "Shared.Logging.Level"
  type  = "String"
  value = each.value.use_guided_failure ? "Warning" : "Debug"

  scope {
    environments = [octopusdeploy_environment.this[each.key].id]
  }
}

# Sensitive: `value` is left unset and `sensitive_value` is used instead.
# Octopus never returns the value once written, so OpenTofu cannot detect
# drift on it - changing `shared_api_key` is what triggers an update.
resource "octopusdeploy_variable" "shared_api_key" {
  space_id = octopusdeploy_space.this.id
  owner_id = octopusdeploy_library_variable_set.shared_configuration.id

  name            = "Shared.Api.Key"
  type            = "Sensitive"
  is_sensitive    = true
  sensitive_value = var.shared_api_key
  description     = "Placeholder secret - repoint at your secret store before real use."
}

##
## Set 2: standard parameters - templates (variable set parameters) plus a
## prompted variable, showing both ways of collecting input.
##

resource "octopusdeploy_library_variable_set" "standard_parameters" {
  space_id    = octopusdeploy_space.this.id
  name        = "Standard Parameters"
  description = "Parameters every project or tenant is expected to supply."

  # Templates become per-tenant / per-project parameters that Octopus prompts
  # for when the set is attached.
  template {
    name          = "Standard.ServiceName"
    label         = "Service name"
    help_text     = "Short lowercase name of the service being deployed."
    default_value = "example-service"

    display_settings = {
      "Octopus.ControlType" = "SingleLineText"
    }
  }

  template {
    name          = "Standard.InstanceCount"
    label         = "Instance count"
    help_text     = "How many instances of the service to run."
    default_value = "2"

    display_settings = {
      "Octopus.ControlType" = "SingleLineText"
    }
  }

  template {
    name          = "Standard.EnableFeatureFlags"
    label         = "Enable feature flags"
    help_text     = "Turn the feature flag client on for this deployment."
    default_value = "False"

    display_settings = {
      "Octopus.ControlType" = "Checkbox"
    }
  }
}

# A prompted variable is answered at deployment time rather than being stored.
resource "octopusdeploy_variable" "change_reference" {
  space_id = octopusdeploy_space.this.id
  owner_id = octopusdeploy_library_variable_set.standard_parameters.id

  name = "Standard.ChangeReference"
  type = "String"

  prompt {
    label       = "Change reference"
    description = "Ticket or change request this deployment is associated with."
    is_required = true

    display_settings {
      control_type = "SingleLineText"
    }
  }
}

resource "octopusdeploy_variable" "deployment_mode" {
  space_id = octopusdeploy_space.this.id
  owner_id = octopusdeploy_library_variable_set.standard_parameters.id

  name  = "Standard.DeploymentMode"
  type  = "String"
  value = "Rolling"

  prompt {
    label       = "Deployment mode"
    description = "How the new version should be rolled out."
    is_required = true

    display_settings {
      control_type = "Select"

      select_option {
        value        = "Rolling"
        display_name = "Rolling"
      }

      select_option {
        value        = "BlueGreen"
        display_name = "Blue / green"
      }

      select_option {
        value        = "AllAtOnce"
        display_name = "All at once"
      }
    }
  }
}
