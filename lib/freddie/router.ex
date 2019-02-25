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
      packet_types_mod =
        Application.get_env(
          :freddie,
          :packet_type_mod
        )

      protocol =
        quote do
          unquote(packet_types_mod).unquote(protocol).value()
        end

      protocol_seq =
        quote do
          elem(unquote(protocol), 0)
        end

      protocol_scheme =
        quote do
          elem(unquote(protocol), 1)
        end

      defp internal_dispatch(protocol_seq, var!(meta), payload, var!(context)) do
        var!(msg) = unquote(protocol_scheme).decode(payload)
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
        :packet_type_mod
      )

    packet_types
  end

  defp load_packet_scheme_mod() do
    packet_scheme_mod =
      Application.get_env(
        :freddie,
        :scheme_root_mod
      )

    packet_scheme_mod
  end

  def load_scheme_table() do
    case load_packet_scheme_mod() do
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
    case load_packet_scheme_mod() do
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
    custom_handler_schemes =
      packet_handler_mod.defs()
      |> Enum.with_index()
      # |> IO.inspect(label: "[DEBUG] => ")
      |> Enum.map(fn {def, idx} ->
        {{:msg, protocol_mod}, _} = def

        {protocol_mod, idx}
      end)

    default_handler_schemes =
      Freddie.Scheme.Common.defs()
      |> Enum.with_index()
      # |> IO.inspect(label: "[DEBUG] => ")
      |> Enum.map(fn {def, idx} ->
        {{:msg, protocol_mod}, _} = def

        # Specify to avoid module here!
        case protocol_mod do
          Freddie.Scheme.Common.BigInteger ->
            nil

          Freddie.Scheme.Common.Message ->
            nil

          Freddie.Scheme.Common.Message.Meta ->
            nil

          other ->
            {protocol_mod, -idx}
        end
      end)
      |> Enum.reduce([], fn elem, acc ->
        case elem do
          nil ->
            acc

          other ->
            [elem | acc]
        end
      end)

    default_handler_schemes ++ custom_handler_schemes
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
