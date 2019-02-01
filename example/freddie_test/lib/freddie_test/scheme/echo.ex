defmodule FreddieTest.Scheme do
  use Protobuf, """
  syntax = "proto3";
  package Common;

  message Echo {
      string msg = 1;
  }
  """
end
