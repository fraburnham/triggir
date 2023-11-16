defmodule TriggirWeb.GitlabWebhookController do
  use TriggirWeb, :controller
  import TriggerWeb.Webhook

  def get_run_numbers(paths, sha) do
    paths
    |> Stream.filter(fn el ->
      String.starts_with?(el, sha)
    end)
    |> Stream.map(fn el ->
      [_, num] = String.split(el, "-")
      num
    end)
    |> Enum.sort(:desc)
  end

  def get_last_run_number(project_dir, sha) do
    case File.ls(project_dir) do
      {:ok, paths} ->
        case get_run_numbers(paths, sha) do
          [run_num | _] -> String.to_integer(run_num)
          _ -> 0
        end

      {:error, _} ->
        0
    end
  end

  def get_workdir(trigger, project, sha) do
    project_dir =
      Enum.reduce(
        [Application.fetch_env!(:triggir, :runs_path), trigger, project],
        fn path, acc ->
          Path.join(acc, path)
        end
      )

    workdir_base = Path.join(project_dir, sha)
    next_num = get_last_run_number(project_dir, sha) + 1

    "#{workdir_base}-#{next_num}"
  end

  def run(conn, request_body) do
    Triggir.TaskManager.run(fn ->
      workdir =
        get_workdir(
          "gitlab",
          request_body["repository"]["name"],
          request_body["checkout_sha"]
        )

      setup_results =
        Taskir.main(
          build_context(request_body, workdir),
          "tasks/checkout.yaml"
        )

      with :ok <- File.mkdir_p(workdir),
           true <- Enum.all?(setup_results, fn {status, _} -> status == :ok end) do
        store_results(
          setup_results ++
            Taskir.main(
              build_context(request_body, workdir)
              |> Map.put("workdir", workdir),
              "#{workdir}/.triggir/tasks.yaml"
            ),
          workdir
        )
      end
    end)

    json(conn, %{status: "ok"})
  end
end
