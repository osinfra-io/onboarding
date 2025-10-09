# Local Values
# https://opentofu.org/docs/language/values/locals
#
# Transforms team structure into flattened maps for resource creation using Team Topologies methodology.
# All locals are organized alphabetically for easy navigation and maintenance.

locals {

  # Flatten Datadog team memberships with role handling and deduplication
  datadog_team_memberships = { for membership in flatten([
    for team_key, team in local.datadog_teams : concat(
      [
        for user_email in team.admins : {
          key     = "${team_key}-${replace(user_email, "@", "-at-")}-admin"
          team_id = team_key
          user_id = user_email
          role    = "admin"
        }
      ],
      [
        for user_email in setsubtract(toset(team.members), toset(team.admins)) : {
          key     = "${team_key}-${replace(user_email, "@", "-at-")}-member"
          team_id = team_key
          user_id = user_email
          role    = "member"
        }
      ]
    )
  ]) : membership.key => membership }

  # Create Datadog teams for each top-level team with hardcoded definitions and customizable membership
  datadog_teams = {
    for team_key, team in var.team : team_key => {
      name        = "${local.team_type_labels[team.team_type]}: ${team.display_name}"
      description = "${team.display_name} is a ${local.team_type_labels[team.team_type]} ${local.team_topologies_descriptions[team.team_type]}."
      handle      = "${local.team_type_short_names[team.team_type]}-${team_key}"
      admins      = team.datadog_team.admins
      members     = team.datadog_team.members
    }
  }

  # Flatten all unique Datadog users from all teams for user lookup
  datadog_users = toset(flatten([
    for team_key, team in local.datadog_teams : concat(team.admins, team.members)
  ]))

  # Flatten all environments from all teams into a single map
  # Creates keys like "onboarding-sandbox" for each team-environment combination
  # Structure: team_types → teams → hardcoded environments
  environments = { for environment in flatten([
    for team_key, team in var.team : [
      for environment in ["Sandbox", "Non-production", "Production"] : {
        team        = team_key
        environment = environment
      }
    ]
  ]) : "${environment.team}-${lower(environment.environment)}" => environment }

  # Flatten GitHub child team maintainer memberships
  github_child_team_maintainers = { for item in flatten([
    for team_key, team in local.github_child_teams : [
      for username in team.maintainers : { team_key = team_key, username = username, role = "maintainer" }
    ]
  ]) : "${item.team_key}-${item.username}" => item }

  # Flatten GitHub child team member memberships
  github_child_team_members = { for item in flatten([
    for team_key, team in local.github_child_teams : [
      for username in team.members : { team_key = team_key, username = username, role = "member" }
    ]
  ]) : "${item.team_key}-${item.username}" => item }

  # Flatten GitHub child teams with hardcoded definitions and customizable memberships
  github_child_teams = { for github_team in flatten([
    for team_key, team in var.team : [
      for github_team_key in ["sandbox-approver", "non-production-approver", "production-approver", "repository-administrators"] : {
        key         = "${team_key}-${github_team_key}"
        parent_team = team_key
        name        = github_team_key
        description = "${local.github_team_function_names[github_team_key]}."
        privacy     = "closed"
        maintainers = team.github_child_teams[github_team_key].maintainers
        members     = team.github_child_teams[github_team_key].members
      }
    ]
  ]) : github_team.key => github_team }

  # GitHub parent team memberships (configured members/maintainers plus child team maintainers)
  github_parent_team_memberships = { for item in flatten([
    for team_key, team in var.team : concat(
      # Configured parent team maintainers
      [
        for username in team.github_parent_team.maintainers :
        { team_key = team_key, username = username, role = "maintainer" }
      ],
      # Configured parent team members
      [
        for username in team.github_parent_team.members :
        { team_key = team_key, username = username, role = "member" }
      ],
      # Auto-add child team maintainers as members (deduplicated)
      [
        for username in distinct(flatten([
          for github_team_key, github_team in team.github_child_teams : github_team.maintainers
        ])) : { team_key = team_key, username = username, role = "member" }
        if !contains(concat(team.github_parent_team.maintainers, team.github_parent_team.members), username)
      ]
    )
  ]) : "${item.team_key}-${item.username}" => item }

  # Create parent GitHub teams for each team
  github_parent_teams = {
    for team_key, team in var.team : team_key => {
      name        = "${local.team_type_short_names[team.team_type]}-${team_key}"
      description = "${team.display_name} is a ${local.team_type_labels[team.team_type]} ${local.team_topologies_descriptions[team.team_type]}."
      privacy     = "closed"
    }
  }

  # GitHub team function names mapping
  github_team_function_names = {
    "sandbox-approver"          = "Sandbox GitHub Actions approvals"
    "non-production-approver"   = "Non-Production GitHub Actions approvals"
    "production-approver"       = "Production GitHub Actions approvals"
    "repository-administrators" = "Repository administration"
  }

  # Google Cloud role descriptions mapping
  google_role_descriptions = {
    "reader" = "Permissions for read-only actions that don't affect state, such as viewing (but not modifying) existing resources or data."
    "writer" = "All of the permissions in the Reader role, plus permissions for actions that modify state, such as changing existing resources."
    "admin"  = "All of the permissions in the Writer role, plus permissions for actions like the following: Completing sensitive tasks, like managing tag bindings for Compute Engine resources; Managing roles and permissions for a project and all resources within the project; Setting up billing for a project."
  }

  # Flatten IAM role bindings for team folder assignments (top-level team folders only)
  # Groups get access to entire team folder and all child environments
  iam_bindings = { for binding in flatten([
    for identity_group_key, group in local.identity_groups : [
      for role in group.roles : {
        binding_key = "${identity_group_key}-${replace(role, "/", "-")}"
        group_key   = identity_group_key
        team_key    = group.team
        role        = role
      }
    ]
  ]) : binding.binding_key => binding }

  # Flatten Google identity groups with hardcoded definitions and customizable membership
  # Creates exactly 3 groups per team: admin, writer, reader
  # Uses official Google Cloud role descriptions
  identity_groups = { for identity_group in flatten([
    for team_key, team in var.team : [
      for group_key in ["admin", "writer", "reader"] : {
        key          = "${team_key}-${group_key}"
        team         = team_key
        description  = local.google_role_descriptions[group_key]
        display_name = "${local.team_type_labels[team.team_type]}: ${team.display_name} ${title(group_key)}"
        managers     = team.google_identity_groups[group_key].managers
        members      = team.google_identity_groups[group_key].members
        owners       = team.google_identity_groups[group_key].owners
        roles        = ["roles/${group_key}"]
      }
    ]
  ]) : identity_group.key => identity_group }

  # Flatten identity group manager memberships
  managers = { for item in flatten([
    for group_key, group in local.identity_groups : [
      for user in group.managers : { group = group_key, user = user }
    ]
  ]) : "${item.group}-${item.user}" => { group = item.group, manager = item.user } }

  # Flatten identity group member memberships
  members = { for item in flatten([
    for group_key, group in local.identity_groups : [
      for user in group.members : { group = group_key, user = user }
    ]
  ]) : "${item.group}-${item.user}" => { group = item.group, member = item.user } }

  # Flatten identity group owner memberships
  owners = { for item in flatten([
    for group_key, group in local.identity_groups : [
      for user in group.owners : { group = group_key, user = user }
    ]
  ]) : "${item.group}-${item.user}" => { group = item.group, owner = item.user } }

  # Map team type keys to plural display names for folder creation
  # Used for team type folders (e.g., "Platform Teams", "Stream-aligned Teams")
  team_type_display_names = {
    "stream-aligned-team"        = "Stream-aligned Teams"
    "platform-team"              = "Platform Teams"
    "complicated-subsystem-team" = "Complicated-subsystem Teams"
    "enabling-team"              = "Enabling Teams"
  }

  # Helper: team type singular labels (removes "s" from display names)
  # Used throughout for consistent description formatting (e.g., "Platform Team" instead of "Platform Teams")
  team_type_labels = {
    for key, display_name in local.team_type_display_names :
    key => trimsuffix(display_name, "s")
  }

  # Map team type keys to short abbreviations for compact identifiers
  team_type_short_names = {
    "stream-aligned-team"        = "st"
    "platform-team"              = "pt"
    "complicated-subsystem-team" = "cst"
    "enabling-team"              = "et"
  }

  # Team Topologies descriptions mapping
  team_topologies_descriptions = {
    "stream-aligned-team"        = "aligned to a flow of work from (usually) a segment of the business domain"
    "platform-team"              = "providing a compelling internal product to accelerate delivery by Stream-aligned teams"
    "complicated-subsystem-team" = "where significant mathematics/calculation/technical expertise is needed"
    "enabling-team"              = "helps  Stream-aligned teams to overcome obstacles. Also detects missing capabilities"
  }

  # Extract unique team types from all teams to create team type folders
  # Results in a set like: ["platform-team", "stream-aligned-team"]
  team_types = toset([
    for team_key, team in var.team : team.team_type
  ])
}
