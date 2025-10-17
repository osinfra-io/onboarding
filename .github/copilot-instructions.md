# Onboarding Infrastructure as Code - AI Coding Guide

## Project Overview
This OpenTofu project automates team onboarding across Google Cloud, GitHub, and Datadog using **Team Topologies** methodology. It creates hierarchical organizational structures with consistent security, governance, and operational practices.

## Architecture & Core Concepts

### Team Topologies Structure
The project implements a 3-level Google Cloud folder hierarchy:
```
Top Level Folder → Team Type Folders → Team Folders → Environment Folders
                   (Platform Teams)    (Onboarding)   (Sandbox/Non-prod/Prod)
```

### Key Components Created
- **Google Cloud**: Folder hierarchy + Identity Groups (admin/writer/reader roles) + IAM bindings + Billing budgets
- **GitHub**: Parent teams + 4 child teams per team (sandbox/non-prod/prod approvers + repo admins) + Projects
- **Datadog**: Teams with admin/member roles + User management

### File Organization & Structure
- `main.tofu` - All resource definitions, organized with data sources first, then resources alphabetically by resource type
- `locals.tofu` - Complex data transformations from team configs to flat resource maps (alphabetically ordered)
- `variables.tofu` - Strongly typed team configuration with validation rules (alphabetically ordered)
- `outputs.tofu` - Output values (alphabetically ordered)
- `teams/*.tfvars` - Per-team configuration files (e.g., `pt-onboarding.tfvars`)

**Code Organization Standards:**
- **File structure**: All variables, outputs, locals, and tfvars must be in strict alphabetical order
- **main.tofu structure**: Data sources first, then resources alphabetically by resource type
- **Consistent ordering**: Maintains readability and makes code easier to navigate

## Development Workflows

### Team Configuration Pattern
Teams are defined in `teams/{team-prefix}-{team-name}.tfvars` following this structure:
```hcl
team = {
  team_key = {
    display_name = "Title Case Name"  # Must pass validation regex
    team_type    = "platform-team"    # One of 4 Team Topologies types

    # Hardcoded structures with customizable membership:
    github_parent_team = { maintainers = [], members = [] }
    github_child_teams = {
      sandbox-approver = { maintainers = [], members = [] }
      # ... 3 more hardcoded child teams
    }
    google_identity_groups = {
      admin = { managers = [], members = [], owners = [] }
      # ... writer, reader (3 hardcoded roles)
    }
    datadog_team = { admins = [], members = [] }
  }
}
```

### Validation & Deployment
- **Pre-commit hooks**: `tofu-fmt`, `tofu-validate` (see `.pre-commit-config.yaml`)
- **CI/CD**: Matrix deployment per team via `production.yml` workflow using reusable workflows
- **State management**: Per-team workspaces with GCS backend + KMS encryption

### Admin Protection Pattern
Organization owners/admins are **hardcoded in `locals.tofu`** and protected via lifecycle rules:
```hcl
# In locals.tofu
github_organization_owners = ["brettcurtis"]
datadog_organization_admins = ["brett@osinfra.io"]

# In main.tofu resources
lifecycle {
  prevent_destroy = true
  ignore_changes  = [role] # Prevent accidental demotion
}
```

## Development Guidelines

### Adding New Teams
1. Create new `.tfvars` file in `teams/` directory using naming convention `{team_prefix}-{team_name}.tfvars`
2. Add team to GitHub workflow matrix in `.github/workflows/production.yml`
3. Team type must be one of: `platform-team`, `stream-aligned-team`, `complicated-subsystem-team`, `enabling-team`

### Local Development Setup
```bash
# Speed up local validation with plugin cache
mkdir -p $HOME/.opentofu.d/plugin-cache
export TF_PLUGIN_CACHE_DIR=$HOME/.opentofu.d/plugin-cache

# Run pre-commit hooks locally
pre-commit run --all-files
```

### Understanding Data Transformations
The `locals.tofu` file contains complex flattening operations that transform nested team configs into flat resource maps. Key patterns:
- **Flattening loops**: `flatten([for team_key, team in var.team : [...]])`
- **Deduplication**: `setsubtract()`, `distinct()` for handling overlapping memberships
- **Key generation**: Consistent naming like `"${team_key}-${role}"` for resource identification

### Naming Conventions
- **Team prefixes**: `pt-` (platform), `st-` (stream-aligned), `cst-` (complicated-subsystem), `et-` (enabling)
- **Google Groups**: `{team_prefix}-{team_key}-{role}@{domain}`
- **GitHub Teams**: Parent `{team_prefix}-{team_key}`, Children `{parent}-{function}`
- **Folders**: Title case display names from team configuration

### Testing Changes
- Use `tofu plan -var-file=teams/{team}.tfvars` to test specific team configurations
- Check `locals.tofu` outputs for proper data transformation
- Validate against existing state before applying changes to production

## Common Patterns & Anti-Patterns
✅ **Do**: Use hardcoded admin lists in `locals.tofu` for protected users
✅ **Do**: Follow Team Topologies methodology for team classification
✅ **Do**: Use consistent key generation patterns in locals for resource mapping
✅ **Do**: Maintain alphabetical ordering in all configuration files
❌ **Don't**: Modify hardcoded structures (environments, roles, child team names)
❌ **Don't**: Remove admin protection without following 2-step removal process
❌ **Don't**: Skip validation rules - they enforce organizational standards
