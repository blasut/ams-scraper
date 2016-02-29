defmodule Ams.Listning do
  def all do
    # Hämta alla län
    {:ok, %{body: lanlista}} = HTTPoison.get("http://api.arbetsformedlingen.se/af/v0/platsannonser/soklista/lan", %{"Accept" => "application/json", "Accept-Language" => "sv"})
    # För varje hämta alla annonser
    lanlista = Poison.decode!(lanlista)
    lanlista = lanlista["soklista"]["sokdata"]
  end

  def parse(lanlista) do
    lanlista
    |> Stream.chunk(1, 1, [])
    |> Stream.map(fn(lans) -> fetch_and_parse_batch(lans) end)
    |> Enum.to_list
    |> List.flatten
  end

  def fetch_and_parse_batch(lans) do
    IO.inspect "start batch"
    IO.inspect lans
    lans
    |> Enum.map((fn (lan) -> Task.async(fn -> Ams.Lan.get(lan) end) end))
    |> Enum.map((fn (lan) -> Task.await(lan, 1000 * 6000) end)) # We add higher timeout so all the functions below have time to finish
  end
end
