defmodule FreddieScaffold.Generator do

  @template_path "../../templates"

  def generate(target_path, app_name) do
    project_info = FreddieScaffold.ProjectInfo.new(target_path, app_name)


  end

  defp copy_templates(project_info) do
    template_path = Path.expand(@template_path)

    unless Path.basename("templates") do
      Mix.raise("Missing templates!")
    end

    File.ls(@template_path)
  end

  defp copy_template(project_info, target_file_path) do

  end
end
