defmodule SportsnetApiWeb.Graphql.Queries.SportsTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.AccountsFixtures
  import SportsnetApi.Factory
  import SportsnetApiWeb.UserAuth

  describe "allSports query" do
    setup %{conn: conn} do
      user = user_fixture()

      %{user: user, conn: conn}
    end

    test "return all sports when authenticated", %{conn: conn, user: user} do
      insert_list(3, :sport)
      {:ok, token} = log_in_user(user)

      query = """
      {
        allSports {
          id
          name
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query})

      assert %{"data" =>  %{"allSports" => sports}} = json_response(conn, 200)
      assert [
        %{"id" => _id_1, "name" => _name_1},
        %{"id" => _id_2, "name" => _name_2},
        %{"id" => _id_3, "name" => _name_3}
      ] = sports
    end

    test "returns an empty list when no sports are found", %{conn: conn, user: user} do
      {:ok, token} = log_in_user(user)

      query = """
      {
        allSports {
          id
          name
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query})

      assert %{"data" =>  %{"allSports" => sports}} = json_response(conn, 200)
      assert [] = sports
    end

    test "returns 401 when no authenticated", %{conn: conn} do
      insert_list(3, :sport)

      query = """
      {
        allSports {
          id
          name
        }
      }
      """
      conn = post(conn, "/graphql", %{query: query})

      assert response(conn, 401)
    end
  end
end
