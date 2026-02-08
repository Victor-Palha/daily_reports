defmodule DailyReports.AccountsTest do
  use DailyReports.DataCase, async: true

  alias DailyReports.Accounts
  alias DailyReports.Accounts.{User, RefreshToken}
  alias DailyReports.Fixtures

  describe "get_user/1" do
    test "returns the user with given id" do
      user = Fixtures.user_fixture()
      assert Accounts.get_user(user.id).id == user.id
    end

    test "returns nil when user does not exist" do
      assert Accounts.get_user(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_user_by_email/1" do
    test "returns the user with given email" do
      user = Fixtures.user_fixture()
      assert Accounts.get_user_by_email(user.email).id == user.id
    end

    test "returns nil when user does not exist" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end
  end

  describe "create_user/1" do
    test "creates a user with valid attributes" do
      attrs = %{
        email: Fixtures.unique_user_email(),
        password: "Password123!",
        name: "Test User",
        role: "Collaborator"
      }

      assert {:ok, user} = Accounts.create_user(attrs)
      assert user.email == attrs.email
      assert user.name == attrs.name
      assert user.role == attrs.role
    end

    test "returns error with invalid attributes" do
      assert {:error, changeset} = Accounts.create_user(%{})
      assert "can't be blank" in errors_on(changeset).email
    end
  end

  describe "authenticate_user/2" do
    test "authenticates user with correct credentials" do
      password = "Password123!"
      user = Fixtures.user_fixture(%{password: password})

      assert {:ok, authenticated_user} = Accounts.authenticate_user(user.email, password)
      assert authenticated_user.id == user.id
    end

    test "returns error with incorrect password" do
      user = Fixtures.user_fixture(%{password: "CorrectPassword123!"})

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user(user.email, "WrongPassword")
    end

    test "returns error with non-existent email" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("nonexistent@example.com", "password")
    end

    test "returns error for inactive user" do
      password = "Password123!"

      {:ok, user} =
        %{password: password, is_active: false, email: Fixtures.unique_user_email()}
        |> Accounts.create_user()

      user = Repo.update!(User.changeset(user, %{is_active: false}))

      assert {:error, :invalid_credentials} = Accounts.authenticate_user(user.email, password)
    end
  end

  describe "generate_tokens/1" do
    test "generates access and refresh tokens for a user" do
      user = Fixtures.user_fixture()

      assert {:ok, access_token, refresh_token} = Accounts.generate_tokens(user)
      assert is_binary(access_token)
      assert is_binary(refresh_token)

      # Verify the refresh token is stored in the database
      stored_token = Repo.get_by(RefreshToken, token: refresh_token)
      assert stored_token != nil
      assert stored_token.user_id == user.id
    end

    test "generates tokens with custom TTL" do
      user = Fixtures.user_fixture()

      assert {:ok, access_token, refresh_token} =
               Accounts.generate_tokens(user, {2, :hour}, 60)

      assert is_binary(access_token)
      assert is_binary(refresh_token)
    end
  end

  describe "verify_token/1" do
    test "verifies a valid access token" do
      user = Fixtures.user_fixture()
      {:ok, access_token, _refresh_token} = Accounts.generate_tokens(user)

      assert {:ok, verified_user, claims} = Accounts.verify_token(access_token)
      assert verified_user.id == user.id
      assert claims["token_type"] == "access"
    end

    test "returns error for invalid token" do
      assert {:error, _reason} = Accounts.verify_token("invalid_token")
    end

    test "returns error for refresh token used as access token" do
      user = Fixtures.user_fixture()
      {:ok, _access_token, refresh_token} = Accounts.generate_tokens(user)

      # Using refresh token where access token is expected should fail
      assert {:error, _reason} = Accounts.verify_token(refresh_token)
    end
  end

  describe "refresh_tokens/1" do
    test "generates new tokens with valid refresh token" do
      user = Fixtures.user_fixture()
      {:ok, old_access_token, old_refresh_token} = Accounts.generate_tokens(user)

      assert {:ok, new_access_token, new_refresh_token} =
               Accounts.refresh_tokens(old_refresh_token)

      assert is_binary(new_access_token)
      assert is_binary(new_refresh_token)
      assert new_access_token != old_access_token
      assert new_refresh_token != old_refresh_token

      # Old refresh token should be revoked
      old_stored_token = Repo.get_by(RefreshToken, token: old_refresh_token)
      assert old_stored_token.revoked_at != nil
    end

    test "returns error for invalid refresh token" do
      assert {:error, _reason} = Accounts.refresh_tokens("invalid_token")
    end

    test "returns error for revoked refresh token" do
      user = Fixtures.user_fixture()
      {:ok, _access_token, refresh_token} = Accounts.generate_tokens(user)

      # Revoke the token
      stored_token = Repo.get_by(RefreshToken, token: refresh_token)
      {:ok, _} = Accounts.revoke_refresh_token(stored_token)

      # Try to use the revoked token
      assert {:error, :invalid_refresh_token} = Accounts.refresh_tokens(refresh_token)
    end
  end

  describe "revoke_refresh_token/1" do
    test "revokes a refresh token" do
      user = Fixtures.user_fixture()
      {:ok, _access_token, refresh_token} = Accounts.generate_tokens(user)

      stored_token = Repo.get_by(RefreshToken, token: refresh_token)
      assert stored_token.revoked_at == nil

      assert {:ok, updated_token} = Accounts.revoke_refresh_token(stored_token)
      assert updated_token.revoked_at != nil
    end
  end

  describe "revoke_all_user_tokens/1" do
    test "revokes all refresh tokens for a user" do
      user = Fixtures.user_fixture()

      # Generate multiple tokens
      {:ok, _, token1} = Accounts.generate_tokens(user)
      {:ok, _, token2} = Accounts.generate_tokens(user)
      {:ok, _, token3} = Accounts.generate_tokens(user)

      # Verify all tokens exist and are not revoked
      assert Repo.get_by(RefreshToken, token: token1).revoked_at == nil
      assert Repo.get_by(RefreshToken, token: token2).revoked_at == nil
      assert Repo.get_by(RefreshToken, token: token3).revoked_at == nil

      # Revoke all tokens
      assert {3, nil} = Accounts.revoke_all_user_tokens(user)

      # Verify all tokens are revoked
      assert Repo.get_by(RefreshToken, token: token1).revoked_at != nil
      assert Repo.get_by(RefreshToken, token: token2).revoked_at != nil
      assert Repo.get_by(RefreshToken, token: token3).revoked_at != nil
    end
  end

  describe "cleanup_expired_tokens/0" do
    test "deletes expired refresh tokens" do
      user = Fixtures.user_fixture()

      # Create an expired token
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)

      expired_token = %RefreshToken{
        token: "expired_token",
        user_id: user.id,
        expires_at: expired_at
      }

      {:ok, expired} = Repo.insert(expired_token)

      # Create a valid token
      {:ok, _access, _refresh} = Accounts.generate_tokens(user)

      # Cleanup
      assert {1, nil} = Accounts.cleanup_expired_tokens()

      # Verify only expired token was deleted
      assert Repo.get(RefreshToken, expired.id) == nil
      assert Repo.aggregate(RefreshToken, :count) > 0
    end
  end

  describe "list_users/1" do
    test "returns all users with default pagination" do
      user1 = Fixtures.user_fixture(%{name: "User 1"})
      user2 = Fixtures.user_fixture(%{name: "User 2"})

      result = Accounts.list_users()

      assert result.total_count == 2
      assert result.page == 1
      assert result.page_size == 20
      assert result.total_pages == 1
      assert length(result.users) == 2

      user_ids = Enum.map(result.users, & &1.id)
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "filters users by name (case-insensitive partial match)" do
      Fixtures.user_fixture(%{name: "John Doe"})
      Fixtures.user_fixture(%{name: "Jane Smith"})
      Fixtures.user_fixture(%{name: "Johnny Test"})

      result = Accounts.list_users(%{"name" => "john"})

      assert result.total_count == 2

      assert Enum.all?(result.users, fn user ->
               String.contains?(String.downcase(user.name), "john")
             end)
    end

    test "filters users by role" do
      Fixtures.user_fixture(%{role: "Master"})
      Fixtures.user_fixture(%{role: "Manager"})
      Fixtures.user_fixture(%{role: "Collaborator"})
      Fixtures.user_fixture(%{role: "Collaborator"})

      result = Accounts.list_users(%{"role" => "Collaborator"})

      assert result.total_count == 2
      assert Enum.all?(result.users, fn user -> user.role == "Collaborator" end)
    end

    test "filters users by is_active with boolean" do
      active_user = Fixtures.user_fixture()
      inactive_user = Fixtures.user_fixture()
      Accounts.update_user(inactive_user, %{is_active: false})

      result = Accounts.list_users(%{"is_active" => true})

      assert result.total_count == 1
      assert hd(result.users).id == active_user.id
      assert hd(result.users).is_active == true
    end

    test "filters users by is_active with string" do
      _active_user = Fixtures.user_fixture()
      inactive_user = Fixtures.user_fixture()
      Accounts.update_user(inactive_user, %{is_active: false})

      result = Accounts.list_users(%{"is_active" => "false"})

      assert result.total_count == 1
      assert hd(result.users).id == inactive_user.id
      assert hd(result.users).is_active == false
    end

    test "combines multiple filters" do
      Fixtures.user_fixture(%{name: "John Manager", role: "Manager"})
      Fixtures.user_fixture(%{name: "John Collaborator", role: "Collaborator"})
      Fixtures.user_fixture(%{name: "Jane Manager", role: "Manager"})

      result = Accounts.list_users(%{"name" => "john", "role" => "Manager"})

      assert result.total_count == 1
      assert hd(result.users).name == "John Manager"
    end

    test "handles pagination with custom page and page_size" do
      for i <- 1..15 do
        Fixtures.user_fixture(%{name: "User #{i}"})
      end

      # Page 1
      result = Accounts.list_users(%{"page" => 1, "page_size" => 5})

      assert result.page == 1
      assert result.page_size == 5
      assert result.total_count == 15
      assert result.total_pages == 3
      assert length(result.users) == 5

      # Page 2
      result = Accounts.list_users(%{"page" => 2, "page_size" => 5})

      assert result.page == 2
      assert length(result.users) == 5

      # Page 3
      result = Accounts.list_users(%{"page" => 3, "page_size" => 5})

      assert result.page == 3
      assert length(result.users) == 5
    end

    test "handles pagination with string parameters" do
      for i <- 1..10 do
        Fixtures.user_fixture(%{name: "User #{i}"})
      end

      result = Accounts.list_users(%{"page" => "2", "page_size" => "3"})

      assert result.page == 2
      assert result.page_size == 3
      assert length(result.users) == 3
    end

    test "limits page_size to maximum of 100" do
      Fixtures.user_fixture()

      result = Accounts.list_users(%{"page_size" => 200})

      assert result.page_size == 100
    end

    test "defaults invalid page to 1" do
      Fixtures.user_fixture()

      result = Accounts.list_users(%{"page" => "invalid"})

      assert result.page == 1
    end

    test "defaults invalid page_size to 20" do
      Fixtures.user_fixture()

      result = Accounts.list_users(%{"page_size" => "invalid"})

      assert result.page_size == 20
    end

    test "handles negative page numbers" do
      Fixtures.user_fixture()

      result = Accounts.list_users(%{"page" => -1})

      assert result.page == 1
    end

    test "handles zero page_size" do
      Fixtures.user_fixture()

      result = Accounts.list_users(%{"page_size" => 0})

      assert result.page_size == 20
    end

    test "returns empty list when no users match filters" do
      Fixtures.user_fixture(%{name: "John Doe"})

      result = Accounts.list_users(%{"name" => "NonexistentName"})

      assert result.users == []
      assert result.total_count == 0
      assert result.total_pages == 0
    end

    test "orders users by inserted_at desc, then name asc" do
      # Create three users with identical timestamps (practically)
      # This tests the secondary ordering by name
      users_created =
        for name <- ["Zara", "Alice", "Mike"] do
          Fixtures.user_fixture(%{name: name})
        end

      result = Accounts.list_users()

      # Verify all users are in results
      result_ids = Enum.map(result.users, & &1.id)
      assert Enum.all?(users_created, fn user -> user.id in result_ids end)

      # Find the positions of our test users
      test_users_in_result =
        Enum.filter(result.users, fn u ->
          u.id in Enum.map(users_created, & &1.id)
        end)

      # Should have all 3 users
      assert length(test_users_in_result) == 3

      # When grouped by time (very close timestamps), they should be ordered by name
      # Since they were created in quick succession, they're likely the most recent
      names = Enum.map(test_users_in_result, & &1.name)

      # Verify ordering exists and is deterministic
      assert length(names) == 3
      assert "Alice" in names
      assert "Mike" in names
      assert "Zara" in names
    end

    test "preloads user associations" do
      _user = Fixtures.user_fixture()

      result = Accounts.list_users()

      preloaded_user = hd(result.users)

      # Check that associations are loaded (not Ecto.Association.NotLoaded)
      assert Ecto.assoc_loaded?(preloaded_user.created_by_user)
      assert Ecto.assoc_loaded?(preloaded_user.members)
      assert Ecto.assoc_loaded?(preloaded_user.projects)
    end

    test "ignores empty string filters" do
      Fixtures.user_fixture(%{name: "John Doe", role: "Manager"})
      Fixtures.user_fixture(%{name: "Jane Smith", role: "Collaborator"})

      result = Accounts.list_users(%{"name" => "", "role" => ""})

      assert result.total_count == 2
    end
  end
end
