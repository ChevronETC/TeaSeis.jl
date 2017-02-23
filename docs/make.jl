using Documenter, TeaSeis

makedocs(
    modules = [TeaSeis]
)
cp("build/README.md", "../README.md", remove_destination=true)
