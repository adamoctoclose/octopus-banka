locals {
  # Keyed by name so the map is stable if the list is reordered, plus the index
  # so we can drive sort order and lifecycle phase order from the list.
  environments = {
    for index, environment in var.environments :
    environment.name => merge(environment, { sort_order = index })
  }
}

resource "octopusdeploy_environment" "this" {
  for_each = local.environments

  space_id                     = octopusdeploy_space.this.id
  name                         = each.value.name
  description                  = each.value.description
  allow_dynamic_infrastructure = each.value.allow_dynamic_infrastructure
  use_guided_failure           = each.value.use_guided_failure
  sort_order                   = each.value.sort_order
}
