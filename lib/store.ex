defmodule Ams.Store do
  def store(annonser, filename) do
    {:ok, file} = File.open filename, [:write]
    IO.binwrite file, Poison.encode_to_iodata!(annonser)
    File.close file
  end
end
