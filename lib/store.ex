defmodule Ams.Store do
  def store(annonser) do
    {:ok, file} = File.open "store.txt", [:write]
    IO.binwrite file, Poison.encode_to_iodata!(annonser)
    File.close file
  end
end
