defmodule ThesisWeb.SubmissionController do
  use ThesisWeb, :controller

  alias Thesis.Configuration
  alias Thesis.Assignments
  alias Thesis.Submissions
  alias Thesis.Submissions.File

  require Logger

  def index(%Plug.Conn{assigns: %{role: role}} = conn, %{"assignment_id" => assignment_id}) do
    assignment = Assignments.get!(assignment_id)
    configuration = Assignments.get_latest_configuration!(assignment.id)

    %Configuration{allowed_file_extensions: allowed_file_extensions} =
      Configuration.parse_code(configuration.code)

    render(conn, "index.html",
      assignment: assignment,
      allowed_file_extensions: allowed_file_extensions,
      role: role
    )
  end

  def previous(%Plug.Conn{assigns: %{role: role, user: user}} = conn, %{
        "assignment_id" => assignment_id
      }) do
    assignment = Assignments.get!(assignment_id)
    submissions = Submissions.list_by_author_and_assignment(user.id, assignment_id)

    render(conn, "previous.html",
      assignment: assignment,
      role: role,
      submissions: submissions
    )
  end

  def show(%Plug.Conn{assigns: %{role: role}} = conn, %{"id" => submission_id}) do
    submission = Submissions.get_with_jobs!(submission_id)

    with [job] <- submission.jobs do
      {:ok, events} = EventStore.read_stream_forward(job.id)

      live_render(conn, ThesisWeb.SubmissionLiveView,
        session: %{
          submission: submission,
          job: job,
          events: events,
          role: role
        }
      )
    else
      _ ->
        live_render(conn, ThesisWeb.SubmissionLiveView,
          session: %{
            submission: submission,
            role: role
          }
        )
    end
  end

  def files(conn, %{"id" => submission_id}) do
    submission = Submissions.get_with_files_with_content!(submission_id)
    previous_submission = Submissions.get_previous_submission(submission)

    diff =
      if previous_submission do
        Submissions.calculate_diff(previous_submission.files, submission.files)
      else
        Submissions.calculate_diff(nil, submission.files)
      end

    render(conn, "files.html",
      submission: submission,
      assignment: submission.assignment,
      diff: diff
    )
  end

  def submit(%Plug.Conn{assigns: %{user: user}} = conn, %{
        "file" => file,
        "assignment_id" => assignment_id,
        "comment" => comment
      }) do
    assignment = Assignments.get!(assignment_id)
    configuration = Assignments.get_latest_configuration!(assignment.id)

    %Configuration{
      allowed_file_extensions: allowed_file_extensions,
      required_files: required_files
    } = Configuration.parse_code(configuration.code)

    file_extension = Path.extname(file.filename)

    if file_extension not in allowed_file_extensions do
      allowed_list = Enum.join(allowed_file_extensions, ", ")
      Logger.debug("Invalid file extension: #{file_extension}, allowed: #{allowed_list}")

      conn
      |> put_flash(:error, "Invalid file extension: #{file_extension}, allowed: #{allowed_list}")
      |> redirect(to: current_path(conn))
    else
      files =
        if file.content_type in ["application/zip", "application/x-gzip"] do
          extracted_files = Thesis.Extractor.extract!(file.path)
          for {name, contents} <- extracted_files, do: %{name: name, contents: contents}
        else
          [%{name: file.filename, contents: Elixir.File.read!(file.path)}]
        end

      filenames = Enum.map(files, fn %{name: name} -> name end)
      missing_files = MapSet.difference(MapSet.new(required_files), MapSet.new(filenames))

      if not Enum.empty?(missing_files) do
        missing_files_list = Enum.join(missing_files, ", ")
        Logger.debug("Missing required file(s): #{missing_files_list}")

        conn
        |> put_flash(:error, "Missing required file(s): #{missing_files_list}")
        |> redirect(to: current_path(conn))
      end

      submission =
        Submissions.create!(user, assignment, %{jobs: [], files: files, comment: comment})

      token = Submissions.create_download_token!(submission)

      download_url =
        Application.get_env(:thesis, :submission_download_hostname) <>
          Routes.submission_path(conn, :download, token.id)

      job =
        Submissions.create_job!(submission, %{
          image: "test:latest",
          cmd: "mix test_suite #{download_url} #{submission.id}"
        })

      Thesis.Coderunner.start_event_stream(job)

      redirect(conn, to: Routes.submission_path(conn, :show, submission.id))
    end
  end

  def submit(conn, %{"assignment_id" => _assignment_id}) do
    conn
    |> put_flash(:error, "No file was specified")
    |> redirect(to: current_path(conn))
  end

  def download(conn, %{"token_id" => token_id}) do
    submission = Submissions.get_by_token!(token_id)

    files = for f <- submission.files, do: %File{f | contents: Base.encode64(f.contents)}

    configuration = Assignments.get_latest_configuration!(submission.assignment_id)

    data =
      Thesis.Configuration.parse_code(configuration.code)
      |> Map.from_struct()
      |> Map.put(:files, files)
      |> IO.inspect()

    # TODO: Uncomment to enable download token removal (One-time-use tokens)
    # Submissions.remove_token!(token)

    render(conn, "download.json", data: data)
  end
end
