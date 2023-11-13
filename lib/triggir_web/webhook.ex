defmodule TriggerWeb.Webhook do
  def build_key(k, prefix) do
    if(prefix != "", do: "#{prefix}_#{k}", else: k)
    |> String.upcase()
  end

  def envify_map(m) do
    Enum.reduce(
      m,
      [],
      fn el, acc -> acc ++ envify_map(el, "") end
    )
  end

  def envify_map({k, v}, prefix) when is_list(v) do
    case Jason.encode(v) do
      {:ok, v} ->
        envify_map({k, v}, prefix)

      {:error, _} ->
        []
    end
  end

  def envify_map({k, v}, prefix) when is_map(v) do
    Enum.reduce(
      v,
      [],
      fn v, acc ->
        acc ++ envify_map(v, build_key(k, prefix))
      end
    )
  end

  def envify_map({k, v}, prefix) do
    [{build_key(k, prefix), "#{v}"}]
  end

  def build_context(request_body, workdir) do
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
end
