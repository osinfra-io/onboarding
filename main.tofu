# Data Sources
# https://opentofu.org/docs/language/data-sources

# Datadog Role Data Sources
# https://search.opentofu.org/provider/DataDog/datadog/latest/docs/data-sources/role

# Fetch all required Datadog roles
data "datadog_role" "this" {
  for_each = toset([
    "Datadog Admin Role",
    "Datadog Read Only Role",
    "Datadog Standard Role"
  ])

  filter = each.key
}

# Resources
# https://opentofu.org/docs/language/resources

# Datadog User Resource
# https://search.opentofu.org/provider/DataDog/datadog/latest/docs/resources/user

# Datadog User Management - Split resources for lifecycle protection
# Organization admins are protected from deletion to maintain platform access
# Datadog Organization Admins - Protected from deletion
resource "datadog_user" "admins" {
  for_each = toset(local.datadog_organization_admins)

  email = each.value
  name  = split("@", each.value)[0] # Use email prefix as name
  roles = [local.datadog_user_roles[each.value]]

  depends_on = [data.datadog_role.this]

  # Protect organization admins from accidental deletion
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [roles] # Prevent accidental role changes
  }
}

# Regular Datadog Users - Can be destroyed normally
resource "datadog_user" "this" {
  for_each = setsubtract(local.all_datadog_users, toset(local.datadog_organization_admins))

  email = each.value
  name  = split("@", each.value)[0] # Use email prefix as name
  roles = [local.datadog_user_roles[each.value]]

  depends_on = [data.datadog_role.this]
}

# Datadog Team Membership Resource
# https://search.opentofu.org/provider/DataDog/datadog/latest/docs/resources/team_membership

resource "datadog_team_membership" "this" {
  for_each = local.datadog_team_memberships

  team_id = datadog_team.this[each.value.team_id].id
  user_id = try(
    datadog_user.admins[each.value.user_id].id,
    datadog_user.this[each.value.user_id].id
  )
  role = each.value.role

  depends_on = [datadog_user.admins, datadog_user.this]
}

# Datadog Team Resource
# https://search.opentofu.org/provider/DataDog/datadog/latest/docs/resources/team

resource "datadog_team" "this" {
  for_each = local.datadog_teams

  name        = each.value.name
  description = each.value.description
  handle      = each.value.handle
}

# GitHub Team Membership Resource - Child Teams
# https://search.opentofu.org/provider/integrations/github/latest/docs/resources/team_membership

resource "github_team_membership" "child_maintainers" {
  for_each = local.github_child_team_maintainers

  team_id  = github_team.children[each.value.team_key].id
  username = each.value.username
  role     = each.value.role

  depends_on = [github_membership.owners, github_membership.members]
}

resource "github_team_membership" "child_members" {
  for_each = local.github_child_team_members

  team_id  = github_team.children[each.value.team_key].id
  username = each.value.username
  role     = each.value.role

  depends_on = [github_membership.owners, github_membership.members]
}

# GitHub Team Membership Resource - Parent Teams
# https://search.opentofu.org/provider/integrations/github/latest/docs/resources/team_membership

resource "github_team_membership" "parents" {
  for_each = local.github_parent_team_memberships

  team_id  = github_team.parents[each.value.team_key].id
  username = each.value.username
  role     = each.value.role

  depends_on = [github_membership.owners, github_membership.members]
}

# GitHub Team Resource - Child Teams
# https://search.opentofu.org/provider/integrations/github/latest/docs/resources/team

resource "github_team" "children" {
  for_each = local.github_child_teams

  name           = each.value.name
  description    = each.value.description
  privacy        = each.value.privacy
  parent_team_id = github_team.parents[each.value.parent_team].id
}

# GitHub Organization Membership Management - Split resources for lifecycle protection
# Organization owners are protected from deletion to maintain platform access
# https://search.opentofu.org/provider/integrations/github/latest/docs/resources/membership

# GitHub Organization Owners - Protected from deletion
resource "github_membership" "owners" {
  for_each = toset(local.github_organization_owners)

  username = each.value
  role     = "admin"

  # Protect organization owners from accidental deletion
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role] # Prevent accidental demotion
  }
}

# Regular GitHub Members - Can be destroyed normally
resource "github_membership" "members" {
  for_each = setsubtract(local.all_github_users, toset(local.github_organization_owners))

  username = each.value
  role     = "member"
}

# GitHub Team Resource - Parent Teams
# https://search.opentofu.org/provider/integrations/github/latest/docs/resources/team

# If you need to import a team, you can do so with the following command:
# tofu import github_team.parents\["team-key"\] <team_id>

# To get the team ids, you can run the following curl command with a token that has the read:org scope against your own organization.
# curl -H "Authorization: token $GITHUB_READ_ORG_TOKEN" https://api.github.com/orgs/osinfra-io/teams

resource "github_team" "parents" {
  for_each = local.github_parent_teams

  name        = each.value.name
  description = each.value.description
  privacy     = each.value.privacy
}

