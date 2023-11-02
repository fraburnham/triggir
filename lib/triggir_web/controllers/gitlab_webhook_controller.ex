defmodule TriggirWeb.GitlabWebhookController do
  use TriggirWeb, :controller

  defp build_key(k, prefix) do
    if(prefix != "", do: "#{prefix}_#{k}", else: k)
    |> String.upcase()
  end

  defp envify_map(m) do
    Enum.reduce(
      m,
      [],
      fn el, acc -> acc ++ envify_map(el, "") end
    )
  end

  defp envify_map({k, v}, prefix) when is_list(v) do
    case Jason.encode(v) do
      {:ok, v} ->
        envify_map({k, v}, prefix)

      {:error, _} ->
        []
    end
  end

  defp envify_map({k, v}, prefix) when is_map(v) do
    Enum.reduce(
      v,
      [],
      fn v, acc ->
        acc ++ envify_map(v, build_key(k, prefix))
      end
    )
  end

  defp envify_map({k, v}, prefix) do
    # gotta be a better way to handle numbers...
    [{build_key(k, prefix), "#{v}"}]
  end

  defp build_context(request_body, workdir) do
    %{"env" => envify_map(request_body |> Map.put("WORKDIR", workdir))}
  end

  def store_results(results, workdir) do
    # This is likely to be a bad pattern for large outputs
    File.write!(
      Path.join(workdir, ".taskir-output"),
      Enum.reduce(
        results,
        "",
        fn result, acc ->
          {_, data} = result
          acc <> "\n----\n" <> data
        end
      )
    )
  end

  def run(conn, request_body) do
    # Work needs to happen in a separate process eventually. For experimentation this is probably fine.
    base_dir = Application.fetch_env!(:triggir, :runs_path)
    project = request_body["repository"]["name"]
    sha = request_body["checkout_sha"]

    workdir =
      Enum.reduce(
        [base_dir, "workspaces", project, sha],
        fn path, acc ->
          Path.join(acc, path)
        end
      )

    setup_results = Taskir.main(build_context(request_body, workdir), "tasks/checkout.yaml")
    IO.puts(inspect(setup_results))

    with :ok <- File.mkdir_p(workdir),
         true <- Enum.all?(setup_results, fn {status, _} -> status == :ok end) do
      store_results(
        setup_results ++
          Taskir.main(
            build_context(request_body, workdir) |> Map.put("workdir", workdir),
            "#{workdir}/.taskirci/tasks.yaml"
          ),
        workdir
      )

      json(conn, %{status: "ok"})
    else
      _ ->
        json(conn, %{status: "failed"})
    end
  end
end
