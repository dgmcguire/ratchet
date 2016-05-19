defmodule Ratchet.Renderer do
  import Ratchet.Transformer, only: [transform: 1]

  @doc """
  Render template to markup given data
  """
  def render(template, data) do
    template
    |> parse
    |> transform
    |> compile
    |> eval(data)
  end

  @doc """
  Parse template to AST
  """
  def parse(template) do
    Floki.parse(template)
  end

  @doc """
  Compile markup from AST
  """
  def compile(ast) do
    Floki.raw_html(ast)
  end

  defp eval(template, data) do
    EEx.eval_string(template, data: data)
  end
end
