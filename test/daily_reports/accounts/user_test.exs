defmodule DailyReports.Accounts.UserTest do
  use DailyReports.DataCase, async: true

  alias DailyReports.Accounts.User
  alias DailyReports.Fixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        User.changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          name: "John Doe"
        })

      assert changeset.valid?
    end

    test "invalid changeset without email" do
      changeset = User.changeset(%User{}, %{name: "John Doe"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).email
    end

    test "invalid changeset with invalid email format" do
      changeset =
        User.changeset(%User{}, %{
          email: "invalid-email",
          name: "John Doe"
        })

      refute changeset.valid?
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "invalid changeset with email too long" do
      long_email = String.duplicate("a", 150) <> "@example.com"

      changeset =
        User.changeset(%User{}, %{
          email: long_email,
          name: "John Doe"
        })

      refute changeset.valid?
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "invalid changeset with invalid role" do
      changeset =
        User.changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          role: "InvalidRole"
        })

      refute changeset.valid?
      assert "must be one of: Collaborator, Master, Manager" in errors_on(changeset).role
    end

    test "valid changeset with valid role" do
      for role <- ["Collaborator", "Master", "Manager"] do
        changeset =
          User.changeset(%User{}, %{
            email: Fixtures.unique_user_email(),
            role: role
          })

        assert changeset.valid?
      end
    end
  end

  describe "registration_changeset/2" do
    test "valid registration changeset with all required fields" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          password: "securePassword123!",
          name: "John Doe",
          role: "Collaborator"
        })

      assert changeset.valid?
      assert get_change(changeset, :password_hash)
      refute get_change(changeset, :password)
    end

    test "invalid registration changeset without password" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          name: "John Doe"
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).password
    end

    test "invalid registration changeset with short password" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          password: "short"
        })

      refute changeset.valid?
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "invalid registration changeset with password too long" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          password: String.duplicate("a", 73)
        })

      refute changeset.valid?
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "hashes password on valid changeset" do
      password = "securePassword123!"

      changeset =
        User.registration_changeset(%User{}, %{
          email: Fixtures.unique_user_email(),
          password: password,
          role: "Collaborator"
        })

      assert changeset.valid?
      assert get_change(changeset, :password_hash)
      assert get_change(changeset, :password_hash) != password
      refute get_change(changeset, :password)
    end
  end

  describe "valid_password?/2" do
    test "returns true for correct password" do
      password = "securePassword123!"
      user = Fixtures.user_fixture(%{password: password})

      assert User.valid_password?(user, password)
    end

    test "returns false for incorrect password" do
      user = Fixtures.user_fixture(%{password: "correctPassword123!"})

      refute User.valid_password?(user, "wrongPassword")
    end

    test "returns false for nil password_hash" do
      user = %User{password_hash: nil}

      refute User.valid_password?(user, "anyPassword")
    end
  end

  describe "inserting users" do
    test "successfully creates a user with valid attributes" do
      attrs = %{
        email: Fixtures.unique_user_email(),
        password: "Password123!",
        name: "Jane Doe",
        role: "Manager"
      }

      changeset = User.registration_changeset(%User{}, attrs)
      assert {:ok, user} = Repo.insert(changeset)

      assert user.email == attrs.email
      assert user.name == attrs.name
      assert user.role == attrs.role
      assert user.is_active == true
      assert user.password_hash
    end

    test "fails to create user with duplicate email" do
      email = Fixtures.unique_user_email()
      Fixtures.user_fixture(%{email: email})

      changeset =
        User.registration_changeset(%User{}, %{
          email: email,
          password: "Password123!"
        })

      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).email
    end
  end
end
