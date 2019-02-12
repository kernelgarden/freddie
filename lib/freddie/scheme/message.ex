defmodule Freddie.Scheme.Message do

  defmacro __using__(opts) do
    quote do
      #use Protobuf, opts

      import Freddie.Scheme.Message
    end
  end
end
