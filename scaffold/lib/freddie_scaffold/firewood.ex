defmodule FreddieScaffold.Firewood do

  @scaffold_path Path.expand("../../", __DIR__)

  @templates_dir "templates"

  defmacro __using__(_env) do
    quote do
      import FreddieScaffold.Firewood

      Module.register_attribute(__MODULE__, :template_root, accumulate: false)
      Module.register_attribute(__MODULE__, :template_list, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    target = Module.get_attribute(env.module, :template_root)

    {template_list, target_resources_ast} =
      traverse(target)
      |> Enum.reduce({[], []}, fn {identifier, file_path}, {identifier_acc, ast_acc} ->
          {
            [identifier | identifier_acc],
            [
              quote do
                @external_resource unquote(file_path)
                def get(unquote(identifier)), do: unquote(File.read!(file_path))
              end
              | ast_acc
            ]
          }
        end)

    quote do
      unquote(target_resources_ast)

      def get_template_prefix(), do: unquote(@templates_dir)

      def get_template_type(), do: unquote(target)

      def get_template_list(), do: unquote(template_list)
    end
  end

  defmacro template_root(root_path) do
    quote do
      @template_root unquote(root_path)
    end
  end

  defp add_template(template_name) do
    Macro.to_string(
      quote do
        @template_list unquote(template_name)
      end
    )
  end

  defp traverse(path) do
    root_path = Path.join([@scaffold_path, @templates_dir, path])

    case File.ls(root_path) do
      {:ok, files} ->
        files
      {:error, reason} ->
        Mix.raise("Failed to ls #{inspect root_path}!, reason: #{inspect reason}")
    end
    |> Stream.flat_map(fn file ->
      file_path = Path.join(root_path, file)

      if File.dir?(file_path) do
        traverse(Path.join(path, file))
      else
        [{Path.join(path, file), file_path}]
      end
    end)
    |> Enum.to_list()
  end

end
