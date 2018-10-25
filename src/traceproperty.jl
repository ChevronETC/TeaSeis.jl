struct TracePropertyDef{T}
    label::String
    description::String
    format::Type{T}
    elementcount::Int32
end

function TracePropertyDef(label::AbstractString, description::AbstractString, _T::Type{T}, elementcount::Integer=one(Int32)) where {T}
    TracePropertyDef{T}(String(label), String(description), T, Int32(elementcount))
end
function TracePropertyDef(label::AbstractString)
    for propdef in stockprop
        if propdef[2].label == label
            return propdef[2]
        end
    end
    return TracePropertyDef(label, "", Int32, 1)
end

mutable struct TraceProperty{T}
    def::TracePropertyDef{T}
    byteoffset::Int32
end
TraceProperty(def::TracePropertyDef{T}, byteoffset::Int64) where {T} = TraceProperty(def, Int32(byteoffset))

function stringtype2type(format::AbstractString, count::Integer)
    count > 1 && return Vector{stringtype2type(format)}
    return stringtype2type(format)
end
function stringtype2type(format::AbstractString)
    format == "INTEGER" && return Int32
    format == "LONG" && return Int64
    format == "FLOAT" && return Float32
    format == "DOUBLE" && return Float64
    format == "BYTESTRING" && return UInt8
    error("unrecognized format: $(format)")
end

propertyformatstring(propertydef::TracePropertyDef{Int32}) = "INTEGER"
propertyformatstring(propertydef::TracePropertyDef{Int64}) = "LONG"
propertyformatstring(propertydef::TracePropertyDef{Float32}) = "FLOAT"
propertyformatstring(propertydef::TracePropertyDef{Float64}) = "DOUBLE"

propertyformatstring(propertydef::TracePropertyDef{Array{Int32,1}}) = "INTEGER"
propertyformatstring(propertydef::TracePropertyDef{Array{Int64,1}}) = "LONG"
propertyformatstring(propertydef::TracePropertyDef{Array{Float32,1}}) = "FLOAT"
propertyformatstring(propertydef::TracePropertyDef{Array{Float64,1}}) = "DOUBLE"
propertyformatstring(propertydef::TracePropertyDef{Array{UInt8,1}}) = "BYTESTRING"

propertyformatstring(property::TraceProperty) = propertyformatstring(property.def)

function in(item::String, col::Array{TracePropertyDef,1})
    for it in col
        if item == it.label
            return true
        end
    end
    return false
end
in(item::TracePropertyDef, col::Array{TracePropertyDef,1}) = in(item.label, col)
in(item::TracePropertyDef, col::Array{TraceProperty,1}) = in(item.label, propdef.(col))
in(item::TraceProperty, col::Array{TraceProperty,1}) = in(item.def.label, propdef.(col))
in(item::String, col::Array{TraceProperty,1}) = in(item, propdef.(col))

in(item::Symbol, col::NamedTuple) = item ∈ keys(col)
in(item::String, col::NamedTuple) = in(Symbol(item), col)
in(item::TracePropertyDef, col::NamedTuple) = in(item.label, col)


sizeof(propdef::TracePropertyDef{T}) where {T<:Number} = sizeof(T)*propdef.elementcount
sizeof(propdef::TracePropertyDef{T}) where {T<:Array} = sizeof(eltype(T))*propdef.elementcount
sizeof(prop::TraceProperty) = sizeof(prop.def)

propdef(prop::TraceProperty) = prop.def
proplabel(prop::TracePropertyDef) = prop.label

label(propdef::TracePropertyDef) = propdef.label
description(propdef::TracePropertyDef) = propdef.description
format(propdef::TracePropertyDef) = propdef.format
elementcount(propdef::TracePropertyDef) = propdef.elementcount

==(propdef1::TracePropertyDef, propdef2::TracePropertyDef) = propdef1.label == propdef2.label && propdef1.format == propdef2.format && propdef1.elementcount == propdef2.elementcount
==(prop1::TraceProperty, prop2::TraceProperty) = prop1.def == prop2.def && prop1.byteoffset == prop2.byteoffset
