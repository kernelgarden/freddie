defmodule Freddie.Router do
  require Logger

  @root_module SchemeTable

  @on_load :load_scheme_table

  defmacro __using__(_opts) do
    quote do
      import Freddie.Router

      def dispatch({command, meta, payload}, context) do
        internal_dispatch(command, meta, payload, context)
      end

      def dispatch(:disconnect, context) do
        internal_dispatch(:disconnect, context)
      end

      def dispatch(:connect, context) do
        internal_dispatch(:connect, context)
      end

      unquote(prelude())
    end
  end

  defmacro __before_compile__(_env) do
    compile_scheme_table()
  end

  defmacro __after_compile__(_env, _byte_code) do
  end

  defmacro defhandler(protocol, body) do
    quote bind_quoted: [
            protocol: Macro.escape(protocol, unquote: true),
            body: Macro.escape(body, unquote: true)
          ] do

      protocol_seq = quote do
        get_scheme_seq(unquote(protocol))
      end

      defp internal_dispatch(protocol_seq, var!(meta), payload, var!(context)) do
        var!(msg) = unquote(protocol).decode(payload)
        unquote(body[:do])
      end
    end
  end

  defmacro disconnect(body) do
    quote bind_quoted: [
            body: Macro.escape(body, unquote: true)
          ] do
      defp internal_dispatch(:disconnect, var!(context)) do
        unquote(body[:do])
      end
    end
  end

  defmacro connect(body) do
    quote bind_quoted: [
            body: Macro.escape(body, unquote: true)
          ] do
      defp internal_dispatch(:connect, var!(context)) do
        unquote(body[:do])
      end
    end
  end

  defp internal_dispatch(unknown_seq, _, _, _) do
    Logger.warn("received unkown protocol #{unknown_seq}")
  end

  def lookup(scheme) do
    root_mod = root_mod_term()
    apply(root_mod, Freddie.Router.Builder.key_to_term(scheme), [])
  end

  defp prelude() do
    quote do
      @before_compile unquote(__MODULE__)

      @after_compile unquote(__MODULE__)
    end
  end

  defmacro make_internal_handler(internal_schemes) do
    quote bind_quoted: [
            internal_schemes: Macro.escape(internal_schemes, unquote: true)
          ] do
      defp internal_dispatch() do
      end
    end
  end

  defp root_mod_term(), do: :"#{@root_module}"

  defp load_packet_types() do
    packet_types =
      Application.get_env(
        :freddie,
        :packet_type_mod,
        nil
      )

    packet_types
  end

  defp load_packet_scheme_mod() do
    packet_scheme_mod =
      Application.get_env(
        :freddie,
        :scheme_root_mod,
        nil
      )

    packet_scheme_mod
  end

  defp load_mods() do
    {load_packet_scheme_mod(), load_packet_types()}
  end

  def load_scheme_table() do
    mods = {packet_scheme_mod, packet_types_mod} = load_mods()
    Logger.info("[DEBUG] => load_scheme_table")

    case (packet_scheme_mod == nil) or (packet_types_mod == nil) do
      true ->
        Logger.warn("packet_handler_mod doesn't registered")
        :abort

      false ->
        #case function_exported?(packet_scheme_mod, :defs, 0) and function_exported?(Freddie.Scheme.Common, :defs, 0) do
        #case function_exported?(packet_types_mod, :enums, 0) do
        case true do
          # Not need to compile
          true ->
            Logger.info("packet_handler_mod: #{inspect mods}")

            mods
            |> make_schemes()
            |> generate_scheme_table()

            :ok

          # To compile first! Not defined protocols
          false ->
            # pass now
            Logger.info("Booooom")
            :ok
        end
    end
  end

  defp compile_scheme_table() do
    mods = {packet_scheme_mod, packet_types_mod} = load_mods()

    case (packet_scheme_mod == nil) or (packet_types_mod == nil) do
      true ->
        Logger.warn("packet_handler_mod doesn't registered")

      false ->
        Logger.info("packet_handler_mod: #{inspect mods}")

        mods
        |> make_schemes()
        |> generate_scheme_table()
    end
  end

  defp make_schemes({packet_scheme_mod, packet_types_mod}) do
    prefix_length = length(Module.split(packet_types_mod))

    custom_types = packet_types_mod.enums()
    custom_schemes =
      custom_types
      |> Enum.map(fn type ->
          scheme =
            Module.split(type)
            |> Enum.drop(prefix_length)
            |> Module.concat()
          seq = packet_types_mod.value(type)
          {scheme, seq}
        end)

    internal_types = Freddie.InternalPackets.Types.enums()
    internal_schemes =
      internal_types
      |> Enum.map(fn type ->
          scheme =
            Module.split(type)
            |> Enum.drop(3)
            |> Module.concat()
          seq = Freddie.InternalPackets.Types.value(type)
          {scheme, seq}
        end)

    # IO.puts("[DEBUG] make_schemes => #{inspect internal_schemes}")

    internal_schemes ++ custom_schemes
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
