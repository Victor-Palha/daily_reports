# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DailyReports.Repo.insert!(%DailyReports.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DailyReports.Repo
alias DailyReports.Accounts.User
alias DailyReports.Projects.{Project, Member}
alias DailyReports.Reports.Report

# Clear existing data in development
if Mix.env() == :dev do
  Repo.delete_all(Report)
  Repo.delete_all(Member)
  Repo.delete_all(Project)
  Repo.delete_all(User)
end

# Create Users
IO.puts("Creating users...")

master_user =
  %User{}
  |> User.registration_changeset(%{
    name: "John Master",
    email: "john.master@example.com",
    password: "Password123!",
    role: "Master"
  })
  |> Repo.insert!()

manager_user =
  %User{}
  |> User.registration_changeset(%{
    name: "Jane Manager",
    email: "jane.manager@example.com",
    password: "Password123!",
    role: "Manager"
  })
  |> Repo.insert!()

developers =
  for i <- 1..8 do
    %User{}
    |> User.registration_changeset(%{
      name: "Developer #{i}",
      email: "developer#{i}@example.com",
      password: "Password123!",
      role: "Collaborator"
    })
    |> Repo.insert!()
  end

_inactive_user =
  %User{}
  |> User.registration_changeset(%{
    name: "Inactive User",
    email: "inactive@example.com",
    password: "Password123!",
    role: "Collaborator"
  })
  |> Repo.insert!()
  |> Ecto.Changeset.change(%{is_active: false})
  |> Repo.update!()

IO.puts("Created #{8 + 3} users")

# Create Projects
IO.puts("Creating projects...")

parent_project =
  %Project{}
  |> Project.changeset(%{
    identifier: "VO-2026-01",
    name: "Volt Platform",
    description: "Main platform development project for enterprise solutions",
    is_active: true
  })
  |> Repo.insert!()

child_project_1 =
  %Project{}
  |> Project.changeset(%{
    identifier: "VO-2026-02",
    name: "Volt Mobile App",
    description: "Mobile application for the Volt platform",
    is_active: true,
    parent_id: parent_project.id
  })
  |> Repo.insert!()

child_project_2 =
  %Project{}
  |> Project.changeset(%{
    identifier: "VO-2026-03",
    name: "Volt API Gateway",
    description: "API gateway and microservices infrastructure",
    is_active: true,
    parent_id: parent_project.id
  })
  |> Repo.insert!()

standalone_project =
  %Project{}
  |> Project.changeset(%{
    identifier: "DR-2026-01",
    name: "Daily Reports System",
    description: "Internal daily reporting and tracking system",
    is_active: true
  })
  |> Repo.insert!()

_deactivated_project =
  %Project{}
  |> Project.changeset(%{
    identifier: "OL-2025-99",
    name: "Old Legacy System",
    description: "Deprecated system - no longer maintained",
    is_active: false,
    deactivated_at: ~U[2025-12-31 23:59:59Z],
    deactivated_by: manager_user.id
  })
  |> Repo.insert!()

IO.puts("Created 5 projects")

# Create Members (linking users to projects)
IO.puts("Creating project members...")

# Volt Platform members
_member_1 =
  %Member{}
  |> Member.changeset(%{
    project_id: parent_project.id,
    user_id: manager_user.id,
    role: "Product Manager"
  })
  |> Repo.insert!()

_member_2 =
  %Member{}
  |> Member.changeset(%{
    project_id: parent_project.id,
    user_id: Enum.at(developers, 0).id,
    role: "Tech Lead"
  })
  |> Repo.insert!()

_member_3 =
  %Member{}
  |> Member.changeset(%{
    project_id: parent_project.id,
    user_id: Enum.at(developers, 1).id,
    role: "Backend Developer"
  })
  |> Repo.insert!()

_member_4 =
  %Member{}
  |> Member.changeset(%{
    project_id: parent_project.id,
    user_id: Enum.at(developers, 2).id,
    role: "Frontend Developer"
  })
  |> Repo.insert!()

# Volt Mobile App members
member_5 =
  %Member{}
  |> Member.changeset(%{
    project_id: child_project_1.id,
    user_id: Enum.at(developers, 3).id,
    role: "Mobile Developer"
  })
  |> Repo.insert!()

member_6 =
  %Member{}
  |> Member.changeset(%{
    project_id: child_project_1.id,
    user_id: Enum.at(developers, 4).id,
    role: "UI/UX Designer"
  })
  |> Repo.insert!()

# Volt API Gateway members
member_7 =
  %Member{}
  |> Member.changeset(%{
    project_id: child_project_2.id,
    user_id: Enum.at(developers, 5).id,
    role: "Backend Developer"
  })
  |> Repo.insert!()

member_8 =
  %Member{}
  |> Member.changeset(%{
    project_id: child_project_2.id,
    user_id: Enum.at(developers, 6).id,
    role: "DevOps Engineer"
  })
  |> Repo.insert!()

# Daily Reports System members
member_9 =
  %Member{}
  |> Member.changeset(%{
    project_id: standalone_project.id,
    user_id: master_user.id,
    role: "Solution Architect"
  })
  |> Repo.insert!()

member_10 =
  %Member{}
  |> Member.changeset(%{
    project_id: standalone_project.id,
    user_id: Enum.at(developers, 7).id,
    role: "Full Stack Developer"
  })
  |> Repo.insert!()

IO.puts("Created 10 project members")

# Create Reports
IO.puts("Creating daily reports...")

