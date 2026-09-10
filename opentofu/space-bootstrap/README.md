# Space bootstrap (OpenTofu)

Creates an Octopus Deploy space and its baseline configuration in a single
apply. The space name is an input variable, so the whole thing can be driven
from an Octopus runbook with a prompted variable.

## What it creates

| Resource | Detail |
| --- | --- |
| Space | Named from `space_name`, optional slug, managed by the built-in `teams-managers` team |
| Environments | `Development`, `Test`, `Production` by default, in promotion order |
| Lifecycle: `Application Lifecycle` | One phase per environment, generated from the `environments` variable |
| Lifecycle: `Hotfix Lifecycle` | Single phase containing every environment, no promotion gates |
| Library variable set: `Shared Configuration` | Unscoped, environment-scoped, and sensitive variables |
| Library variable set: `Standard Parameters` | Three templates (parameters) plus two prompted variables |

Octopus also creates a `Default Lifecycle` and a `Default Project Group` inside
every new space automatically. These are not managed here, and the lifecycle
names above are chosen so they do not collide.

## Files

| File | Purpose |
| --- | --- |
| [versions.tf](versions.tf) | OpenTofu and provider version constraints, backend placeholder |
| [providers.tf](providers.tf) | Provider configuration |
| [variables.tf](variables.tf) | Inputs, including `space_name` |
| [space.tf](space.tf) | The space |
| [environments.tf](environments.tf) | Environments, plus the `local.environments` map everything else keys off |
| [lifecycles.tf](lifecycles.tf) | Both lifecycles |
| [variable-sets.tf](variable-sets.tf) | Library variable sets and their variables |
| [outputs.tf](outputs.tf) | IDs to capture as runbook output variables |

## Requirements

- OpenTofu 1.6+ (or Terraform 1.6+ - the configuration is compatible with both)
- `OctopusDeploy/octopusdeploy` provider `~> 1.19`
- Octopus Server **2025.3 or newer**. Lifecycle retention uses the
  `release_retention_with_strategy` / `tentacle_retention_with_strategy`
  blocks. On an older server, replace them with
  `release_retention_policy` / `tentacle_retention_policy`
  (`quantity_to_keep`, `should_keep_forever`, `unit`) and set
  `TF_OCTOPUS_DEPRECATION_REVERSALS=octopusdeploy_lifecycles.retention_policy`.
- An API key belonging to a user who can create spaces (`SpaceEdit` at the
  system level). The creating user becomes a space manager automatically.

## Running it locally

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit it
tofu init
tofu plan
tofu apply
```

Or without a tfvars file:

```bash
export TF_VAR_octopus_address="https://my.octopus.app"
export TF_VAR_octopus_api_key="API-XXXX"
export TF_VAR_space_name="Example Space"

tofu init
tofu apply -auto-approve
```

## Running it from an Octopus runbook

Every input maps to a `TF_VAR_` environment variable, so no template file or
`-var` juggling is needed.

1. **Prompted variable** on the runbook - name it `SpaceName`, type
   *Single-line text*, mark it required.
2. **Project variables** for the connection:
   - `Octopus.Address` -> `#{Octopus.Web.ServerUri}` (or the URL directly)
   - `Octopus.ApiKey` -> a sensitive variable holding the API key
3. **Terraform Apply step** pointed at this directory, with these
   *Additional Variables* / environment variables:

   ```
   TF_VAR_octopus_address = #{Octopus.Address}
   TF_VAR_octopus_api_key = #{Octopus.ApiKey}
   TF_VAR_space_name      = #{SpaceName}
   TF_IN_AUTOMATION       = true
   ```

4. **Configure a remote backend** (see the commented block in
   [versions.tf](versions.tf)). The runbook's working directory is discarded
   after each execution, so without remote state a second run will try to
   create the space again and fail on the duplicate name. Either uncomment a
   backend block or pass `-backend-config` values from the step's *Custom
   parameters*.
5. **Capture the outputs** if later steps need them. The Octopus Terraform
   steps expose outputs as
   `Octopus.Action[Apply Space].Output.TerraformValueOutputs[space_id]`.

### Managing more than one space

State is per-space here, so give each space its own state key - for example
`octopus/spaces/#{SpaceName | ToLower}.tfstate` in the backend key, or use a
separate workspace per space (`tofu workspace select -or-create "#{SpaceName}"`).
Sharing one state file across spaces will cause the second run to delete the
first space.

## Notes and gotchas

- **A space must have a manager.** Octopus rejects the create call with
  *"Please select either teams and/or users as managers of this space"* if none
  is supplied - it does not fall back to the calling user. [space.tf](space.tf)
  hardcodes the built-in `teams-managers` team. To name specific users instead,
  add `space_managers_team_members = ["Users-1"]` to the resource.
- **Space name length.** Octopus limits space names to 20 characters. The
  `space_name` variable validates this up front so the runbook fails fast with
  a clear message instead of an API error.
- **`space_id` on the provider is deliberately unset.** The space does not
  exist when the provider is configured, so it cannot be targeted there. Every
  resource sets `space_id` explicitly instead.
- **Sensitive variables cannot be read back.** Octopus never returns
  `sensitive_value`, so OpenTofu cannot detect drift on `Shared.Api.Key`.
  Changing the `shared_api_key` input is what triggers an update. Point it at
  your secret store rather than committing a value.
- **Environment order is significant.** The list order in `environments` sets
  both `sort_order` on the environments and the phase order of
  `Application Lifecycle`. The map is keyed by name, so reordering the list
  will not recreate environments, but renaming one will.
- **Destroying.** Octopus refuses to delete a space while its task queue is
  running. Set `is_task_queue_stopped = true` in [space.tf](space.tf), apply,
  then destroy.
