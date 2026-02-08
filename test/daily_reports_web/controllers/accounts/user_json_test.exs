defmodule DailyReportsWeb.Accounts.UserJSONTest do
  use DailyReportsWeb.ConnCase, async: true

  alias DailyReportsWeb.Accounts.UserJSON
  alias DailyReports.Fixtures
  alias DailyReports.Repo

  describe "show/1" do
    test "renders basic user data without associations" do
      user = Fixtures.user_fixture()

      result = UserJSON.show(%{user: user})

      assert %{data: user_data} = result
      assert user_data.id == user.id
      assert user_data.email == user.email
      assert user_data.name == user.name
      assert user_data.role == user.role
      assert user_data.is_active == user.is_active
      refute Map.has_key?(user_data, :members)
      refute Map.has_key?(user_data, :projects)
      refute Map.has_key?(user_data, :created_by)
    end

    test "includes created_by when preloaded" do
      creator = Fixtures.user_fixture(%{name: "Creator User", role: "Master"})

      {:ok, user} =
        %{
          name: "Test User",
          email: Fixtures.unique_user_email(),
          password: "Password123!",
          role: "Collaborator",
          created_by: creator.id
        }
        |> then(
          &DailyReports.Accounts.User.registration_changeset(%DailyReports.Accounts.User{}, &1)
        )
        |> Repo.insert()

      user_with_preload = Repo.preload(user, :created_by_user)

      result = UserJSON.show(%{user: user_with_preload})

      assert %{data: user_data} = result
      assert Map.has_key?(user_data, :created_by)
      assert user_data.created_by.id == creator.id
      assert user_data.created_by.name == "Creator User"
      assert user_data.created_by.email == creator.email
    end

    test "includes members when preloaded" do
      user = Fixtures.user_fixture()
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{user: user, project: project})

      user_with_preload = Repo.preload(user, :members)

      result = UserJSON.show(%{user: user_with_preload})

      assert %{data: user_data} = result
      assert Map.has_key?(user_data, :members)
      assert length(user_data.members) == 1
      assert hd(user_data.members).id == member.id
      assert hd(user_data.members).role == member.role
      assert hd(user_data.members).project_id == project.id
    end

    test "includes projects when preloaded through members" do
      user = Fixtures.user_fixture()
      project = Fixtures.project_fixture(%{name: "Test Project"})
      Fixtures.member_fixture(%{user: user, project: project})

      user_with_preload = Repo.preload(user, :projects)

      result = UserJSON.show(%{user: user_with_preload})

      assert %{data: user_data} = result
      assert Map.has_key?(user_data, :projects)
      assert length(user_data.projects) == 1
      assert hd(user_data.projects).id == project.id
      assert hd(user_data.projects).identifier == project.identifier
      assert hd(user_data.projects).name == "Test Project"
      assert hd(user_data.projects).is_active == project.is_active
    end

    test "includes all associations when fully preloaded" do
      creator = Fixtures.user_fixture(%{name: "Creator", role: "Master"})

      {:ok, user} =
        %{
          name: "Test User",
          email: Fixtures.unique_user_email(),
          password: "Password123!",
          role: "Collaborator",
          created_by: creator.id
        }
        |> then(
          &DailyReports.Accounts.User.registration_changeset(%DailyReports.Accounts.User{}, &1)
        )
        |> Repo.insert()

      project = Fixtures.project_fixture()
      _member = Fixtures.member_fixture(%{user: user, project: project})

      user_with_preload = Repo.preload(user, [:created_by_user, :members, :projects])

      result = UserJSON.show(%{user: user_with_preload})

      assert %{data: user_data} = result
      assert Map.has_key?(user_data, :created_by)
      assert Map.has_key?(user_data, :members)
      assert Map.has_key?(user_data, :projects)
    end

    test "does not include empty members list" do
      user = Fixtures.user_fixture()
      user_with_preload = Repo.preload(user, :members)

      result = UserJSON.show(%{user: user_with_preload})

      assert %{data: user_data} = result
      refute Map.has_key?(user_data, :members)
    end

    test "does not include empty projects list" do
      user = Fixtures.user_fixture()
      user_with_preload = Repo.preload(user, :projects)

      result = UserJSON.show(%{user: user_with_preload})

      assert %{data: user_data} = result
      refute Map.has_key?(user_data, :projects)
    end
  end

  describe "index/1" do
    test "renders list of users with preloaded associations" do
      creator = Fixtures.user_fixture(%{name: "Creator", role: "Master"})

      {:ok, user1} =
        %{
          name: "User 1",
          email: Fixtures.unique_user_email(),
          password: "Password123!",
          role: "Collaborator",
          created_by: creator.id
        }
        |> then(
          &DailyReports.Accounts.User.registration_changeset(%DailyReports.Accounts.User{}, &1)
        )
        |> Repo.insert()

      user2 = Fixtures.user_fixture(%{name: "User 2"})
      project = Fixtures.project_fixture()
      Fixtures.member_fixture(%{user: user1, project: project})

      users = Repo.preload([user1, user2], [:created_by_user, :members, :projects])

      result =
        UserJSON.index(%{
          users: users,
          total_count: 2,
          page: 1,
          page_size: 20,
          total_pages: 1
        })

      assert %{data: data, meta: meta} = result
      assert length(data) == 2
      assert meta.total_count == 2

      user1_data = Enum.find(data, fn u -> u.id == user1.id end)
      assert Map.has_key?(user1_data, :created_by)
      assert Map.has_key?(user1_data, :members)
      assert Map.has_key?(user1_data, :projects)

      user2_data = Enum.find(data, fn u -> u.id == user2.id end)
      refute Map.has_key?(user2_data, :members)
      refute Map.has_key?(user2_data, :projects)
    end
  end
end
