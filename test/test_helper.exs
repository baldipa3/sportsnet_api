ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(SportsnetApi.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)

# Enable use of interactive shell to stop at IEx.pry()
ExUnit.after_suite(fn _results ->
  System.stop(0)
end)
