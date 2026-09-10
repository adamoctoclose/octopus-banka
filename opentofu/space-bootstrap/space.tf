resource "octopusdeploy_space" "this" {
  name        = var.space_name
  description = var.space_description != "" ? var.space_description : "Created by OpenTofu for ${var.space_name}."

  # These three are optional+computed in the provider, so passing `null` means
  # "leave whatever Octopus chose" rather than "set to empty".
  slug                        = var.space_slug != "" ? var.space_slug : null
  space_managers_teams        = length(var.space_managers_teams) > 0 ? var.space_managers_teams : null
  space_managers_team_members = length(var.space_managers_team_members) > 0 ? var.space_managers_team_members : null

  is_default = false

  # Octopus refuses to delete a space while its task queue is running. Leaving
  # this false keeps the space usable; see the README for how to destroy.
  is_task_queue_stopped = false
}
