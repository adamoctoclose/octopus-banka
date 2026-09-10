provider "octopusdeploy" {
  address = var.octopus_address
  api_key = var.octopus_api_key

  # NOTE: `space_id` is intentionally left unset so the provider talks to the
  # default space for server-level operations. The space created here does not
  # exist when the provider is configured, so it cannot be targeted here.
  # Every resource below sets `space_id` explicitly instead.
}
