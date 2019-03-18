defmodule FreddieScaffold.ProjectInfo do

  alias __MODULE__

  @restrict_chars ["."]

  defstruct app_name: "",
            app_mod: "",
            target_path: "",

  def new(target_path, app_name) do
    validate_name(app_name)

    app_mod = Macro.camelize(app_name)

    %ProjectInfo{
      app_name: app_name,
      app_mod: app_mod,
      target_path: target_path
    }
  end

  defp validate_name(app_name) do
    if !String.valid?(app_name) or String.contains?(app_name, @restrict_chars) do
      Mix.raise("Invalid app name!")
    end
  end

end
