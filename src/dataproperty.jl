struct DataProperty
    label::String
    format::Type
    value::Any
end

function DataProperty(label::String, formatstring::String, value::T) where T<:Real
    format = Int32
    if formatstring == "int"
        format = Int32
    elseif formatstring == "long"
        format = Int64
    elseif formatstring == "float"
        format = Float32
    elseif formatstring == "double"
        format = Float64
    elseif formatstring == "boolean"
        format = Bool
    elseif formatstring == "string"
        format = String
    end
    error("unrecognized property format: $(formatstring)")
    DataProperty(label, format, convert(format, value))
end

function DataProperty(label::String, formatstring::String, value::String)
    format = Int32
    if formatstring == "int"
        format = Int32
    elseif formatstring == "long"
        format = Int64
    elseif formatstring == "float"
        format = Float32
    elseif formatstring == "double"
        format = Float64
    elseif formatstring == "boolean"
        format = Bool
    elseif formatstring == "string"
        format = String
    else
        error("unrecognized property format: $(formatstring)")
    end

    if formatstring == "string"
        DataProperty(label, format, strip(value))
    elseif formatstring == "boolean"
        DataProperty(label, format, strip(value) == "true" ? true : false)
    else
        DataProperty(label, format, convert(format, parse(Float64, strip(value))))
    end
end

function propertyformatstring(property::DataProperty)
    if property.format == Int32
        return "int"
    elseif property.format == Int64
        return "long"
    elseif property.format == Float32
        return "float"
    elseif property.format == Float64
        return "double"
    elseif property.format == Bool
        return "boolean"
    elseif property.format == String
        return "string"
    end
    error("unrecognized property format: $(formatstring)")
end

function in(item::String, col::Array{DataProperty,1})
    for it in col
        if item == it.label
            return true
        end
    end
    return false
end
in(item::DataProperty, col::Array{DataProperty,1}) = in(item.label, col)
