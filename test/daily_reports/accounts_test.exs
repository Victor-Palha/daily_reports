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
end
