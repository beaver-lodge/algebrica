defmodule AlgebricaTest do
  use ExUnit.Case, async: true

  doctest Algebrica

  test "returns the project name" do
    assert Algebrica.name() == "Algebrica"
  end
end
