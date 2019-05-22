defmodule ThesisWeb.SharedView do
  use ThesisWeb, :view

  alias Thesis.Accounts.User
  alias Thesis.Submissions.Submission
  alias Thesis.Assignments.Assignment

  def user_link(conn, %User{} = user) do
    user_link(conn, user.id)
  end

  def user_link(conn, user_id) do
    href = Routes.user_path(conn, :show, user_id)
    icon = icon(:user)

    ~E(<a href="<%= href %>" class="ui blue label"><i class="<%= icon %>"></i><%= user_id %></a>)
  end

  def submission_link(conn, %Submission{} = submission) do
    submission_link(conn, submission.id)
  end

  def submission_link(conn, submission_id) do
    href = Routes.submission_path(conn, :show, submission_id)
    icon = icon(:submission)

    ~E(<a href="<%= href %>" class="ui orange label"><i class="<%= icon %>"></i><%= submission_id %></a>)
  end

  def assignment_link(conn, %Assignment{} = assignment) do
    assignment_link(conn, assignment.id)
  end

  def assignment_link(conn, assignment_id) do
    href = Routes.assignment_path(conn, :show, assignment_id)
    icon = icon(:assignment)

    ~E(<a href="<%= href %>" class="ui red label"><i class="<%= icon %>"></i><%= assignment_id %></a>)
  end

  def render_sidebar_item(%Link{title: title, href: href, icon: icon} = _item, active_item) do
    ~E(<a class="<%= if active_item == title do "active" end %> item" href="<%= href %>"><i class="<%= icon %>"></i><%= title %></a>)
  end

  def render_sidebar_item(%LinkSeparator{title: title, icon: icon} = _item, _active_item) do
    ~E(</div><div class="item"><i class="<%= icon %>"></i><b><%= title %></b></div><div class="ui vertical pointing fluid menu">)
  end
end