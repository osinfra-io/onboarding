team = {
  onboarding = {
    display_name = "Onboarding"
    team_type    = "platform-team"

    github_parent_team = {
      maintainers = ["brettcurtis"]
      members     = []
    }

    github_child_teams = {
      sandbox-approver = {
        maintainers = ["brettcurtis"]
        members     = []
      }
      non-production-approver = {
        maintainers = ["brettcurtis"]
        members     = []
      }
      production-approver = {
        maintainers = ["brettcurtis"]
        members     = []
      }
      repository-administrators = {
        maintainers = ["brettcurtis"]
        members     = []
      }
    }

    datadog_team = {
      admins  = ["brett@osinfra.io"]
      members = []
    }

    google_identity_groups = {
      admin = {
        managers = []
        members  = []
        owners   = ["brett@osinfra.io"]
      }
      writer = {
        managers = []
        members  = []
        owners   = ["brett@osinfra.io"]
      }
      reader = {
        managers = []
        members  = []
        owners   = ["brett@osinfra.io"]
      }
    }
  }
}
