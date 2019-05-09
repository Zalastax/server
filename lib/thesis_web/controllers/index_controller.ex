defmodule ThesisWeb.IndexController do
  use ThesisWeb, :controller
  import Thesis.Repo, only: [get_or_insert!: 2]
  alias Thesis.Assignments

  require Logger

  plug PlugLti when action in [:launch]

  def launch(
        conn,
        %{
          "user_id" => lti_user_id,
          "roles" => roles,
          "ext_lti_assignment_id" => assignment_id,
          "resource_link_title" => assignment_name
        } = _params
      ) do
    user = get_or_insert!(Thesis.User, %{lti_user_id: lti_user_id})
    assignment = Assignments.get_or_insert!(%{id: assignment_id, name: assignment_name})
    role = determine_role(roles)

    conn
    |> put_session(:user, user)
    |> put_session(:role, role)
    |> redirect_user(role, assignment)
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end

  defp redirect_user(conn, role, assignment) do
    case role do
      :student ->
        redirect(conn, to: Routes.submission_path(conn, :index, assignment.id))

      :teacher ->
        redirect(conn, to: Routes.assignment_path(conn, :index, assignment.id))
    end
  end

  defp determine_role(roles) do
    cond do
      roles =~ "Learner" ->
        :student

      roles =~ "Instructor" ->
        :teacher

      true ->
        :unknown
    end
  end
end
