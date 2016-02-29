defmodule Ams.Annons do
  @moduledoc """
  Parsar en enskild annons.
  """
  def get(%{"annonsid" => annonsid}) do
    :timer.sleep(100)
    case HTTPoison.get("http://api.arbetsformedlingen.se/af/v0/platsannonser/#{annonsid}", %{"Accept" => "application/json", "Accept-Language" => "sv"}) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        annons = body |> Poison.decode!
        annons["platsannons"]
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
        %{}
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "annons: #{annonsid} : #{reason}"
        %{"annons" => %{}}
    end
  end
end
