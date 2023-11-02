defmodule TriggirWeb.RunOutputController do
  use TriggirWeb, :controller

  def shas_list(conn, params) do
    case Application.fetch_env!(:triggir, :runs_path)
         |> Path.join("workspaces")
         |> Path.join(params["project"])
         |> File.ls() do
      {:ok, shas} ->
        render(conn, :links_list,
          links: Enum.map(shas, fn sha -> "/gitlab/#{params["project"]}/#{sha}" end)
        )

      # TOOD: make an error page for this junk
      {:error, reason} ->
        render(conn, :single_run, run_output: reason)
    end
  end

  def projects_list(conn, params) do
    case Application.fetch_env!(:triggir, :runs_path)
         |> Path.join("workspaces")
         |> File.ls() do
      {:ok, projects} ->
        render(conn, :links_list, links: Enum.map(projects, fn p -> "/gitlab/#{p}" end))

      {:error, reason} ->
        render(conn, :single_run, run_output: reason)
    end
  end

  def show(conn, params) do
    case Enum.reduce(
           [
             Application.fetch_env!(:triggir, :runs_path),
             "workspaces",
             params["project"],
             params["sha"],
             ".taskir-output"
           ],
           fn path, acc -> Path.join(acc, path) end
         )
         |> File.read() do
      # TODO: handle errors
      {_, data} ->
        # translate newlines to breaks
        render(conn, :single_run, run_output: data)
    end
  end
end
