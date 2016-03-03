defmodule Ams.Lan do
  def get(%{"antal_ledigajobb" => av_jobs, "antal_platsannonser" => ads,
            "id" => lanid, "namn" => lan}) do
    # Räkna ut antal sidor, med per_page per sida.
    # Starta en process för varje sida, som i sin tur startar en process för vare listning
    per_page = 10
    pages = Float.ceil(ads / per_page) |> round
    pages = Range.new(1, pages)

    pages
    |> Stream.chunk(2, 2, [])
    |> Stream.map((fn (page) -> fetch_and_parse_batch(page, lanid, per_page) end))
    |> Enum.to_list # force execution for every stream batch
  end

  def fetch_and_parse_batch(pages, lanid, per_page) do
    IO.puts "batch fetch pages:"
    IO.inspect pages
    pages
    |> Enum.map((fn (page) -> Task.async(fn -> get_listings(%{lanid: lanid, page: page, rows: per_page}) end) end))
    |> Enum.map((fn (page) -> Task.await(page, 1000 * 300) end)) # We add higher timeout so all the functions below have time to finish
  end

  def get_listings(%{lanid: lanid, page: page, rows: rows}) do
    :timer.sleep(100)
    IO.puts "Get listings: lanid: #{lanid}; page: #{page}; rows: #{rows}"

    case HTTPoison.get("http://api.arbetsformedlingen.se/af/v0/platsannonser/matchning?lanid=#{lanid}&antalrader=#{rows}&sida=#{page}", %{"Accept" => "application/json", "Accept-Language" => "sv"}) do
      {:ok, %HTTPoison.Response{status_code: 200, body: listings}} ->
        listings = Poison.decode!(listings)["matchningslista"]["matchningdata"]

        listings
        |> Enum.map((fn (listing) -> Task.async(fn -> Ams.Annons.get(listing) end) end))
        |> Enum.map((fn (listing) -> Task.await(listing, 1000 * 60) end))
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "cant get #{lanid}: #{reason}"
        []
    end
  end
end
