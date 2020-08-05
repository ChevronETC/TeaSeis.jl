using Documenter, TeaSeis

makedocs(
    sitename="TeaSeis",
    modules=[TeaSeis],
    pages = [
        "index.md",
        "manual.md",
        "reference.md",
        "STOCKPROPS.md",
        "SSPROPS.md"]
)

deploydocs(
    repo = "github.com/ChevronETC/TeaSeis.jl.git"
)
