defmodule SportsnetApiWeb.Graphql.Queries.SportsQueriesTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  describe "allSports query" do
    setup %{conn: conn} do
      token = insert(:user) |> create_user_api_token()

      %{conn: conn, token: token}
    end

    test "return all sports when authenticated", %{conn: conn, token: token} do
      insert_list(3, :sport)

      query = """
      {
        allSports {
          id
          name
          code
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query})

      assert %{"data" =>  %{"allSports" => sports}} = json_response(conn, 200)
      assert [
        %{"id" => _id_1, "name" => _name_1, "code" => _code_1},
        %{"id" => _id_2, "name" => _name_2, "code" => _code_2},
        %{"id" => _id_3, "name" => _name_3, "code" => _code_3}
      ] = sports
    end

    test "returns an empty list when no sports are found", %{conn: conn, token: token} do
      query = """
      {
        allSports {
          id
          name
          code
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
          code
        }
      }
      """
      conn = post(conn, "/graphql", %{query: query})

      assert response(conn, 401)
    end
  end
end