# GitHub Team Settings Resource
# https://search.opentofu.org/provider/integrations/github/latest/docs/resources/team_settings

resource "github_team_settings" "this" {
  for_each = local.review_request_delegations

  review_request_delegation {
    algorithm    = "LOAD_BALANCE"
    member_count = each.value.member_count
    notify       = false
  }

  team_id = github_team.parents[each.key].id
}

# GitHub Organization Projects V2 - Not yet supported in Terraform provider
# GitHub has deprecated classic Projects (v1) in favor of Projects V2 (beta)
# The Terraform GitHub provider doesn't yet have full support for Projects V2
#
# Manual creation steps for now:
# 1. Go to https://github.com/orgs/osinfra-io/projects
# 2. Create new project for each team:
#    - Name: {team.display_name} (e.g., "Onboarding")
#    - Description: "{display_name} is a {team_type} {description}. This project tracks work, features, and initiatives for the {display_name} team."
# 3. Add team access via project Settings → Manage access
#
# TODO: Implement when Terraform provider supports Projects V2
# Tracking: https://github.com/integrations/terraform-provider-github/issues/1661

# Google Billing Budget Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_billing_budget

resource "google_billing_budget" "teams" {
  for_each = var.billing_account != null ? var.team : {}

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.monthly_budget_amount
    }
  }

  billing_account = var.billing_account

  budget_filter {
    resource_ancestors = [google_folder.team[each.key].id]
  }

  display_name = "${each.value.display_name} Monthly"

  threshold_rules {
    threshold_percent = 0.50
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }
}

# Cloud Identity Group Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/cloud_identity_group

resource "google_cloud_identity_group" "this" {
  for_each = local.identity_groups

  description          = each.value.description
  display_name         = each.value.display_name
  initial_group_config = "EMPTY"

  # When you signed up for Google Workspace or Cloud Identity, your account is assigned a unique customer ID.
  # You can look up this ID in your Admin console.
  # https://admin.google.com/ac/accountsettings/profile

  parent = "customers/${var.customer_id}"

  group_key {
    id = "${local.team_type_short_names[var.team[each.value.team].team_type]}-${each.key}@${var.primary_domain}"
  }

  labels = {

    # Must not contain more than one entry and must contain the following entry:

    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Cloud Identity Group Membership Resources
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/cloud_identity_group_membership

resource "google_cloud_identity_group_membership" "managers" {

  # Iterate over local.managers to create a resource for each user in the manager list.

  for_each = local.managers

  group = google_cloud_identity_group.this[each.value.group].id

  preferred_member_key {
    id = each.value.manager
  }

  # MEMBER role must be specified. The order of roles should not be changed.

  roles { name = "MEMBER" }
  roles { name = "MANAGER" }
}

resource "google_cloud_identity_group_membership" "members" {

  # Iterate over local.members to create a resource for each user in the member list.

  for_each = local.members

  group = google_cloud_identity_group.this[each.value.group].id

  preferred_member_key {
    id = each.value.member
  }

  roles { name = "MEMBER" }
}

resource "google_cloud_identity_group_membership" "owners" {

  # Iterate over local.owners to create a resource for each user in the owner list.

  for_each = local.owners

  group = google_cloud_identity_group.this[each.value.group].id

  preferred_member_key {
    id = each.value.owner
  }

  # MEMBER role must be specified. The order of roles should not be changed.

  roles { name = "OWNER" }
  roles { name = "MEMBER" }
}

# Google Folder IAM Member Resource
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_folder_iam_member

# Assign identity groups to team folders with their specified roles
# Groups inherit access to all child environment folders
resource "google_folder_iam_member" "team_access" {
  for_each = local.iam_bindings

  folder = google_folder.team[each.value.team_key].name
  role   = each.value.role
  member = "group:${google_cloud_identity_group.this[each.value.group_key].group_key[0].id}"

  depends_on = [
    google_cloud_identity_group.this,
    google_folder.team
  ]
}

# Google Folder Resources
# https://search.opentofu.org/provider/hashicorp/google/latest/docs/resources/google_folder

# Folder resources provide grouping mechanism and isolation boundaries between projects.
# This creates a 3-level hierarchy following Team Topologies methodology:
#   Team Types (Platform Teams, Stream-aligned Teams, etc.)
#   └── Teams (Onboarding, Kubernetes, Customer Trust, etc.)
#       └── Environments (Sandbox, Non-production, Production)
#
# https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#folders

resource "google_folder" "environment" {
  for_each = local.environments

  display_name        = each.value.environment
  parent              = google_folder.team[each.value.team].name
  deletion_protection = false
}

resource "google_folder" "team" {
  for_each = var.team

  display_name        = each.value.display_name
  parent              = google_folder.team_type[each.value.team_type].name
  deletion_protection = false
}

resource "google_folder" "team_type" {
  for_each = local.team_types

  display_name        = local.team_type_display_names[each.value]
  parent              = "folders/${var.top_level_folder_id}"
  deletion_protection = false
}
