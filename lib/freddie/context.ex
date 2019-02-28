defmodule Freddie.Context do
  require Logger

  alias __MODULE__

  defstruct session: nil, __internal__: %{}

  @spec new(Freddie.Session.t()) :: Freddie.Context.t()
  def new(session) do
    %Context{session: session, __internal__: %{}}
  end

  ################################################################################
  ##
  ## Context API
  ##
  ################################################################################

  @spec put(Freddie.Context.t(), any(), any()) :: Freddie.Context.t()
  def put(context, key, value) do
    %Context{context | __internal__: Map.put(context.__internal__, key, value)}
    |> update_context()
  end

  @spec get(Freddie.Context.t(), any()) :: :error | {:ok, any()}
  def get(context, key) do
    Map.fetch(context.__internal__, key)
  end

  ################################################################################
  ##
  ## Session API
  ##
  ################################################################################

  @spec get_session(Freddie.Context.t()) :: Freddie.Session.t()
  def get_session(context) do
    context.session
  end

  @spec update_session(Freddie.Context.t(), any(), any()) :: Freddie.Context.t()
  def update_session(context, key, value) do
    new_session = Map.put(context.session, key, value)
    %Context{context | session: new_session}
  end

  @spec update_session(Freddie.Context.t(), keyword()) :: Freddie.Context.t()
  def update_session(context, update_list) when is_list(update_list) do
    new_session =
      update_list
      |> Enum.reduce(context.session, fn {key, value}, old_session ->
        Map.put(old_session, key, value)
      end)

    %Context{context | session: new_session}
  end

  @spec set_session(Freddie.Context.t(), Freddie.Session.t()) :: Freddie.Context.t()
  def set_session(context, new_session) do
    %Context{context | session: new_session}
  end

  defp update_context(new_context) do
    Freddie.Session.update_context(new_context)
  end
end
