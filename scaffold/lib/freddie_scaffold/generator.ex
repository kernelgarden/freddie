defmodule FreddieScaffold.Generator do

  alias FreddieScaffold.ProjectInfo

  @app_name_holder "app_name"
  @app_mod_holder "app_mod"

  def generate(project_info) do
    root = Path.join(project_info.target_path, project_info.app_name)

    if File.exists?(root) do
      Mix.raise("Already exists #{inspect root}!")
    end

    # create target root
    if File.mkdir_p(root) != :ok do
      Mix.raise("Failed to create root directory!")
    end

    IO.ANSI.format([:green, "  [create]", :white, "  #{Path.join(project_info.app_name, project_info.template_type)}"], true)
    |> IO.puts()

    project_info.template_list
    |> Enum.each(&copy_file(project_info, &1))
  end

  defp copy_file(project_info, identifier) do
    # new file path
    new_file_path =
      make_new_file_path(project_info, identifier)
      |> make_dir_if_not_exists()

    # adopt eex
    contents = EEx.eval_string(project_info.firewood.get(identifier), ProjectInfo.get_replacer(project_info))

    File.write!(new_file_path, contents, [:write])

    print_create(identifier, project_info)
  end

  defp make_dir_if_not_exists(file_path) do
    String.trim_trailing(file_path, Path.join("/", Path.basename(file_path)))
    |> File.mkdir_p!()

    file_path
  end

  defp make_new_file_path(project_info, identifier) do
    [project_info.target_path, project_info.app_name, String.trim_leading(identifier, project_info.template_type)]
    |> Path.join()
    |> replace_holder(project_info)
  end

  defp replace_holder(base_string, project_info) do
    base_string
    |> String.replace(@app_name_holder, project_info.app_name)
    |> String.replace(@app_mod_holder, project_info.app_mod)
  end

  defp print_create(path, project_info) do
    path = replace_holder(path, project_info)

    IO.ANSI.format([:green, "  [create]"], true)
    |> IO.write()

    print_depth(path)

    IO.ANSI.format([:white, "  #{path}\n"], true)
    |> IO.write()
  end

  defp print_depth(path) do
    depth =
      path
      |> Path.split()
      |> Enum.count()

    String.duplicate("  ", depth - 1)
    |> IO.write()
  end
end
