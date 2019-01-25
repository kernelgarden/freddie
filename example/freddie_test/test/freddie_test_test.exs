defmodule FreddieTestTest do
  use ExUnit.Case
  doctest FreddieTest

  test "greets the world" do
    assert FreddieTest.hello() == :world
  end
end
