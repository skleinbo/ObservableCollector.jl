using Documenter, DocumenterMarkdown, ObservableCollector

makedocs(sitename="ObservableCollector.jl",
    modules=[ObservableCollector],
    format = Markdown(),
    pages = [
        "Overview" => "index.md",
    ],
    clean=true)

if !haskey(ENV, "TRAVIS") || ENV["TRAVIS"]==false
    run(`mkdocs build`)
end

deploydocs(
    repo   = "github.com/skleinbo/ObservableCollector.jl.git",
    deps   = Deps.pip("mkdocs", "pygments", "python-markdown-math"),
    make   = () -> run(`mkdocs build`),
    target = "site"
)
