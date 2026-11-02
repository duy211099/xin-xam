defmodule ChuaTau.Fortunes do
  @moduledoc """
  Fortune collections, loaded once at application start from `priv/fortunes/*.json`.

  Each file is one collection. Data is parsed and validated here, at the boundary,
  and a bad file stops the boot with a message naming the file and the problem.
  """

  alias ChuaTau.{Collection, Fortune}
  alias ChuaTau.Fortunes.Sample

  @notice "Nội dung mẫu, không phải lời xăm truyền thống."
  @max_total 500
  @slug ~r/^[a-z0-9]+(-[a-z0-9]+)*$/
  @key {__MODULE__, :state}

  def notice, do: @notice

  ## Boot

  @doc "Loads `priv/fortunes` into `:persistent_term`. Raises on bad data."
  def load! do
    collections = load_dir!(default_dir())
    :persistent_term.put(@key, %{collections: collections, json: encode(collections)})
    :ok
  end

  def default_dir, do: Application.app_dir(:chua_tau, "priv/fortunes")

  def load_dir!(dir) do
    case load_dir(dir) do
      {:ok, collections} -> collections
      {:error, message} -> raise ArgumentError, "invalid fortune data: " <> message
    end
  end

  @spec load_dir(Path.t()) :: {:ok, [Collection.t()]} | {:error, String.t()}
  def load_dir(dir) do
    dir
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
      case read_file(path) do
        {:ok, collection} -> {:cont, {:ok, [collection | acc]}}
        {:error, message} -> {:halt, {:error, "#{Path.basename(path)}: #{message}"}}
      end
    end)
    |> case do
      {:ok, []} -> {:error, "no .json files in #{dir}"}
      {:ok, collections} -> collections |> Enum.reverse() |> sort_and_check_ids()
      error -> error
    end
  end

  defp read_file(path) do
    with {:ok, body} <- File.read(path),
         {:ok, data} <- Jason.decode(body) do
      parse_collection(data)
    else
      {:error, %Jason.DecodeError{} = e} -> {:error, "not valid JSON (#{Exception.message(e)})"}
      {:error, reason} -> {:error, "cannot read file (#{inspect(reason)})"}
    end
  end

  defp sort_and_check_ids(collections) do
    sorted = Enum.sort_by(collections, &(&1.order || 1_000_000))

    case sorted |> Enum.map(& &1.id) |> Enum.frequencies() |> Enum.find(fn {_, n} -> n > 1 end) do
      nil -> {:ok, sorted}
      {id, _} -> {:error, "collection id #{inspect(id)} is used by more than one file"}
    end
  end

  ## Parsing

  @spec parse_collection(term()) :: {:ok, Collection.t()} | {:error, String.t()}
  def parse_collection(%{} = data) do
    with {:ok, id} <- slug(data["collection"]),
         {:ok, name} <- text(data, "name"),
         {:ok, total} <- total(data["total"]),
         {:ok, order} <- order(data["order"]),
         {:ok, sample} <- bool(data["sample"], "sample"),
         {:ok, list} <- list(data["fortunes"]),
         {:ok, entries} <- parse_entries(list, total, sample) do
      {:ok,
       %Collection{
         id: id,
         name: name,
         total: total,
         sample: sample,
         order: order,
         entries: entries
       }}
    end
  end

  def parse_collection(_), do: {:error, "top level must be a JSON object"}

  defp slug(id) when is_binary(id) do
    if Regex.match?(@slug, id),
      do: {:ok, id},
      else: {:error, ~s("collection" must be a lowercase slug like "quan-am", got #{inspect(id)})}
  end

  defp slug(_), do: {:error, ~s("collection" is required and must be a string)}

  defp total(n) when is_integer(n) and n in 1..@max_total, do: {:ok, n}

  defp total(n),
    do: {:error, ~s("total" must be an integer in 1..#{@max_total}, got #{inspect(n)})}

  defp order(nil), do: {:ok, nil}
  defp order(n) when is_integer(n), do: {:ok, n}
  defp order(n), do: {:error, ~s("order" must be an integer, got #{inspect(n)})}

  defp bool(nil, _), do: {:ok, false}
  defp bool(b, _) when is_boolean(b), do: {:ok, b}
  defp bool(b, key), do: {:error, ~s("#{key}" must be true or false, got #{inspect(b)})}

  defp list(l) when is_list(l), do: {:ok, l}
  defp list(_), do: {:error, ~s("fortunes" is required and must be a list)}

  defp text(map, key) do
    case map[key] do
      s when is_binary(s) and s != "" ->
        {:ok, s}

      other ->
        {:error, ~s("#{key}" is required and must be a non-empty string, got #{inspect(other)})}
    end
  end

  defp parse_entries(list, total, collection_sample) do
    Enum.reduce_while(list, {:ok, %{}}, fn raw, {:ok, acc} ->
      with {:ok, fortune} <- parse_fortune(raw, total, collection_sample),
           :ok <- unique(acc, fortune.number) do
        {:cont, {:ok, Map.put(acc, fortune.number, fortune)}}
      else
        {:error, message} -> {:halt, {:error, message}}
      end
    end)
  end

  defp unique(acc, number) do
    if Map.has_key?(acc, number), do: {:error, "duplicate fortune number #{number}"}, else: :ok
  end

  defp parse_fortune(%{"number" => n} = raw, total, collection_sample) when is_integer(n) do
    with :ok <- in_range(n, total),
         {:ok, title} <- fortune_text(raw, n, "title"),
         {:ok, interpretation} <- fortune_text(raw, n, "interpretation"),
         {:ok, advice} <- fortune_text(raw, n, "advice"),
         {:ok, category} <- fortune_text(raw, n, "category"),
         {:ok, poem} <- poem(raw["poem"], n),
         {:ok, sample} <- bool(raw["sample"], "sample") do
      {:ok,
       %Fortune{
         number: n,
         title: title,
         category: category,
         poem: poem,
         interpretation: interpretation,
         advice: advice,
         sample: collection_sample or sample,
         generated: false
       }}
    end
  end

  defp parse_fortune(raw, _, _),
    do: {:error, "fortune without an integer \"number\": #{inspect(raw, limit: 5)}"}

  defp in_range(n, total) when n in 1..total//1, do: :ok
  defp in_range(n, total), do: {:error, "fortune number #{n} is outside 1..#{total}"}

  defp fortune_text(raw, n, key) do
    case raw[key] do
      s when is_binary(s) and s != "" -> {:ok, s}
      _ -> {:error, ~s(fortune #{n}: "#{key}" is required and must be a non-empty string)}
    end
  end

  defp poem([_ | _] = lines, n) do
    if Enum.all?(lines, &(is_binary(&1) and &1 != "")),
      do: {:ok, lines},
      else: {:error, ~s(fortune #{n}: "poem" lines must be non-empty strings)}
  end

  defp poem(_, n),
    do: {:error, ~s(fortune #{n}: "poem" is required and must be a non-empty list of lines)}

  ## Access

  def all, do: state().collections

  def get(id), do: Enum.find(all(), &(&1.id == id))

  @doc "A written fortune, or the deterministic generated sample for that number."
  @spec fortune(Collection.t(), integer()) :: Fortune.t() | nil
  def fortune(%Collection{total: total}, n) when not is_integer(n) or n < 1 or n > total, do: nil

  def fortune(%Collection{entries: entries, id: id}, n),
    do: Map.get(entries, n) || Sample.entry(id, n)

  def json, do: state().json

  @doc "Encodes collections as the page JSON: every number 1..total is present."
  def encode(collections) do
    %{
      notice: @notice,
      collections:
        for c <- collections do
          %{
            collection: c.id,
            name: c.name,
            total: c.total,
            sample: c.sample,
            generateSamples: false,
            fortunes: for(n <- 1..c.total, do: fortune(c, n))
          }
        end
    }
    |> Jason.encode!(escape: :html_safe)
  end

  defp state, do: :persistent_term.get(@key)
end
