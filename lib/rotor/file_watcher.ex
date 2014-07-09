defmodule Rotor.FileWatcher do
  import Rotor.Utils
  use GenServer


  # group_info will have %{name: name}
  def init(group_info) do
    {:ok, group_info}
  end


  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end


  def handle_call(:poll, _from, state) do
    {changed_files, file_index} = case get_in(state, [:file_index]) do
      nil ->
        {:ok, group_info} = Rotor.WatchGroupServer.group(state.name)
        file_index = build_file_index(group_info.paths)
        state = put_in state[:file_index], file_index
        {[], file_index}
      index ->
        update_file_index_timestamps(index)
    end

    if length(changed_files) != 0 do
      state = put_in state[:file_index], file_index
      Rotor.WatchGroupServer.trigger(state.name, changed_files, HashDict.values(file_index))
    end

    interval = get_in group_info, [:options, :interval]
    Process.send_after(self, :poll, interval)
    {:reply, :ok, state}
  end


end
