# Output Values
# https://opentofu.org/docs/language/values/outputs

# Environment Folder IDs
# Output folder IDs for each environment
output "environment_folder_ids" {
  description = "Map of environment folder IDs keyed by environment key (team-environment format)"
  value = {
    for environment_key, environment_resource in google_folder.environment :
    environment_key => environment_resource.id
  }
}

# Environment folders by team - easier lookup
output "environment_folders_by_team" {
  description = "Environment folder IDs organized by team for easier consumption"
  value = {
    for team_key, team in var.team : team_key => {
      for env_key, env in local.environments :
      env_key => {
        folder_id   = google_folder.environment[env_key].id
        environment = env.environment
        team        = env.team
      }
      if startswith(env_key, "${team_key}-")
    }
  }
}

# All Environments with Metadata
output "environments" {
  description = "Map of environments with their folder IDs and metadata"
  value = {
    for environment_key, environment in local.environments : environment_key => {
      folder_id   = google_folder.environment[environment_key].id
      environment = environment.environment
      team        = environment.team
    }
  }
}

# Folder paths for debugging/documentation
output "folder_hierarchy" {
  description = "Complete folder hierarchy with paths for documentation"
  value = {
    for team_key, team in var.team : team_key => {
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

# Identity Group Information
output "identity_groups" {
  description = "Map of identity groups with their metadata"
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

# Simple folder ID lookups for most common cases
output "production_folder_ids" {
  description = "Production environment folder IDs for quick reference"
  value = {
    for env_key, env in local.environments :
    env_key => google_folder.environment[env_key].id
    if env.environment == "Production"
  }
}

output "sandbox_folder_ids" {
  description = "Sandbox environment folder IDs for quick reference"
  value = {
    for env_key, env in local.environments :
    env_key => google_folder.environment[env_key].id
    if env.environment == "Sandbox"
  }
}

# Environment folders by team and environment name - for direct lookup
output "team_environment_folders" {
  description = "Environment folder IDs organized by team and environment name"
  value = {
    for team_key, team in var.team : team_key => {
      for env_name in ["Sandbox", "Non-production", "Production"] : lower(env_name) => [
        for env_key, env in local.environments :
        google_folder.environment[env_key].id
        if startswith(env_key, "${team_key}-") && env.environment == env_name
      ]
    }
  }
}

# Team Folder IDs
# Output folder IDs for each team
output "team_folder_ids" {
  description = "Map of team folder IDs keyed by team key"
  value = {
    for team_key, team_resource in google_folder.team :
    team_key => team_resource.id
  }
}

# Team Type Folder IDs
# Output folder IDs for each team type (Platform Teams, Stream-aligned Teams, etc.)
output "team_type_folder_ids" {
  description = "Map of team type folder IDs keyed by team type"
  value = {
    for team_type_key, team_type_resource in google_folder.team_type :
    team_type_key => team_type_resource.id
  }
}

# All Team Folders with Metadata
output "teams" {
  description = "Map of teams with their folder IDs and metadata"
  value = {
    for team_key, team in var.team : team_key => {
      folder_id    = google_folder.team[team_key].id
      display_name = team.display_name
      team_type    = team.team_type
    }
  }
}
