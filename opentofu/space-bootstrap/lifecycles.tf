##
## Lifecycles
##
## Octopus creates a "Default Lifecycle" automatically inside every new space,
## so the lifecycles here use distinct names to avoid colliding with it.
##
## Retention uses the `*_with_strategy` blocks (provider 1.19+ / Octopus
## 2025.3+). Valid `strategy` values are:
##   "Count"   - keep `quantity_to_keep` of `unit` ("Days" or "Items")
##   "Forever" - never delete; `quantity_to_keep` must be omitted
##   "Default" - inherit the space default; `quantity_to_keep` must be omitted
##
## On an Octopus server older than 2025.3, swap these for the legacy
## `release_retention_policy` / `tentacle_retention_policy` blocks and set
## TF_OCTOPUS_DEPRECATION_REVERSALS=octopusdeploy_lifecycles.retention_policy.

# Standard promotion path: one phase per environment, in the order the
# `environments` variable lists them.
resource "octopusdeploy_lifecycle" "application" {
  space_id    = octopusdeploy_space.this.id
  name        = "Application Lifecycle"
  description = "Promotes releases through ${join(" -> ", [for e in var.environments : e.name])}."

  release_retention_with_strategy {
    strategy         = "Count"
    quantity_to_keep = var.release_retention_days
    unit             = "Days"
  }

  tentacle_retention_with_strategy {
    strategy         = "Count"
    quantity_to_keep = var.tentacle_retention_items
    unit             = "Items"
  }

  dynamic "phase" {
    for_each = var.environments

    content {
      name = phase.value.name

      # Every environment in a phase belongs to exactly one of these lists.
      # Automatic targets deploy as soon as the release reaches the phase;
      # optional targets wait to be deployed manually.
      automatic_deployment_targets = phase.value.deploy_automatically ? [octopusdeploy_environment.this[phase.value.name].id] : []
      optional_deployment_targets  = phase.value.deploy_automatically ? [] : [octopusdeploy_environment.this[phase.value.name].id]

      # The first phase has nothing to be promoted from. Later phases require
      # one successful deployment in the previous phase before they unlock.
      minimum_environments_before_promotion = phase.key == 0 ? 0 : 1
      is_optional_phase                     = false
    }
  }
}

# Hotfix path: a single phase containing every environment, so a release can go
# straight to any of them without walking the promotion chain.
resource "octopusdeploy_lifecycle" "hotfix" {
  space_id    = octopusdeploy_space.this.id
  name        = "Hotfix Lifecycle"
  description = "Allows a release to be deployed to any environment without promotion gates."

  release_retention_with_strategy {
    strategy         = "Count"
    quantity_to_keep = var.release_retention_days
    unit             = "Days"
  }

  tentacle_retention_with_strategy {
    strategy = "Default"
  }

  phase {
    name                                  = "Any Environment"
    optional_deployment_targets           = [for name, environment in octopusdeploy_environment.this : environment.id]
    minimum_environments_before_promotion = 0
    is_optional_phase                     = false
  }
}
