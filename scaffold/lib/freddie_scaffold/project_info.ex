defmodule FreddieScaffold.ProjectInfo do

  alias __MODULE__

  @restrict_chars ["."]

  defstruct app_name: "",
            app_mod: "",
            freddie_version: "",
            target_path: "",
            template_type: "",
            template_list: [],
            project_prefix: "",
            firewood: nil

  def new({target_path, app_name, firewood}) do
    validate_name(app_name)

    app_mod = Macro.camelize(app_name)

    %ProjectInfo{
      app_name: app_name,
      app_mod: app_mod,
      freddie_version: "0.1.3",
      target_path: target_path,
      template_type: firewood.get_template_type(),
      template_list: firewood.get_template_list(),
      project_prefix: firewood.get_template_prefix(),
      firewood: firewood
    }
  end

  def get_replacer(project_info) do
    [
      app_name: project_info.app_name,
      app_mod: project_info.app_mod,
      freddie_version: project_info.freddie_version
    ]
  end

  defp validate_name(app_name) do
    if !String.valid?(app_name) or String.contains?(app_name, @restrict_chars) do
      Mix.raise("Invalid app name!")
    end
  end

end
