# Output Values
# https://opentofu.org/docs/language/values/outputs

# Complete folder hierarchy for documentation and reference
output "folder_hierarchy" {
  description = "Complete folder hierarchy with team types, teams, and environments"
  value = {
    for team_key, team in var.team : team_key => {
      team_type        = team.team_type
      team_type_folder = local.team_type_display_names[team.team_type]
      team_folder      = team.display_name
      team_folder_id   = google_folder.team[team_key].id
      environments = {
        for env_key, env in local.environments :
        env.environment => google_folder.environment[env_key].id
        if startswith(env_key, "${team_key}-")
      }
    }
  }
}

# Identity group information for IAM auditing and management
output "identity_groups" {
  description = "Google Cloud identity groups with email addresses and metadata"
  value = {
    for group_key, group in local.identity_groups : group_key => {
      email        = google_cloud_identity_group.this[group_key].group_key[0].id
      display_name = group.display_name
      description  = group.description
      team         = group.team
      role         = split("-", group_key)[1] # Extract role from group_key (team-role format)
    }
  }
}

# Team metadata for reference and management
output "teams" {
  description = "Team information with folder IDs and metadata"
  value = {
    for team_key, team in var.team : team_key => {
      folder_id    = google_folder.team[team_key].id
      display_name = team.display_name
      team_type    = team.team_type
    }
  }
}
