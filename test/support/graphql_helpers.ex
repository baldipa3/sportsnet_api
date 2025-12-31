defmodule SportsnetApi.GraphQLHelpers do
  use SportsnetApiWeb.ConnCase, async: true

  def post_graphql(conn, token, query, variables \\ %{}) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("content-type", "multipart/form-data")
    |> post("/graphql", %{
      "query" => query,
      "variables" => variables
    })
  end

  def mutation_result(conn, name) do
    json_response(conn, 200)
    |> Map.get("data")
    |> Map.get(name)
  end

  def errors_result(conn) do
    json_response(conn, 200)
    |> Map.get("errors")
  end
end

##### TODO: Refactor Example
  # assert %{"id" => ^encoded_post_id} = mutation_result(conn, "deletePost")
####
