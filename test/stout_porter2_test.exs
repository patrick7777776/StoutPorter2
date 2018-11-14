defmodule StoutPorter2Test do
  use ExUnit.Case

  test "Agreement with official examples" do
    disagreements =
      File.stream!("data/pairs.txt", [:read, :utf8], :line)
      |> Stream.map(fn line -> String.split(line) end)
      |> Stream.filter(fn [word, stem] -> StoutPorter2.stem(word) != stem end)
      |> Enum.to_list()

    assert disagreements == []
  end
end
