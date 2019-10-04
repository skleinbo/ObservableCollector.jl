using Documenter, DocumenterMarkdown, ObservableCollector

makedocs(sitename="ObservableCollector.jl",
    modules=[ObservableCollector],
    format = Markdown(),
    pages = [
        "Overview" => "index.md",
    ],
    clean=true)

deploydocs(
    repo   = "github.com/skleinbo/ObservableCollector.jl.git",
    deps   = Deps.pip("mkdocs", "pygments", "python-markdown-math"),
    make   = () -> run(`mkdocs build`),
    target = "site"
)
