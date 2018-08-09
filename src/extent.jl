mutable struct Extent
    name::String
    path::String
    index::Int32
    start::Int64
    size::Int64
end

Extent() = Extent(" ", " ", -1, -1, -1)

index(ex::Extent) = ex.index
missing(ex::Extent) = ex.index < 1 ? true : false

