team = {
  customer-trust = {
    display_name = "Customer Trust"
    team_type    = "stream-aligned-team"

    github_parent_team = {
      maintainers = []
      members     = []
    }

    github_child_teams = {
      sandbox-approver = {
        maintainers = []
        members     = []
      }
      non-production-approver = {
        maintainers = []
        members     = []
      }
      production-approver = {
        maintainers = []
        members     = []
      }
      repository-administrators = {
        maintainers = []
        members     = []
      }
    }

    datadog_team = {
      admins  = []
      members = []
    }

    google_identity_groups = {
      admin = {
        managers = []
        members  = []
        owners   = []
      }
      writer = {
        managers = []
        members  = []
        owners   = []
      }
      reader = {
        managers = []
        members  = []
        owners   = []
      }
    }
  }
}
