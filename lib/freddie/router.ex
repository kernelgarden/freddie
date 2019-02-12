defmodule Freddie.Router do

  require Logger

  defmacro __using__(_opts) do
    quote do
      import Freddie.Router

      def dispatch({command, meta, payload}, socket) do
        internal_dispatch(command, meta, payload, socket)
      end

      unquote(prelude())
    end
  end

  defmacro __before_compile__(_env) do
    FreddieTest.Scheme.defs()
    |> Enum.with_index()
    |> Enum.each(fn {def, idx} ->
        {{:msg, protocol_mod}, _} = def
        fetch_fn = quote do
          def seq(), do: idx
        end
        Module.eval_quoted(protocol_mod, fetch_fn)
        IO.puts("=====> #{inspect protocol_mod}")
      end)
  end

  defmacro handler(protocol, body) do
    quote bind_quoted: [
      protocol: Macro.escape(protocol, unquote: true),
      body: Macro.escape(body, unquote: true)
    ] do
      protocol_seq = quote do
        unquote(protocol).seq()
      end

      defp internal_dispatch(protocol_seq, var!(meta), payload, var!(socket)) do
        protocol_mod = unquote(protocol)
        var!(msg) = protocol_mod.decode(payload)
        unquote(body[:do])
      end
    end
  end

  defp internal_dispatch(unknown_seq, _, _, _) do
    Logger.warn("received unkown protocol #{unknown_seq}")
  end

  defp prelude() do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  ~S"""
  defmacro reply() do
    quote do
      defp internal_dispatch(:reply, )
    end
  end

  defmacro res_only do
  end
  """
end
