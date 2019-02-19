defmodule Freddie.Router do
  require Logger

  @root_module SchemeTable

  @on_load :load_scheme_table

  defmacro __using__(_opts) do
    quote do
      import Freddie.Router

      def dispatch({command, meta, payload}, socket) do
        internal_dispatch(command, meta, payload, socket)
      end

      def dispatch(:disconnect, socket) do
        internal_dispatch(:disconnect, socket)
      end

      def dispatch(:connect, socket) do
        internal_dispatch(:connect, socket)
      end

      unquote(prelude())
    end
  end

  defmacro __before_compile__(_env) do
    compile_scheme_table()
  end

  defmacro handler(protocol, body) do
    quote bind_quoted: [
            protocol: Macro.escape(protocol, unquote: true),
            body: Macro.escape(body, unquote: true)
          ] do
      protocol_seq =
        quote do
          get_scheme_seq(unquote(protocol))
        end

      defp internal_dispatch(protocol_seq, var!(meta), payload, var!(socket)) do
        protocol_mod = unquote(protocol)
        var!(msg) = protocol_mod.decode(payload)
        unquote(body[:do])
      end
    end
  end

  defmacro disconnect(body) do
    quote bind_quoted: [
      body: Macro.escape(body, unquote: true)
    ] do
      defp internal_dispatch(:disconnect, var!(socket)) do
        unquote(body[:do])
      end
    end
  end

  defmacro connect(body) do
    quote bind_quoted: [
      body: Macro.escape(body, unquote: true)
    ] do
      defp internal_dispatch(:connect, var!(socket)) do
        unquote(body[:do])
      end
    end
  end

  def lookup(scheme) do
    root_mod = root_mod_term()
    apply(root_mod, Freddie.Router.Builder.key_to_term(scheme), [])
  end

  defp internal_dispatch(unknown_seq, _, _, _) do
    Logger.warn("received unkown protocol #{unknown_seq}")
  end

  defp prelude() do
    quote do
      @before_compile unquote(__MODULE__)

    end
  end

  defp root_mod_term(), do: :"#{@root_module}"

  defp load_packet_handler_mod() do
    packet_handler_mod =
      Application.get_env(
        :freddie,
        :scheme_root_mod
      )

    packet_handler_mod
  end

  def load_scheme_table() do
    case load_packet_handler_mod() do
      nil ->
        Logger.warn("packet_handler_mod doesn't registered")
        :abort
      mod ->
        case function_exported?(mod, :defs, 0) do
          # Not need to compile
          true ->
            Logger.info("packet_handler_mod: #{mod}")
            mod
            |> make_schemes()
            |> generate_scheme_table()
            :ok

          # To compile first! Not defined protocols
          false ->
            # pass now
            :ok
        end
    end
  end

  defp compile_scheme_table() do
    case load_packet_handler_mod() do
      nil ->
        Logger.warn("packet_handler_mod doesn't registered")
      mod ->
            Logger.info("packet_handler_mod: #{mod}")
            mod
            |> make_schemes()
            |> generate_scheme_table()
    end
  end

  defp make_schemes(packet_handler_mod) do
    packet_handler_mod.defs()
    |> Enum.with_index()
    #|> IO.inspect(label: "[DEBUG] => ")
    |> Enum.map(fn {def, idx} ->
      {{:msg, protocol_mod}, _} = def

      {protocol_mod, idx}
    end)
  end

  defp generate_scheme_table(schemes) do
    module = root_mod_term()
    binary = Freddie.Router.Builder.compile(module, schemes)
    :code.purge(module)
    {:module, ^module} = :code.load_binary(module, '#{module}.erl', binary)
    :ok
  end

  # Use only in macro!
  defp get_scheme_seq(scheme) do
    root_mod = root_mod_term()
    func_name = Freddie.Router.Builder.key_to_term(scheme)
    root_mod.func_name
  end
end
