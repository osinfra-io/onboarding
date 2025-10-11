# <img width="45" height="45" alt="opentofu" src="https://github.com/user-attachments/assets/e7b3623b-6357-442e-a559-6d1494218355" /> Onboarding

**[GitHub Actions](https://github.com/osinfra-io/onboarding/actions):**

[![Dependabot](https://github.com/osinfra-io/onboarding/actions/workflows/dependabot.yml/badge.svg)](https://github.com/osinfra-io/onboarding/actions/workflows/dependabot.yml)

## 📄 Repository Description

This repository provides Infrastructure as Code (IaC) automation for onboarding teams across multiple platforms using OpenTofu. It implements Team Topologies principles to create a structured organizational hierarchy with appropriate access controls and tooling integrations.

The module automates the creation of:

- **Google Cloud folder hierarchy** following Team Topologies (Platform Teams, Stream-aligned Teams, etc.)
- **Google Cloud Identity Groups** with role-based access (admin, writer, reader)
- **GitHub Teams** with hierarchical structure and environment-specific approval workflows
- **Datadog Teams** for monitoring and observability

This enables platform teams to quickly onboard new teams with consistent security, governance, and operational practices across sandbox, non-production, and production environments.

## 🏭 Platform Information

- Documentation: [docs.osinfra.io](https://docs.osinfra.io/product-guides/google-cloud-platform/onboarding)
- Service Interfaces: [github.com](https://github.com/osinfra-io/onboarding/issues/new/choose)

## <img align="left" width="35" height="35" src="https://github.com/osinfra-io/github-organization-management/assets/1610100/39d6ae3b-ccc2-42db-92f1-276a5bc54e65"> Development

Our focus is on the core fundamental practice of platform engineering, Infrastructure as Code.

>Open Source Infrastructure (as Code) is a development model for infrastructure that focuses on open collaboration and applying relative lessons learned from software development practices that organizations can use internally at scale. - [Open Source Infrastructure (as Code)](https://www.osinfra.io)

To avoid slowing down stream-aligned teams, we want to open up the possibility for contributions. The Open Source Infrastructure (as Code) model allows team members external to the platform team to contribute with only a slight increase in cognitive load. This section is for developers who want to contribute to this repository, describing the tools used, the skills, and the knowledge required, along with OpenTofu documentation.

See the [documentation](https://docs.osinfra.io/fundamentals/development-setup) for setting up a development environment.

### 🛠️ Tools

- [pre-commit](https://github.com/pre-commit/pre-commit)
- [osinfra-pre-commit-hooks](https://github.com/osinfra-io/pre-commit-hooks)

### 📋 Skills and Knowledge

Links to documentation and other resources required to develop and iterate in this repository successfully.

- [google cloud platform groups](https://cloud.google.com/identity/docs/groups)
- [google cloud platform iam](https://cloud.google.com/iam/docs/overview)
- [google cloud platform resource landing-zone](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-landing-zone)
- [team topologies](https://teamtopologies.com/) - Organizational design methodology
- [github teams](https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams)
- [datadog teams](https://docs.datadoghq.com/account_management/teams/)

## Architecture

The module creates a three-level Google Cloud Platform folder hierarchy following Team Topologies principles:

```text
Top Level Folder (provided)
├── Platform Teams/
│   ├── Onboarding/
│   │   ├── Sandbox/
│   │   ├── Non-production/
│   │   └── Production/
│   └── Kubernetes/
│       ├── Sandbox/
│       ├── Non-production/
│       └── Production/
└── Stream-aligned Teams/
    └── Customer Trust/
        ├── Sandbox/
        ├── Non-production/
        └── Production/
```

Additionally, it creates:

- **Google Cloud Identity Groups** with 3 standard roles per team (admin, writer, reader) applied at team folder level
- **GitHub Teams** with hierarchical structure (parent team with child teams for GitHub Action sapprovers and repository administrators)
- **Datadog Teams** for monitoring and observability with admin/member roles, one per top-level team

## Interface (tfvars)

### Required Variables

#### `team`

A map of teams with their team type and membership configuration for hardcoded structures.

```hcl
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
```

## Team Structure

### Team Types (Team Topologies)

Each team must specify one of four team types:

- **`platform-team`** - Provides internal services to accelerate stream-aligned teams
- **`stream-aligned-team`** - Aligned to business capabilities/customer value streams
- **`complicated-subsystem-team`** - Focus on specific technical domains requiring deep expertise
- **`enabling-team`** - Help stream-aligned teams overcome obstacles and develop capabilities

### Environments

Each team automatically gets three hardcoded environment folders:

- **Hardcoded environments**: `Sandbox`, `Non-production`, `Production`

### Google Identity Groups

Each team has exactly 3 Google Cloud identity groups using basic IAM roles applied at the team folder level:

- **Hardcoded basic IAM roles**: reader, writer, admin
  - reader: Permissions for read-only actions that don't affect state, such as viewing (but not modifying) existing resources or data.
  - writer: All of the permissions in the Reader role, plus permissions for actions that modify state, such as changing existing resources.
  - admin: All of the permissions in the Writer role, plus permissions for actions like the following: Completing sensitive tasks, like managing tag bindings for Compute Engine resources; Managing roles and permissions for a project and all resources within the project; Setting up billing for a project.

Users can be assigned to one of three roles within each group:

- **`managers`**: Users who can manage the group
- **`members`**: Regular members of the group
- **`owners`**: Users who own the group
- **Hardcoded roles**: admin, writer, reader (automatically assigned)

**Auto-generated fields:**

- **`description`**: Uses official Google Cloud role descriptions (e.g., "All of the permissions in the Writer role, plus permissions for actions like...")
- **`display_name`**: `"{Team Type}: {Team Name} {Role}"` (e.g., "Platform Team: Onboarding Admin")

**Access Scope**: Groups have access to the entire team folder and all child environment folders.

### GitHub Team Structure

Each team has a hierarchical GitHub team structure with parent and child teams:

**Parent Team Configuration (`github_parent_team`):**

- **`maintainers`**: Users with full administrative access to the parent team
- **`members`**: Users with member access to the parent team

**Child Team Configuration (`github_child_teams`):**

- **`sandbox-approver`**: Members who can approve sandbox environment changes
- **`non-production-approver`**: Members who can approve Non-production environment changes
- **`production-approver`**: Members who can approve production environment changes
- **`repository-administrators`**: Repository administrators with full access

**Membership Logic:**

- **Parent Team**: Gets configured maintainers/members PLUS child team maintainers (auto-inherited as members)
- **Child Teams**: Independently configured maintainers and members
- **Deduplication**: Users configured directly on parent team take precedence over auto-inherited membership

### Datadog Teams

- **Teams**: One per top-level team for monitoring and observability
- **Name format**: `"{Team Type}: {Team Name}"` (e.g., "Platform Team: Onboarding")
- **Description format**: `"{Team Name} is a {Team Type} {Team Topologies description}."` (e.g., "Onboarding is a Platform Team providing a compelling internal product to accelerate delivery by Stream-aligned teams.")
- **Handle format**: `{team_prefix}-{team_name}` (e.g., "pt-onboarding")

## Validation Rules

### Team Types

- Must be exactly: `"platform-team"`, `"stream-aligned-team"`, `"complicated-subsystem-team"`, `"enabling-team"`

### Display Names

- Must be Title Case with first letter of each word capitalized
- Only letters, numbers, and spaces allowed
- The word "and" is allowed in lowercase (e.g., "Trust and Safety")

## Naming Conventions

- **Team Type folders**: Team Topologies categories with "Teams" suffix (e.g., "Platform Teams", "Stream-aligned Teams")
- **Team folders**: Use team display names from configuration (e.g., "Onboarding", "Customer Trust")
- **Environment folders**: Hardcoded environment names (e.g., "Sandbox", "Non-production", "Production")
- **Google Identity groups**:
  - **Email format**: `{team_prefix}-{team_key}-{role}@{domain}` (e.g., `pt-onboarding-admin@osinfra.io`)
  - **Display name**: `"{Team Type}: {Team Name} {Role}"` (e.g., "Platform Team: Onboarding Admin")
- **GitHub Parent teams**: `{team_prefix}-{team_key}` (e.g., "pt-onboarding", "st-customer-trust")
- **GitHub Child teams**:
  - **Name format**: Hardcoded functional names (`sandbox-approver`, `non-production-approver`, `production-approver`, `repository-administrators`)
  - **Full team name**: `{parent_team}-{child_name}` (e.g., "pt-onboarding-sandbox-approver")
- **Datadog Teams**:
  - **Name**: `"{Team Type}: {Team Name}"` (e.g., "Platform Team: Onboarding")
  - **Handle**: `{team_prefix}-{team_key}` (e.g., "pt-onboarding")
