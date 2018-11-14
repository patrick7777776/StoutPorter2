defmodule StemBench do

  use Benchfella

  setup_all do
    words = 
      File.stream!("data/pairs.txt", [:read, :utf8], :line)
      |> Stream.map(fn line -> String.split(line) |> hd end)
      |> Enum.to_list
    {:ok, words}
  end

  defp p([]), do: :ok
  defp p([w|ws]) do
    StoutPorter2.stem(w)
    p(ws)
  end

  bench "raw performance 30k" do
    p(bench_context)
  end

end
