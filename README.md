# Freddie: Elixir Socket Framework

## 1. Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `freddie` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:freddie, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/freddie](https://hexdocs.pm/freddie).

## 2. Features
1. Nonblocking Socket IO
2. Selectable TLS
3. Fault Tolerance
4. Support for Reliable UDP(최신 순서 보장 mode, 순서보장-재전송 보장)
5. Shipping Google Proto Buffers