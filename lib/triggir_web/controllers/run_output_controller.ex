defmodule TriggirWeb.RunOutputController do
  use TriggirWeb, :controller

  def runs_list(conn, params) do
    # TODO: sort by CTIME
    root_dir = Application.fetch_env!(:triggir, :runs_path)

    case Path.join(root_dir, params["trigger"])
         |> Path.join(params["project"])
         |> File.ls() do
      {:ok, runs} ->
        render(conn, :links_list,
          links:
            Enum.map(runs, fn r -> "/#{params["trigger"]}/#{params["project"]}/#{r}" end)
            |> Enum.sort(fn a, b ->
              %{ctime: a_ctime} = File.stat!(Path.join(root_dir, a))
              %{ctime: b_ctime} = File.stat!(Path.join(root_dir, b))
              # want most recent at the front of the list
              b_ctime <= a_ctime
            end)
        )

      # TOOD: make an error page for this junk
      {:error, reason} ->
        render(conn, :single_run, run_output: reason)
    end
  end

  def projects_list(conn, params) do
    # TODO: sort alphabetically
    case Application.fetch_env!(:triggir, :runs_path)
         |> Path.join(params["trigger"])
         |> File.ls() do
      {:ok, projects} ->
        render(conn, :links_list,
          links: Enum.map(projects, fn p -> "/#{params["trigger"]}/#{p}" end)
        )

      {:error, reason} ->
        render(conn, :single_run, run_output: reason)
    end
  end

  def triggers_list(conn, _params) do
    # TODO: sort alphabetically (maybe automatic?)
    case Application.fetch_env!(:triggir, :runs_path)
         |> File.ls() do
      {:ok, triggers} ->
        render(conn, :links_list, links: Enum.map(triggers, fn t -> "/#{t}" end))

      {:error, reason} ->
        render(conn, :single_run, run_output: reason)
    end
  end

  def show(conn, params) do
    case Enum.reduce(
           [
             Application.fetch_env!(:triggir, :runs_path),
             params["trigger"],
             params["project"],
             params["run"],
             ".taskir-output"
           ],
           fn path, acc -> Path.join(acc, path) end
         )
         |> File.read() do
      # TODO: handle errors
      {:ok, data} ->
        render(conn, :single_run, run_output: data)

      {:error, cause} ->
        render(conn, :single_run, run_output: "Failed to read run output: '#{cause}'")
    end
  end
end
