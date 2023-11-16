defmodule Triggir.TaskManager do
  use GenServer

  @impl GenServer
  def init(initial_state) do
    {:ok,
     initial_state
     |> Map.put(:incoming_tasks, :queue.new())
     |> Map.put(:worker_pids, [])
     |> Map.put(:worker_count, 0)}
  end

  @impl GenServer
  def handle_cast(
        {:task, task_function},
        %{incoming_tasks: incoming_tasks} = state
      ) do
    {:noreply,
     start_or_defer(
       state
       |> Map.put(:incoming_tasks, :queue.in(task_function, incoming_tasks))
     )}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    {:noreply, start_or_defer(state)}
  end

  defp reap(%{worker_pids: worker_pids} = state) do
    Enum.reduce(
      worker_pids,
      state |> Map.put(:worker_pids, []) |> Map.put(:worker_count, 0),
      fn pid, %{worker_pids: worker_pids, worker_count: worker_count} = state ->
        if Process.alive?(pid) do
          state
          |> Map.put(:worker_pids, [pid | worker_pids])
          |> Map.put(:worker_count, worker_count + 1)
        else
          state
        end
      end
    )
  end

  defp reap(state) do
    state
  end

  def start_or_defer(
        %{
          incoming_tasks: incoming_tasks,
          worker_pids: worker_pids,
          worker_count: worker_count,
          max_workers: max_workers
        } = state
      ) do
    state = reap(state)

    case :queue.out(incoming_tasks) do
      {:empty, _} ->
        state

      {{:value, task_function}, remaining_tasks} ->
        if worker_count < max_workers do
          state
          |> Map.put(:worker_pids, [
            spawn(fn ->
              task_function.()
            end)
            | worker_pids
          ])
          |> Map.put(:worker_count, worker_count + 1)
          |> Map.put(:incoming_tasks, remaining_tasks)
          |> start_or_defer
        else
          Process.send_after(self(), :tick, 100)
          state
        end
    end
  end

  def start_or_defer(state) do
    reap(state)
  end

  def start(%{max_workers: _max_workers} = options) do
    # TODO: validate options
    # TODO: use Supervisor
    GenServer.start(__MODULE__, options, name: __MODULE__)
  end

  def start(options) do
    start(
      options
      |> Map.put(:max_workers, options[:max_workers] || 5)
    )
  end

  def start_link(options) do
    GenServer.start(
      __MODULE__,
      options
      |> Map.put(:max_workers, options[:max_workers] || 5),
      name: __MODULE__
    )
  end

  def run(task_function) do
    GenServer.cast(__MODULE__, {:task, task_function})
  end
end
