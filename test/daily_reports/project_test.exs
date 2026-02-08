defmodule DailyReports.ProjectTest do
  use DailyReports.DataCase, async: true

  alias DailyReports.Project
  alias DailyReports.Fixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        Project.changeset(%Project{}, %{
          identifier: Fixtures.unique_project_identifier(),
          name: "Test Project"
        })

      assert changeset.valid?
    end

    test "invalid changeset without identifier" do
      changeset = Project.changeset(%Project{}, %{name: "Test Project"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).identifier
    end

    test "invalid changeset without name" do
      changeset =
        Project.changeset(%Project{}, %{
          identifier: Fixtures.unique_project_identifier()
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "invalid changeset with malformed identifier" do
      invalid_identifiers = [
        "invalid",
        "AB-2026",
        "AB-26-01",
        "ab-2026-01",
        "AB2026-01",
        "AB-2026-"
      ]

      for identifier <- invalid_identifiers do
        changeset =
          Project.changeset(%Project{}, %{
            identifier: identifier,
            name: "Test Project"
          })

        refute changeset.valid?, "Expected #{identifier} to be invalid"
        assert "must be in format: VO-2026-01 (Sigla-Ano-ID)" in errors_on(changeset).identifier
      end
    end

    test "valid changeset with properly formatted identifier" do
      valid_identifiers = [
        "AB-2026-01",
        "XYZ-2025-999",
        "ABCD-2024-1",
        "VO-2026-01"
      ]

      for identifier <- valid_identifiers do
        changeset =
          Project.changeset(%Project{}, %{
            identifier: identifier,
            name: "Test Project"
          })

        assert changeset.valid?, "Expected #{identifier} to be valid"
      end
    end

    test "valid changeset with optional fields" do
      changeset =
        Project.changeset(%Project{}, %{
          identifier: Fixtures.unique_project_identifier(),
          name: "Test Project",
          description: "A detailed description",
          is_active: false
        })

      assert changeset.valid?
    end
  end

  describe "deactivation_changeset/2" do
    test "sets deactivated_at when is_active is false" do
      project = Fixtures.project_fixture()

      changeset =
        Project.deactivation_changeset(project, %{
          is_active: false,
          deactivated_by: Ecto.UUID.generate()
        })

      assert changeset.valid?
      assert get_change(changeset, :deactivated_at)
      assert get_change(changeset, :is_active) == false
    end

    test "does not set deactivated_at when is_active is true" do
      project = Fixtures.project_fixture()

      changeset = Project.deactivation_changeset(project, %{is_active: true})

      assert changeset.valid?
      refute get_change(changeset, :deactivated_at)
    end
  end

  describe "inserting projects" do
    test "successfully creates a project with valid attributes" do
      attrs = %{
        identifier: Fixtures.unique_project_identifier(),
        name: "New Project",
        description: "Project description",
        is_active: true
      }

      changeset = Project.changeset(%Project{}, attrs)
      assert {:ok, project} = Repo.insert(changeset)

      assert project.identifier == attrs.identifier
      assert project.name == attrs.name
      assert project.description == attrs.description
      assert project.is_active == true
    end

    test "fails to create project with duplicate identifier" do
      identifier = Fixtures.unique_project_identifier()
      Fixtures.project_fixture(%{identifier: identifier})

      changeset =
        Project.changeset(%Project{}, %{
          identifier: identifier,
          name: "Another Project"
        })

      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).identifier
    end

    test "successfully creates project with parent" do
      parent = Fixtures.project_fixture()

      attrs = %{
        identifier: Fixtures.unique_project_identifier(),
        name: "Child Project",
        parent_id: parent.id
      }

      changeset = Project.changeset(%Project{}, attrs)
      assert {:ok, project} = Repo.insert(changeset)

      assert project.parent_id == parent.id
    end
  end
end
