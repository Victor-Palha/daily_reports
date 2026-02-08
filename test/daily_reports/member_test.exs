defmodule DailyReports.MemberTest do
  use DailyReports.DataCase, async: true

  alias DailyReports.Member
  alias DailyReports.Fixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        Member.changeset(%Member{}, %{
          role: "Backend Developer"
        })

      assert changeset.valid?
    end

    test "invalid changeset without role" do
      changeset = Member.changeset(%Member{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).role
    end

    test "invalid changeset with invalid role" do
      changeset =
        Member.changeset(%Member{}, %{
          role: "InvalidRole"
        })

      refute changeset.valid?
      assert Enum.any?(errors_on(changeset).role, &String.contains?(&1, "must be one of"))
    end

    test "valid changeset with all valid roles" do
      for role <- Member.roles() do
        changeset = Member.changeset(%Member{}, %{role: role})

        assert changeset.valid?, "Expected #{role} to be valid"
      end
    end
  end

  describe "roles/0" do
    test "returns list of valid roles" do
      roles = Member.roles()

      assert is_list(roles)
      assert length(roles) > 0
      assert "Backend Developer" in roles
      assert "Frontend Developer" in roles
      assert "QA Engineer" in roles
      assert "Tech Lead" in roles
      assert "Product Owner" in roles
    end
  end

  describe "inserting members" do
    test "successfully creates a member with valid attributes" do
      user = Fixtures.user_fixture()
      project = Fixtures.project_fixture()

      changeset =
        Member.changeset(%Member{}, %{
          role: "Full Stack Developer"
        })
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:project, project)

      assert {:ok, member} = Repo.insert(changeset)

      assert member.role == "Full Stack Developer"
      assert member.user_id == user.id
      assert member.project_id == project.id
    end

    test "fails to create member with duplicate user and project" do
      user = Fixtures.user_fixture()
      project = Fixtures.project_fixture()

      Fixtures.member_fixture(%{user: user, project: project})

      changeset =
        Member.changeset(%Member{}, %{
          role: "Frontend Developer"
        })
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:project, project)

      assert {:error, changeset} = Repo.insert(changeset)
      assert "user is already a member of this project" in errors_on(changeset).project_id
    end

    test "allows same user in different projects" do
      user = Fixtures.user_fixture()
      project1 = Fixtures.project_fixture()
      project2 = Fixtures.project_fixture()

      Fixtures.member_fixture(%{user: user, project: project1, role: "Backend Developer"})

      changeset =
        Member.changeset(%Member{}, %{
          role: "Frontend Developer"
        })
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:project, project2)

      assert {:ok, member} = Repo.insert(changeset)
      assert member.user_id == user.id
      assert member.project_id == project2.id
    end

    test "allows different users in same project" do
      user1 = Fixtures.user_fixture()
      user2 = Fixtures.user_fixture()
      project = Fixtures.project_fixture()

      Fixtures.member_fixture(%{user: user1, project: project, role: "Backend Developer"})

      changeset =
        Member.changeset(%Member{}, %{
          role: "Frontend Developer"
        })
        |> Ecto.Changeset.put_assoc(:user, user2)
        |> Ecto.Changeset.put_assoc(:project, project)

      assert {:ok, member} = Repo.insert(changeset)
      assert member.user_id == user2.id
      assert member.project_id == project.id
    end
  end
end
