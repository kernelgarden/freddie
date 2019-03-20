defmodule <%= app_mod %>.Scheme do
  use Protobuf, from: Path.wildcard(Path.expand("./scheme/**/*.proto", __DIR__))
end
