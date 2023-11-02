defmodule Triggir.Repo do
  use Ecto.Repo,
    otp_app: :triggir,
    adapter: Ecto.Adapters.Postgres
end
