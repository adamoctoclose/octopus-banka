output "space_id" {
  description = "ID of the created space, e.g. Spaces-123."
  value       = octopusdeploy_space.this.id
}

output "space_name" {
  description = "Name of the created space."
  value       = octopusdeploy_space.this.name
}

output "space_slug" {
  description = "URL slug of the created space."
  value       = octopusdeploy_space.this.slug
}

output "space_url" {
  description = "Direct link to the new space."
  value       = "${trimsuffix(var.octopus_address, "/")}/app#/${octopusdeploy_space.this.id}"
}

output "environment_ids" {
  description = "Map of environment name to environment ID."
  value       = { for name, environment in octopusdeploy_environment.this : name => environment.id }
}

output "lifecycle_ids" {
  description = "Map of lifecycle name to lifecycle ID."
  value = {
    (octopusdeploy_lifecycle.application.name) = octopusdeploy_lifecycle.application.id
    (octopusdeploy_lifecycle.hotfix.name)      = octopusdeploy_lifecycle.hotfix.id
  }
}

output "library_variable_set_ids" {
  description = "Map of library variable set name to ID."
  value = {
    (octopusdeploy_library_variable_set.shared_configuration.name) = octopusdeploy_library_variable_set.shared_configuration.id
    (octopusdeploy_library_variable_set.standard_parameters.name)  = octopusdeploy_library_variable_set.standard_parameters.id
  }
}
