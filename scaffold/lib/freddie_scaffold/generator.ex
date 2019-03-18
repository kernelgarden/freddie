defmodule FreddieScaffold.Generator do

  @app_name_holder "app_name"
  @app_mod_holder "app_mod"

  @template_path "./templates"

  def generate({target_path, app_name}) do
    validate_templates()

    project_info = FreddieScaffold.ProjectInfo.new(target_path, app_name)

    root = Path.join(project_info.target_path, project_info.app_name)

    if File.exists?(root) do
      Mix.raise("Already exists #{inspect root}!")
    end

    # create target root
    if File.mkdir_p(root) != :ok do
      Mix.raise("Failed to create root directory!")
    end

    copy_root(project_info, "")
  end

  defp validate_templates() do
    unless Path.basename("templates") do
      Mix.raise("Missing templates!")
    end
  end

  defp copy_root(project_info, path) do
    root_path = with_template_path(path)

    case File.ls(root_path) do
      {:ok, files} ->
        files
        |> Enum.each(&copy(project_info, path, &1))
      {:error, reason} ->
        Mix.raise("Failed to ls #{inspect root_path}!, reason: #{inspect reason}")
    end
  end

  defp copy(project_info, path, name) do
    file_path = Path.join(with_template_path(path), name)

    case File.dir?(file_path) do
      true ->
        copy_dir(project_info, path, name)

        # process recursive for directory
        copy_root(project_info, Path.join(path, name))

      false ->
        copy_file(project_info, path, name)
    end
  end

  defp copy_dir(project_info, path, name) do
    new_file_path = make_new_file_path(project_info, path, name)

    if File.mkdir_p(new_file_path) != :ok do
      Mix.raise("Failed to create directory #{inspect new_file_path}!")
    end
  end

  defp copy_file(project_info, path, name) do
    # origin file path
    file_path = Path.join(with_template_path(path), name)

    # new file path
    new_file_path = make_new_file_path(project_info, path, name)

    # adopt eex
    contents = EEx.eval_file(file_path, FreddieScaffold.ProjectInfo.get_replacer(project_info))

    File.write(new_file_path, contents, [:write])
  end

  defp make_new_file_path(project_info, path, name) do
    new_file_path = Path.join([project_info.target_path, project_info.app_name, path, name])

    new_file_path
    |> String.replace(@app_name_holder, project_info.app_name)
    |> String.replace(@app_mod_holder, project_info.app_mod)
  end

  defp template_path() do
    Path.expand(@template_path)
  end

  defp with_template_path(trail) do
    Path.join(template_path(), trail)
  end
end
