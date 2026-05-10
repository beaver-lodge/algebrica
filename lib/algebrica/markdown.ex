defmodule Algebrica.Markdown do
  @behaviour ExDoc.Markdown

  @moduledoc false

  @bare_display_envs ~w(align align* aligned array pmatrix cases vmatrix)

  @impl true
  def available? do
    ExDoc.Markdown.Earmark.available?()
  end

  @impl true
  def to_ast(text, opts) do
    text
    |> protect_math()
    |> ExDoc.Markdown.Earmark.to_ast(opts)
  end

  defp protect_math(text) do
    text
    |> protect_block_math()
    |> protect_inline_math()
  end

  defp protect_block_math(text) do
    text
    |> String.split("\n", trim: false)
    |> protect_block_math_lines([])
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp protect_block_math_lines([], acc), do: acc

  defp protect_block_math_lines([line | rest] = lines, acc) do
    trimmed = String.trim(line)

    cond do
      String.starts_with?(String.trim_leading(line), "\\\\[") ->
        {content, rest} = collect_display_math(lines)
        protect_block_math_lines(rest, [math_element("div", "math-display", content) | acc])

      env = bare_display_env(trimmed) ->
        {content, rest} = collect_bare_display_env(lines, env)
        protect_block_math_lines(rest, [math_element("div", "math-display", content) | acc])

      true ->
        protect_block_math_lines(rest, [line | acc])
    end
  end

  defp collect_display_math([line | rest]) do
    line = line |> drop_through("\\\\[")
    collect_until_marker([line | rest], "\\\\]", [])
  end

  defp collect_bare_display_env(lines, env) do
    collect_until_env_end(tl(lines), env, [hd(lines)])
  end

  defp collect_until_marker([], _marker, acc), do: {Enum.reverse(acc) |> Enum.join("\n"), []}

  defp collect_until_marker([line | rest], marker, acc) do
    case split_once(line, marker) do
      {before, after_marker} ->
        content = Enum.reverse([before | acc]) |> Enum.join("\n")
        rest = if after_marker == "", do: rest, else: [after_marker | rest]
        {content, rest}

      nil ->
        collect_until_marker(rest, marker, [line | acc])
    end
  end

  defp collect_until_env_end([], _env, acc), do: {Enum.reverse(acc) |> Enum.join("\n"), []}

  defp collect_until_env_end([line | rest], env, acc) do
    marker = "\\end{#{env}}"

    case split_once(line, marker) do
      {before, after_marker} ->
        content = Enum.reverse([before <> marker | acc]) |> Enum.join("\n")
        rest = if after_marker == "", do: rest, else: [after_marker | rest]
        {content, rest}

      nil ->
        collect_until_env_end(rest, env, [line | acc])
    end
  end

  defp bare_display_env(line) do
    case Regex.run(~r/^\\begin\{([^}]+)\}/, line) do
      [_whole, env] when env in @bare_display_envs -> env
      _ -> nil
    end
  end

  defp drop_through(line, marker) do
    case split_once(line, marker) do
      {_before, after_marker} -> after_marker
      nil -> line
    end
  end

  defp split_once(line, marker) do
    case :binary.match(line, marker) do
      {index, length} ->
        before = binary_part(line, 0, index)
        after_marker = binary_part(line, index + length, byte_size(line) - index - length)
        {before, after_marker}

      :nomatch ->
        nil
    end
  end

  defp protect_inline_math(text) do
    Regex.replace(~r/\\\\\(([^\n]+?)\\\\\)/, text, fn _whole, content ->
      inline_math(content)
    end)
  end

  defp math_element("div", class, content) do
    content =
      content
      |> normalize_tex_source()
      |> String.trim()
      |> html_escape()

    "\n<div class=\"#{class}\" data-math-source=\"algebrica\">\n#{content}\n</div>\n"
  end

  defp inline_math(content) do
    content =
      content
      |> normalize_tex_source()
      |> String.trim()

    "$#{content}$"
  end

  defp normalize_tex_source(content) do
    content
    |> String.replace("\\\\\\[", "\\\\[")
    |> String.replace("\\\\{", "\\{")
    |> String.replace("\\\\}", "\\}")
    |> String.replace("\\\\;", "\\;")
    |> String.replace("\\\\,", "\\,")
    |> String.replace("\\(", "(")
    |> String.replace("\\)", ")")
    |> String.replace("\\_", "_")
    |> String.replace("\\=", "=")
    |> String.replace("\\+", "+")
    |> String.replace("\\-", "-")
    |> String.replace("\\'", "'")
    |> then(fn content ->
      Regex.replace(~r/\\\\([A-Za-z]+)/, content, fn _whole, command ->
        "\\#{command}"
      end)
    end)
  end

  defp html_escape(content) do
    content
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
