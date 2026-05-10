defmodule Algebrica.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/beaver-lodge/algebrica"
  @homepage_url "https://algebrica.org"

  @content_groups [
    {"Sets and Numbers", "sets-and-numbers"},
    {"Powers, Radicals, and Logarithms", "powers-radicals-logarithms"},
    {"Equations", "equations"},
    {"Polynomials", "polynomials"},
    {"Complex Numbers", "complex-numbers"},
    {"Trigonometry", "trigonometry"},
    {"Vectors and Matrices", "vectors-and-matrices"},
    {"Linear Systems", "linear-systems"},
    {"Integrals", "integrals"},
    {"Limits", "limits"},
    {"Algebraic Structures", "algebraic-structures"}
  ]

  def project do
    [
      app: :algebrica,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      name: "Algebrica",
      description: description(),
      homepage_url: @homepage_url,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "A Mix/ExDoc wrapper for the Algebrica mathematics knowledge base."
  end

  defp package do
    [
      name: "algebrica",
      licenses: ["CC-BY-NC-4.0"],
      links: %{
        "GitHub" => @source_url,
        "Website" => @homepage_url
      },
      files: ~w(.formatter.exs lib mix.exs README.md LICENSE.md) ++ content_dirs(),
      exclude_patterns: ["**/.DS_Store", "**/.obsidian/**"]
    ]
  end

  defp docs do
    [
      main: "algebrica-readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      markdown_processor: Algebrica.Markdown,
      before_closing_head_tag: &before_closing_head_tag/1,
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp extras do
    [
      project_extras(),
      content_extras()
    ]
    |> List.flatten()
    |> existing_extras()
    |> Enum.map(&extra_entry/1)
  end

  defp groups_for_extras do
    project_group = {"Project", existing_extras(project_extras())}

    content_groups =
      Enum.map(@content_groups, fn {group, dir} ->
        {group, existing_extras(markdown_files(dir))}
      end)

    [project_group | content_groups]
    |> Enum.reject(fn {_group, entries} -> entries == [] end)
  end

  defp project_extras do
    [
      "README.md",
      "LICENSE.md"
    ]
  end

  defp content_extras do
    @content_groups
    |> Enum.flat_map(fn {_group, dir} -> markdown_files(dir) end)
    |> Enum.uniq()
  end

  defp content_dirs do
    Enum.map(@content_groups, fn {_group, dir} -> dir end)
  end

  defp markdown_files(dir) do
    dir
    |> Path.join("*.md")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp existing_extras(entries) do
    Enum.filter(entries, &File.exists?/1)
  end

  defp extra_entry("README.md") do
    {"README.md", [filename: "algebrica-readme", title: "Algebrica"]}
  end

  defp extra_entry("LICENSE.md") do
    {"LICENSE.md", [filename: "license", title: "License"]}
  end

  defp extra_entry(path), do: path

  defp before_closing_head_tag(:html) do
    ~S"""
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/katex.min.css">
    <style>
      .katex-display {
        overflow-x: auto;
        overflow-y: hidden;
        padding: 0.15rem 0;
      }
    </style>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/katex.min.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/contrib/auto-render.min.js"></script>
    """
  end

  defp before_closing_head_tag(:epub), do: ""

  defp before_closing_body_tag(:html) do
    ~S"""
    <script>
      (() => {
        const ignoredTextSelector = "script, noscript, style, textarea, pre, code";

        function normalizeMathText(text) {
          return text
            .replace(/\\\\\(/g, "\\(")
            .replace(/\\\\\)/g, "\\)")
            .replace(/\\\\\[/g, "\\[")
            .replace(/\\\\\]/g, "\\]")
            .replace(/\\begin\{align\*?\}/g, "\\begin{aligned}")
            .replace(/\\end\{align\*?\}/g, "\\end{aligned}");
        }

        function normalizeTex(text) {
          let normalized = text.trim();
          const replacements = [
            ["\\\\\\[", "\\\\["],
            ["\\\\{", "\\{"],
            ["\\\\}", "\\}"],
            ["\\\\;", "\\;"],
            ["\\\\,", "\\,"],
            ["\\(", "("],
            ["\\)", ")"],
            ["\\_", "_"],
            ["\\=", "="],
            ["\\+", "+"],
            ["\\-", "-"],
            ["\\'", "'"]
          ];

          for (const [from, to] of replacements) {
            normalized = normalized.split(from).join(to);
          }

          normalized = normalized.replace(/\\\\([A-Za-z]+)/g, (_whole, command) => `\\${command}`);

          return normalized
            .replace(/\\begin\{align\*?\}/g, "\\begin{aligned}")
            .replace(/\\end\{align\*?\}/g, "\\end{aligned}");
        }

        function renderExplicitMath(root) {
          if (typeof katex === "undefined") {
            return false;
          }

          for (const mathEl of root.querySelectorAll(".math-display, .math-inline")) {
            if (mathEl.dataset.mathRendered === "true") {
              continue;
            }

            const displayMode = mathEl.classList.contains("math-display");
            const tex = normalizeTex(mathEl.textContent || "");
            katex.render(tex, mathEl, {
              displayMode,
              throwOnError: false,
              strict: "ignore"
            });
            mathEl.dataset.mathRendered = "true";
          }

          return true;
        }

        function isLikelyMathCode(text) {
          const trimmed = normalizeMathText(text).trim();
          const isDelimitedMath =
            /^\\$\\$[\s\S]+\\$\\$$/.test(trimmed) ||
            /^\\$[^$][\s\S]*\\$$/.test(trimmed) ||
            /^\\\([\s\S]+\\\)$/.test(trimmed) ||
            /^\\\[[\s\S]+\\\]$/.test(trimmed);

          if (!isDelimitedMath) {
            return false;
          }

          return /\\[a-zA-Z]+/.test(trimmed) || /[\^_{}=]/.test(trimmed);
        }

        function unwrapInlineMathCode(root) {
          for (const codeEl of root.querySelectorAll("code")) {
            if (codeEl.closest("pre")) {
              continue;
            }

            const text = codeEl.textContent || "";

            if (!isLikelyMathCode(text)) {
              continue;
            }

            codeEl.replaceWith(document.createTextNode(normalizeMathText(text)));
          }
        }

        function normalizeMathTextNodes(root) {
          const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
          const nodes = [];
          let node;

          while ((node = walker.nextNode())) {
            if (node.parentElement?.closest(ignoredTextSelector)) {
              continue;
            }

            const normalized = normalizeMathText(node.nodeValue || "");

            if (normalized !== node.nodeValue) {
              nodes.push([node, normalized]);
            }
          }

          for (const [textNode, normalized] of nodes) {
            textNode.nodeValue = normalized;
          }
        }

        function renderMath() {
          if (typeof renderMathInElement !== "function" || typeof katex === "undefined") {
            return false;
          }

          renderExplicitMath(document.body);
          unwrapInlineMathCode(document.body);
          normalizeMathTextNodes(document.body);

          renderMathInElement(document.body, {
            delimiters: [
              {left: "$$", right: "$$", display: true},
              {left: "$", right: "$", display: false},
              {left: "\\(", right: "\\)", display: false},
              {left: "\\[", right: "\\]", display: true}
            ],
            ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"],
            preProcess: normalizeTex,
            throwOnError: false,
            strict: "ignore"
          });

          return true;
        }

        function renderMathWhenReady(attempt = 0) {
          if (renderMath() || attempt > 60) {
            return;
          }

          window.setTimeout(() => renderMathWhenReady(attempt + 1), 50);
        }

        window.addEventListener("exdoc:loaded", () => renderMathWhenReady());
      })();
    </script>
    """
  end

  defp before_closing_body_tag(:epub), do: ""

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end
end
