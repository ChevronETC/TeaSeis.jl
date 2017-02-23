immutable TracePropertyDef{T}
    label::String
    description::String
    format::Type{T}
    elementcount::Int32
end
function TracePropertyDef{T<:Number}(label::String, description::String, format::Type{T}, elementcount::Int)
    _format = format
    if format == UInt8
        _format = Array{UInt8,1}
    elseif elementcount > 1
        _format = Array{format,1}
    end
    TracePropertyDef(label, description, _format, Int32(elementcount))
end
function TracePropertyDef(label::AbstractString)
    for propdef in stockprop
        if propdef[2].label == label
            return propdef[2]
        end
    end
    return TracePropertyDef(label, "", Int32, 1)
end
TracePropertyDef{T<:Number}(label::AbstractString, description::AbstractString, format::Type{T}, elementcount::Int) = TracePropertyDef(String(label), String(description), format, elementcount)

type TraceProperty{T}
    def::TracePropertyDef{T}
    byteoffset::Int32
end
TraceProperty{T}(def::TracePropertyDef{T}, byteoffset::Int64) = TraceProperty(def, Int32(byteoffset))

function TraceProperty(label::String, description::String, format::String, elementcount::Int32, byteoffset::Int32)
    _format = Void
    if format == "INTEGER"
        _format = elementcount == 1 ? Int32 : Array{Int32,1}
    elseif format == "LONG"
        _format = elementcount == 1 ? Int64 : Array{Int64,1}
    elseif format == "FLOAT"
        _format = elementcount == 1 ? Float32 : Array{Float32,1}
    elseif format == "DOUBLE"
        _format = elementcount == 1 ? Float64 : Array{Float64,1}
    elseif format == "BYTESTRING"
        _format = Array{UInt8,1}
    else
        error("unrecognized format: $(format)")
    end
    TraceProperty(TracePropertyDef(label, description, _format, elementcount), byteoffset)
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
in(item::TracePropertyDef, col::Array{TraceProperty,1}) = in(item.label, propdef(col))
in(item::TraceProperty, col::Array{TraceProperty,1}) = in(item.def.label, propdef(col))
in(item::String, col::Array{TraceProperty,1}) = in(item, propdef(col))

function proplabel(props::Array{TracePropertyDef,1})
    n = length(props)
    labels = Array(String, n)
    for i = 1:n
        labels[i] = props[i].label
    end
    return labels
end

sizeof{T<:Number}(propdef::TracePropertyDef{T}) = sizeof(T)*propdef.elementcount
sizeof{T<:Array}(propdef::TracePropertyDef{T}) = sizeof(eltype(T))*propdef.elementcount
sizeof(prop::TraceProperty) = sizeof(prop.def)

propdef(prop::TraceProperty) = prop.def
propdef(prop::Array{TraceProperty,1}) = [propdef(prop[i]) for i=1:length(prop)]

label(propdef::TracePropertyDef) = propdef.label
description(propdef::TracePropertyDef) = propdef.description
format(propdef::TracePropertyDef) = propdef.format
elementcount(propdef::TracePropertyDef) = propdef.elementcount
