defmodule FreddieTest do
  use ExUnit.Case
  doctest Freddie

  test "greets the world" do
    assert Freddie.hello() == :world
  end
end
