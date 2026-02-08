defmodule DailyReports.Accounts.Guardian do
  @moduledoc """
  Guardian implementation for JWT authentication.
  """
  use Guardian, otp_app: :daily_reports

  alias DailyReports.Accounts
  alias DailyReports.Accounts.User

  @doc """
  Encodes the user ID into the JWT subject.
  """
  def subject_for_token(%User{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  @doc """
  Retrieves the user from the JWT subject.
  """
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Builds claims for the JWT token.
  """
  def build_claims(claims, _resource, opts) do
    claims =
      claims
      |> Map.put("token_type", Keyword.get(opts, :token_type, "access"))

    {:ok, claims}
  end

  @doc """
  After encode hook - can be used for logging or tracking.
  """
  def after_encode_and_sign(_resource, _claims, token, _options) do
    {:ok, token}
  end

  @doc """
  After sign-in hook - can be used to set last login time.
  """
  def after_sign_in(_conn, _resource, _claims, _options) do
    :ok
  end

  @doc """
  After sign-out hook - can be used to revoke tokens.
  """
  def after_sign_out(_conn, _options) do
    :ok
  end

  @doc """
  Verifies the claims in a JWT token.
  """
  def verify_claims(claims, _options) do
    {:ok, claims}
  end

  @doc """
  Handles a revoked token.
  """
  def on_revoke(claims, _token, _options) do
    # You can implement token blacklisting here if needed
    {:ok, claims}
  end
end
