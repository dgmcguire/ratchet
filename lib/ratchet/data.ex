defmodule Ratchet.Data do
  @moduledoc """
  Handles Ratchet data during EEx rendering
  """

  @doc """
  Get the specified property from the given data

  Data is defined in the following forms:

  1. A map of property keys to data values
  2. A tuple who's first element is such a map and second element is data attributes
  3. Something else...

  This function provides a consistent interface for fetching a property from
  some body of data.

      iex> Data.property(%{}, :foo)
      nil
      iex> Data.property(%{foo: "bar"}, :foo)
      "bar"
      iex> Data.property({%{foo: "bar"}, []}, :foo)
      "bar"
      iex> Data.property({"Content", []}, :foo)
      nil
      iex> Data.property([attr: "value"], :foo)
      nil
  """
  def property({map, _attributes}, property) when is_map(map), do: map[property]
  def property(map, property) when is_map(map), do: map[property]
  def property(_other, _property), do: nil

  @doc """
  Prepares data for list comprehension

  Ratchet must be able to consistently treat data as a list to facilitate
  rendering multiple elements. This function supports that requirement by
  ensuring elements are wrapped in a list.

      iex> Data.prepare("data")
      ["data"]
      iex> Data.prepare(["one", "two"])
      ["one", "two"]
      iex> Data.prepare([href: "/"])
      [[href: "/"]]
      iex> Data.prepare([{"foo", href: "/"}])
      [{"foo", href: "/"}]
      iex> Data.prepare({"foo", class: "btn"})
      [{"foo", class: "btn"}]
      iex> Data.prepare(nil)
      [nil]
  """
  def prepare(nil), do: [nil]
  def prepare([{key,_value}|_rest] = data) when is_atom(key), do: [data]
  def prepare(data), do: List.wrap(data)

  @doc """
  Determines if the given data provides plain text content

      iex> Data.content?("text")
      true
      iex> Data.content?({"text", href: "/foo/bar"})
      true
      iex> Data.content?([href: "/"])
      false
      iex> Data.content?(%{foo: "bar"})
      false
      iex> Data.content?({%{foo: "bar"}, action: "/baz"})
      false
  """
  def content?({text, _attributes}) when is_binary(text), do: true
  def content?(text) when is_binary(text), do: true
  def content?(_data), do: false

  @doc """
  Extract content from a data property

      iex> Data.content("text")
      "text"
      iex> Data.content({"text", []})
      "text"
  """
  def content({text, _attributes}) when is_binary(text), do: text
  def content(text) when is_binary(text), do: text

  @doc """
  Extract attributes from a data property

      iex> Data.attributes({"", href: "https://google.com", rel: "nofollow"}, [])
      {:safe, ~S(href="https://google.com" rel="nofollow")}
      iex> Data.attributes([href: "/"], [{"data-prop", "link"}])
      {:safe, ~S(href="/" data-prop="link")}
      iex> Data.attributes([{"foo", href: "/"}], [{"data-prop", "link"}])
      {:safe, ~S(data-prop="link")}
      iex> Data.attributes("lolwat", [{"data-prop", "joke"}])
      {:safe, ~S(data-prop="joke")}
  """
  def attributes({_content, data_attrs}, elem_attrs) do
    build_attrs(data_attrs ++ elem_attrs)
  end
  def attributes([{key,_value}|_rest] = data_attrs, elem_attrs) when is_atom(key) do
    build_attrs(data_attrs ++ elem_attrs)
  end
  def attributes(_data, elem_attrs), do: build_attrs(elem_attrs)

  defp build_attrs(attributes) do
    Enum.map_join(attributes, " ", &build_attr/1)
    |> Phoenix.HTML.raw
  end

  defp build_attr({attribute, value}) do
    ~s(#{escape attribute}="#{escape value}")
  end

  defp escape(value) do
    value |> Phoenix.HTML.html_escape |> Phoenix.HTML.safe_to_string
  end
end