# Reports for Volt Mobile App
%Report{}
|> Report.changeset(%{
  project_id: child_project_1.id,
  created_by_id: member_5.id,
  title: "Mobile App Authentication Implementation",
  report_date: ~D[2026-02-05],
  summary: "Implemented user authentication flow in the mobile application",
  achievements:
    "- Completed login/logout screens\n- Integrated biometric authentication\n- Added session management",
  impediments: "None",
  next_steps: "- Add password reset functionality\n- Implement token refresh handling"
})
|> Repo.insert!()

%Report{}
|> Report.changeset(%{
  project_id: child_project_1.id,
  created_by_id: member_6.id,
  title: "UI/UX Design Updates",
  report_date: ~D[2026-02-06],
  summary: "Refined the user interface for better accessibility and user experience",
  achievements:
    "- Updated color scheme for better contrast\n- Redesigned navigation flow\n- Created new icon set",
  impediments: "Waiting for feedback from stakeholders on the new designs",
  next_steps: "- Incorporate feedback\n- Prepare design system documentation"
})
|> Repo.insert!()

%Report{}
|> Report.changeset(%{
  project_id: child_project_1.id,
  created_by_id: member_5.id,
  title: "Daily Progress Update",
  report_date: ~D[2026-02-07],
  summary: "Continued work on mobile app features",
  achievements:
    "- Fixed push notification bugs\n- Optimized app startup time\n- Added offline mode support",
  impediments: "None",
  next_steps: "- Test offline sync functionality\n- Prepare for beta release"
})
|> Repo.insert!()

# Reports for Volt API Gateway
%Report{}
|> Report.changeset(%{
  project_id: child_project_2.id,
  created_by_id: member_7.id,
  title: "API Gateway Rate Limiting",
  report_date: ~D[2026-02-04],
  summary: "Implemented rate limiting middleware for API protection",
  achievements:
    "- Added Redis-based rate limiting\n- Configured different limits per endpoint\n- Added monitoring metrics",
  impediments: "Need to discuss rate limit thresholds with product team",
  next_steps:
    "- Fine-tune rate limits based on usage patterns\n- Add rate limit headers to responses"
})
|> Repo.insert!()

%Report{}
|> Report.changeset(%{
  project_id: child_project_2.id,
  created_by_id: member_8.id,
  title: "Infrastructure Setup",
  report_date: ~D[2026-02-05],
  summary: "Set up CI/CD pipeline and monitoring infrastructure",
  achievements:
    "- Configured GitHub Actions for automated deployments\n- Set up Prometheus and Grafana\n- Implemented automated database backups",
  impediments: "Certificate renewal automation needs further testing",
  next_steps: "- Complete SSL certificate automation\n- Set up log aggregation with ELK stack"
})
|> Repo.insert!()

%Report{}
|> Report.changeset(%{
  project_id: child_project_2.id,
  created_by_id: member_7.id,
  title: "Microservices Communication",
  report_date: ~D[2026-02-07],
  summary: "Enhanced inter-service communication patterns",
  achievements:
    "- Implemented circuit breaker pattern\n- Added distributed tracing\n- Optimized service discovery",
  impediments: "None",
  next_steps: "- Add fallback mechanisms for service failures\n- Document communication patterns"
})
|> Repo.insert!()

# Reports for Daily Reports System
%Report{}
|> Report.changeset(%{
  project_id: standalone_project.id,
  created_by_id: member_9.id,
  title: "System Architecture Planning",
  report_date: ~D[2026-02-03],
  summary: "Designed the overall architecture for the daily reports system",
  achievements:
    "- Created system architecture diagrams\n- Defined database schema\n- Documented API endpoints",
  impediments: "None",
  next_steps: "- Review architecture with team\n- Begin implementation phase"
})
|> Repo.insert!()

%Report{}
|> Report.changeset(%{
  project_id: standalone_project.id,
  created_by_id: member_10.id,
  title: "Authentication System Implementation",
  report_date: ~D[2026-02-06],
  summary: "Built JWT-based authentication system with refresh tokens",
  achievements:
    "- Implemented Guardian JWT integration\n- Created auth controllers and tests\n- Added HTTP-only cookie support\n- All 90 tests passing",
  impediments: "None",
  next_steps: "- Create seeds file\n- Begin project management controllers"
})
|> Repo.insert!()

%Report{}
|> Report.changeset(%{
  project_id: standalone_project.id,
  created_by_id: member_10.id,
  title: "Database Seeding",
  report_date: ~D[2026-02-07],
  summary: "Created comprehensive seed data for development and testing",
  achievements:
    "- Generated seed file with users, projects, members, and reports\n- Tested seed data integrity",
  impediments: "None",
  next_steps: "- Continue with project and report controllers"
})
|> Repo.insert!()

IO.puts("Created 9 daily reports")

IO.puts("\n✅ Seeds completed successfully!")
IO.puts("\nSummary:")
IO.puts("- Users: #{Repo.aggregate(User, :count, :id)}")
IO.puts("- Projects: #{Repo.aggregate(Project, :count, :id)}")
IO.puts("- Members: #{Repo.aggregate(Member, :count, :id)}")
IO.puts("- Reports: #{Repo.aggregate(Report, :count, :id)}")

IO.puts("\n📝 Sample credentials:")
IO.puts("Master: john.master@example.com / Password123!")
IO.puts("Manager: jane.manager@example.com / Password123!")
IO.puts("Developer: developer1@example.com / Password123!")
