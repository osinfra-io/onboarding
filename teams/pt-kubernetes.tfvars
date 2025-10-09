team = {
  kubernetes = {
    display_name = "Kubernetes"
    team_type    = "platform-team"

    github_parent_team = {
      maintainers = []
      members     = []
    }

    github_child_teams = {
      sandbox-approver = {
        maintainers = ["brett"]
        members     = []
      }
      non-production-approver = {
        maintainers = ["brett"]
        members     = []
      }
      production-approver = {
        maintainers = ["brett"]
        members     = []
      }
      repository-administrators = {
        maintainers = ["brett"]
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
