resource "octopusdeploy_space" "this" {
  name        = var.space_name
  description = var.space_description != "" ? var.space_description : "Created by OpenTofu for ${var.space_name}."

  # `slug` is optional+computed, so `null` means "let Octopus generate one"
  # rather than "set it to empty".
  slug = var.space_slug != "" ? var.space_slug : null

  # Octopus requires at least one manager. The API rejects the space with
  # "Please select either teams and/or users as managers of this space" when
  # this is omitted - it does not fall back to the calling user.
  # `teams-managers` is the built-in Octopus Managers team.
  space_managers_teams = ["teams-managers"]

  is_default = false

  # Octopus refuses to delete a space while its task queue is running. Leaving
  # this false keeps the space usable; see the README for how to destroy.
  is_task_queue_stopped = false
}
