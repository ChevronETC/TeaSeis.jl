mutable struct JSeis{T<:NamedTuple,U<:NamedTuple,C<:Union{TraceCompressor{Float32}, TraceCompressor{Int16}}}
    filename::String
    mode::String
    description::String
    mapped::Bool
    datatype::String
    dataformat::DataType
    dataorder::String
    properties::T
    axis_lengths::Array{Int,1}
    axis_propdefs::U
    axis_units::Array{String,1}
    axis_domains::Array{String,1}
    axis_lstarts::Array{Int,1}
    axis_lincs::Array{Int,1}
    axis_pstarts::Array{Float64,1}
    axis_pincs::Array{Float64,1}
    dataproperties::Array{DataProperty,1}
    geom::Union{Geometry,Nothing}
    hastraces::Bool
    secondaries::Array{String, 1}
    trcextents::Array{Extent,1}
    hdrextents::Array{Extent,1}
    currentvolume::Int
    map::Array{Int32,1}
    hdrlength::Int
    compressor::C

    function JSeis(properties::T, axis_propdefs::U, compressor::C) where {T,U,C}
        io=new{T,U,C}()
        io.properties=properties
        io.axis_propdefs=axis_propdefs
        io.compressor = compressor
        io
    end
end

# open/close
"""
    jsopen(filename, mode, [parameters])

Open a new or existing JavaSeis dataset with name `filename::String` and in `mode::String`.
`mode` can be one of `"r"` (read), `"w"` (write/create) or `"r+"` (read and write).
It is convention for filename to havea ".js" extention.

If `"w"` is used for the value of `mode`, then the `axis_lengths` named parameter is required, and several optional
named function parameters are available:

# parameters
* `similarto::String` An existing JavaSeis dataset.  If set, then all other named arguments can be used to modify the data context that belongs to the existing JavaSeis dataset.
* `description::String` Description of dataset, if not set, then a description is parsed from the filename.
* `mapped::Bool` If the dataset is full (no missing frames/traces), then it may be more efficient to set this to `false`.  Defaults to `true`.
* `datatype::String` Examples are `CMP`, `SHOT`, etc.  If not set, then `UNKNOWN` is used.
* `dataformat::Type` Choose from `Float32`, and `Int16`.  If not set, then `Float32` is used.
* `dataorder::String` (not supported)
* `axis_lengths::Array{Int}` size of each dimension (sample/trace/frame/volume/hypercube) of the JavaSeis data context
* `axis_propdefs::Array{TracePropertyDef}` Trace properties corresponding to JavaSeis axes.  If not set, then `SAMPLE`, `TRACE`, `FRAME`, `VOLUME` and `HYPRCUBE` are used.
* `axis_units::Array{String}` Units corresponding to JavaSeis axes. e.g. `SECONDS`, `METERS`, etc.  If not set, then `UNKNOWN` is used.
* `axis_domains::Array{String}` Domains corresponding to JavaSeis axes. e.g. `SPACE`, `TIME`, etc.  If not set, then `UNKNOWN` is used.
* `axis_lstarts::Array{Int}` Logical origins for each axis.  If not set, then `1` is used for the logical origin of each axis.
* `axis_lincs::Array{Int}` Logical increments for each axis.  If not set, then `1` is used for the logical increments of each axis.
* `axis_pstarts::Array{Float64}` Physical origins for each axis.  If not set, then `0.0` is used for the physical origin of each axis.
* `axis_pincs::Array{Float64}` Physical increments for each axis.  If not set, then `1.0` is used for the physical increments of each axis.
* `data_properties::Array{DataProperty}` An array of custom trace properties.  These are in addition to the properties listed in `SSPROPS.md`.
* `properties::Array{TracePropertyDef}` An array of custom data properties.  One property per data-set rather than one property per trace as in `properties` above.
* `geometry::Geometry` An optional three point geometry can be embedded in the JavaSeis file.
* `secondaries::Array{String}` An array of file-system locations used to store the file extents.  If not set, then *primary* storage is used.
* `nextents::Int64` The number of file-extents used to store the data.  If not set, then a heuristic is used to choose the number of extents.  The heuristic is: min(256,10 + (FRAMEWORK_SIZE)/(2*1024^3)).
* `properties_add::Array{TracePropertyDef}` When `similarto` is specified, use this to add trace properties to those already existing in the `similarto` file.
* `properties_rm::Array{TracePropertyDef}` When `similarto` is specified, use this to remove trace properties to those already existing in the `similarto` file.
* `dataproperties_add::Array{DataProperty}` When `similarto` is specfied, use this to add dataset properties to those aloready existing in the `similarto` file.
* `dataproperties_rm::Array{DataProperty}` When `similarto` is specified, use this to remove dataset properties to those already existing in the `similarto` file.
"""
function jsopen(
        filename::String, mode::String;
        description        = "",                                # JavaSeis file description
        mapped             = nothing,                           # ismapped, must be true for irregular (sparse) data
        datatype           = nothing,                           # datatype, stockdatatype[:CUSTOM], stockdatatype[:SOURCE], etc.
        dataformat         = nothing,                           # format stored on disk, Float32 or Float16
        dataorder          = "",                                # big ("BIG_ENDIAN") or little ("LITTLE_ENDIAN") endian stored on disk
        axis_lengths       = Array{Int}(undef, 0),              # length (number of bins) along each axis
        axis_propdefs      = Array{TracePropertyDef}(undef, 0), # axis properties (use for bin header word along each dimension)
        axis_units         = Array{String}(undef, 0),           # axis units (stockunit[:SECONDS], stockunit[:METERS], stockunit[:UNKNOWN] etc.)
        axis_domains       = Array{String}(undef, 0),           # axis domains (stockdomain[:SPACE], stockdomain[:TIME], stockdomain[:UNKNOWN], etc.)
        axis_lstarts       = Array{Int}(undef, 0),              # logical start index for each axis
        axis_lincs         = Array{Int}(undef, 0),              # logical increment between bins for each axis
        axis_pstarts       = Array{Float64}(undef, 0),          # physical start for each axis
        axis_pincs         = Array{Float64}(undef, 0),          # physical increment between bins for each axis
        dataproperties     = Array{DataProperty}(undef, 0),     # add global data properties
        properties         = Array{TracePropertyDef}(undef, 0), # add headers to the standard set
        geometry           = nothing,                           # 3 point geometry
        secondaries        = nothing,                           # secondary file-system locations for storing trace and header data, defaults to primary storage "."
        nextents           = 0,                                 # number of file extents
        similarto          = "",                                # create a JavaSeis file similar to this one
        properties_add     = Array{TracePropertyDef}(undef, 0), # only used in conjunction with similarto, dis-allowed if properties is set
        properties_rm      = Array{TracePropertyDef}(undef, 0), # only used in conjunction with similarto, dis-allowed if properties is set
        dataproperties_add = Array{DataProperty}(undef, 0),     # only used in conjunction with similarto, dis-allowed if dataproperties is set
        dataproperties_rm  = Array{DataProperty}(undef, 0))     # only used in conjunction with similarto, dis-allowed if dataproperties is set
    local traceproperties, _axis_propdefs, _axis_lengths, _dataformat, xml_fileproperties
    if mode == "r" || mode == "r+"
        xml_fileproperties = parse_file(joinpath(filename, "FileProperties.xml"))
        traceproperties = get_trace_properties(xml_fileproperties)
        _axis_propdefs = get_axis_propdefs(traceproperties, xml_fileproperties)
        _axis_lengths = get_axis_lengths(xml_fileproperties)
        _dataformat = get_dataformat(xml_fileproperties)
    elseif mode == "w" && similarto == ""
        traceproperties, _axis_propdefs = get_trace_properties(length(axis_lengths), properties, properties_add, properties_rm, axis_propdefs, similarto)
        _axis_lengths = axis_lengths
        _dataformat = dataformat == nothing ? Float32 : dataformat
    elseif mode == "w" && similarto != ""
        traceproperties, _axis_propdefs = get_trace_properties(length(axis_lengths), properties, properties_add, properties_rm, axis_propdefs, similarto)
        iosim = jsopen(similarto)
        _axis_lengths = length(axis_lengths) == 0 ? [size(iosim)...] : axis_lengths
        _dataformat = dataformat == nothing ? iosim.dataformat : dataformat
    end

    compressor = TraceCompressor(_axis_lengths[1], _dataformat)
    io = JSeis(traceproperties, _axis_propdefs, compressor)
    io.filename = filename
    io.mode = mode
    io.currentvolume = -1
    io.hdrlength = headerlength(io.properties)

    if mode == "r" || mode == "r+"
        io2 = open(joinpath(filename, "Name.properties"), "r")
        io.description = get_description(io2)
        close(io2)

        io.mapped         = get_mapped(xml_fileproperties)
        io.datatype       = get_datatype(xml_fileproperties)
        io.dataformat     = _dataformat
        io.dataorder      = get_dataorder(xml_fileproperties)
        io.axis_lengths   = _axis_lengths
        io.axis_units     = get_axis_units(xml_fileproperties)
        io.axis_domains   = get_axis_domains(xml_fileproperties)
        io.axis_lstarts   = get_axis_lstarts(xml_fileproperties)
        io.axis_lincs     = get_axis_lincs(xml_fileproperties)
        io.axis_pstarts   = get_axis_pstarts(xml_fileproperties)
        io.axis_pincs     = get_axis_pincs(xml_fileproperties)
        io.dataproperties = get_dataproperties(xml_fileproperties)
        io.geom           = nothing

        io.hastraces = false
        if isfile(joinpath(filename, "Status.properties")) == true # Do not fail if Status.properties does not exist to maintain backwards compat
            io2 = open(joinpath(filename, "Status.properties"))
            io.hastraces = get_status(io2)
            close(io2)
        end

        xml = parse_file(joinpath(filename, "VirtualFolders.xml"))
        io.secondaries = get_secondaries(xml)

        xml = parse_file(joinpath(filename, "TraceFile.xml"))
        io.trcextents = get_extents(xml, io.secondaries, io.filename)

        xml = parse_file(joinpath(filename, "TraceHeaders.xml"))
        io.hdrextents = get_extents(xml, io.secondaries, io.filename)

        io.currentvolume = -1
        io.map = zeros(Int32, io.axis_lengths[3])

        return io
    end

    if mode == "w" && isdir(filename) == true
        teaseis_robust_rm(filename)
    end

    if mode == "w" && similarto == ""
        io.mapped         = mapped == nothing ? true : mapped
        io.datatype       = datatype == nothing ? stockdatatype[:CUSTOM] : datatype
        io.dataformat     = _dataformat
        io.dataorder      = dataorder == "" ? "LITTLE_ENDIAN" : dataorder
        io.axis_lengths   = axis_lengths
        io.axis_units     = axis_units
        io.axis_domains   = axis_domains
        io.axis_lstarts   = axis_lstarts
        io.axis_lincs     = axis_lincs
        io.axis_pstarts   = axis_pstarts
        io.axis_pincs     = axis_pincs
        io.dataproperties = dataproperties
        io.geom           = geometry == nothing ? nothing : geometry
        io.secondaries    = secondaries == nothing ? ["."] : secondaries
    elseif mode == "w" && similarto != ""
        iosim = jsopen(similarto)

        # special handling for data properties
        if length(dataproperties) == 0
            dataproperties = copy(iosim.dataproperties)
        else
            @assert length(dataproperties_add) == 0
            @assert length(dataproperties_rm) == 0
        end

        if length(dataproperties_add) != 0
            @assert length(dataproperties) == 0
            for prop in dataproperties_add
                if in(prop, dataproperties) == false
                    push!(dataproperties, prop)
                end
            end
        end

        io.mapped         = mapped == nothing ? iosim.mapped : mapped
        io.datatype       = datatype == nothing ? iosim.datatype : datatype
        io.dataformat     = _dataformat
        io.dataorder      = dataorder == "" ? iosim.dataorder : dataorder
        io.axis_lengths   = _axis_lengths
        io.axis_units     = length(axis_units) == 0 ? copy(iosim.axis_units) : axis_units
        io.axis_domains   = length(axis_domains) == 0 ? copy(iosim.axis_domains) : axis_domains
        io.axis_lstarts   = length(axis_lstarts) == 0 ? copy(iosim.axis_lstarts) : axis_lstarts
        io.axis_lincs     = length(axis_lincs) == 0 ? copy(iosim.axis_lincs) : axis_lincs
        io.axis_pstarts   = length(axis_pstarts) == 0 ? copy(iosim.axis_pstarts) : axis_pstarts
        io.axis_pincs     = length(axis_pincs) == 0 ? copy(iosim.axis_pincs) : axis_pincs
        io.dataproperties = dataproperties
        io.geom           = geometry == nothing ? iosim.geom : geometry
        io.secondaries    = secondaries == nothing ? copy(iosim.secondaries) : secondaries
        nextents          = nextents == 0 ? length(iosim.trcextents) : nextents
    end

    if mode == "w"
        ndim = length(io.axis_lengths)
        @assert ndim >= 3
        @assert length(io.axis_propdefs) == ndim || length(io.axis_propdefs) == 0
        @assert length(io.axis_units)    == ndim || length(io.axis_units)    == 0
        @assert length(io.axis_domains)  == ndim || length(io.axis_domains)  == 0
        @assert length(io.axis_lstarts)  == ndim || length(io.axis_lstarts)  == 0
        @assert length(io.axis_lincs)    == ndim || length(io.axis_lincs)    == 0
        @assert length(io.axis_pstarts)  == ndim || length(io.axis_pstarts)  == 0
        @assert length(io.axis_pincs)    == ndim || length(io.axis_pincs)    == 0

        return jsopen_write(io, nextents, ndim, description, properties, similarto == "" ? false : true)
    end
    error("mode \"$(mode)\" is not supported by jsopen.")
end

function teaseis_robust_rm(filename::AbstractString)
    try
        rm(jsopen(filename, "r"))
    catch
        rm(filename, force=true, recursive=true)
    end
end

function jsopen_write(io::JSeis, nextents::Int, ndim::Int, description::String, properties::Array, issimilar::Bool)
    # axes
    if length(io.axis_units) == 0
        io.axis_units = fill(stockunit[:UNKNOWN], ndim)
    end
    if length(io.axis_domains) == 0
        io.axis_domains = fill(stockdomain[:UNKNOWN], ndim)
    end
    if length(io.axis_lstarts) == 0
        io.axis_lstarts = ones(Int64, ndim)
    end
    if length(io.axis_lincs) == 0
        io.axis_lincs = ones(Int64, ndim)
    end
    if length(io.axis_pstarts) == 0
        io.axis_pstarts = zeros(Float64, ndim)
    end
    if length(io.axis_pincs) == 0
        io.axis_pincs = ones(Float64, ndim)
    end

    # description, if not set by user, we grab it from the filename
    if length(description) == 0
        io.description = io.filename[end-2:end] == ".js" ? io.filename[1:end-3] : io.filename
        io.description = split(io.description,['/','@'])[end]
    else
        io.description = description
    end

    # data is initialized to empty
    io.hastraces = false

    # secondaries, if not set by user, we use primary storage ["."]
    if io.secondaries == nothing
        io.secondaries = ["."]
    end
    if length(io.secondaries) < 1
        error("For primary storage use secondaries=nothing or secondaries=[\".\"], otherwise secondaries must an array of strings with length>0")
    end

    # choose default number of exents (heuristic)
    nextents = nextents == 0 ? nextents_heuristic(io.axis_lengths, io.dataformat) : nextents
    nextents = nextents > prod(io.axis_lengths[3:end]) ? prod(io.axis_lengths[3:end]) : nextents

    # trace and header extents
    io.trcextents = make_extents(nextents, io.secondaries, io.filename, io.axis_lengths, tracelength(io.compressor), "TraceFile")
    io.hdrextents = make_extents(nextents, io.secondaries, io.filename, io.axis_lengths, io.hdrlength, "TraceHeaders")

    # trace map
    io.map = zeros(Int32, io.axis_lengths[3])

    # create the various xml files and directories
    make_primarydir(io)
    make_extentdirs(io)
    create_map(io)
    write_fileproperties(io)
    write_nameproperties(io)
    write_statusproperties(io)
    write_extentmanager(io)
    write_virtualfolders(io)

    return io
end

"""
    jsopen(filename)

Equivalent to `jsopen(filename, "r")`
"""
jsopen(filename::String) = jsopen(filename, "r")

"""
    jscreate(filename)

Create a JavaSeis dataset without opening it.  This method has the same optional arguments as `jsopen`
"""
jscreate(filename::String; kwargs...) = close(jsopen(filename, "w"; kwargs...))

"""
    close(io)

Close an open JavaSeis dataset where `io` is of type `JSeis` created using, for example, `jsopen`.
"""
function close(io::JSeis)
# nothing to do... stub in-case we decide to keep state for the various file-pointers
end

"""
    rm(io)

Remove a JavaSeis dataset from disk.  For example: `rm(jsopen("deleteme.js"))`
"""
function rm(io::JSeis)
    rmsecondaries(io)
    if isdir(io.filename) == true
        rm(io.filename, recursive = true)
    end
end

"""
    empty!(io)

Empty a JavaSeis dataset from disk, retaining the meta-information.  For example: `empty!(jsopen("emptyme.js"))`
"""
function empty!(io::JSeis)
    emptysecondaries!(io)
    if isdir(io.filename) == true
        names = filter(s->(startswith(s, "TraceFile") == true || startswith(s, "TraceHeaders") == true) && endswith(s, ".xml") == false, readdir(io.filename))
        for name in names
            rm("$(io.filename)/$(name)")
        end
    end
    io.hastraces = false
    write_statusproperties(io)
end

function rmsecondaries(io::JSeis)
    for secondary in io.secondaries
        if secondary != "." && isdir(extentdir(secondary, io.filename)) == true
            rm(extentdir(secondary, io.filename), recursive = true)
        end
    end
end

function emptysecondaries!(io::JSeis)
    for secondary in io.secondaries
        if secondary != "." && isdir(extentdir(secondary, io.filename)) == true
            for name in readdir(extentdir(secondary, io.filename))
                rm("$(extentdir(secondary, io.filename))/$(name)")
            end
        end
    end
end

"""
    cp(src, dst, [secondaries=nothing])

Copy a file from `src` (of type `JSeis`) to `dst` of type `String`.  For example, `cp(jsopen("copyfrom.js"), "copyto.js")`.
Use the optional named argument `secondaries` to change the JavaSeis secondary location.
"""
function cp(src::JSeis, dst::AbstractString; secondaries=nothing)
    iodst = jsopen(dst, "w", similarto=src.filename, secondaries=secondaries)
    trcs, hdrs = allocframe(iodst)
    for i = 1:length(src)
        idx = ind2sub(src,i)
        fld = readframe!(src, trcs, hdrs, idx...)
        if fld > 0
            writeframe(iodst, trcs, hdrs)
        end
    end
end

"""
    mv(src, dst, [secondaries=nothing])

Move a file from `src` (of type `JSeis`) to `dst` of type `String`.  For example, `cp(jsopen("movefrom.js"), "moveto.js")`.
Use the optional named argument `secondaries` to change the JavaSeis secondary location.
"""
function mv(src::JSeis, dst::AbstractString; secondaries=nothing)
    cp(src, dst, secondaries=secondaries)
    rm(src)
end

function show(io::IO, js::JSeis)
    write(io, "JavaSeis file:\n");
    write(io, "\tsize: $(size(js))\n");
    write(io, "\ttype: $(js.datatype) ; format: $(asciidataformat(js.dataformat))\n");
    write(io, "\taxis domains: $(domains(js))\n");
    write(io, "\taxis units: $(units(js))\n");
    write(io, "\taxis properties: $(labels(js))");
end

# reading from the various xml files:
get_mapped(xml::XMLDocument)       = strip(content(get_file_property_element(xml, "Mapped"))) == "true" ? true : false
get_datatype(xml::XMLDocument)     = strip(content(get_file_property_element(xml, "DataType")))
get_axis_lengths(xml::XMLDocument) = [parse(Int64, s) for s in split(content(get_file_property_element(xml, "AxisLengths")))]
get_axis_units(xml::XMLDocument)   = split(content(get_file_property_element(xml, "AxisUnits")))
get_axis_domains(xml::XMLDocument) = split(content(get_file_property_element(xml, "AxisDomains")))
get_axis_lstarts(xml::XMLDocument) = [parse(Int64, s) for s in split(content(get_file_property_element(xml, "LogicalOrigins")))]
get_axis_lincs(xml::XMLDocument)   = [parse(Int64, s) for s in split(content(get_file_property_element(xml, "LogicalDeltas")))]
get_axis_pstarts(xml::XMLDocument) = [parse(Float64, s) for s in split(content(get_file_property_element(xml, "PhysicalOrigins")))]
get_axis_pincs(xml::XMLDocument)   = [parse(Float64, s) for s in split(content(get_file_property_element(xml, "PhysicalDeltas")))]
get_dataorder(xml::XMLDocument)    = strip(content(get_file_property_element(xml, "ByteOrder")))

function get_axis_propdefs(properties, xml::XMLDocument)
    labels = split(content(get_file_property_element(xml, "AxisLabels")))
    propdefs = Array{TracePropertyDef}(undef, 0)
    for (i,label) in enumerate(labels)
        push!(propdefs, get_axis_propdef(properties, label, i))
    end
    names = ntuple(i->Symbol(propdefs[i].label), length(propdefs))
    NamedTuple{names}(propdefs)
end

function get_axis_propdef(properties, label::AbstractString, dim::Int)
    # map from JavaSeis axis name to ProMax property label
    plabel = haskey(dictJStoPM, label) == true ? dictJStoPM[label] : label

    for prop in properties
        if prop.def.label == plabel
            return prop.def
        end
    end

    # The sample and trace labels do not need a corresponding trace property.
    # Therefore, these should be considered valid datasets.
    if dim == 1 || dim == 2
        return TracePropertyDef(label, label, Int32, 1)
    end
    error("Malformed JavaSeis: axis props, axis label=$(label) has no corresponding trace property.")
end

function get_dataformat(xml::XMLDocument)
    par = get_file_property_element(xml, "TraceFormat")
    format = strip(content(par))
    if format == "FLOAT"
        return Float32
    elseif format == "DOUBLE"
        return Float64
    elseif format == "COMPRESSED_INT32"
        return Int32
    elseif format == "COMPRESSED_INT16"
        return Int16
    end
    error("Unrecognized JavaSeis data format")
end

function get_trace_properties(xml::XMLDocument)
    props = Array{TraceProperty}(undef, 0)
    for parset in child_elements(root(xml))
        if attribute(parset, "name") == "TraceProperties"
            for parset2 in child_elements(parset)
                label, description, format, count, offset = "", "", "", 1, 0
                for par in child_elements(parset2)
                    if attribute(par, "name") == "label"
                        label = strip(content(par))
                    elseif attribute(par, "name") == "description"
                        description = strip(content(par), [' ', '"'])
                    elseif attribute(par, "name") == "format"
                        format = strip(content(par))
                    elseif attribute(par, "name") == "elementCount"
                        count = parse(Int32, content(par))
                    elseif attribute(par, "name") == "byteOffset"
                        offset = parse(Int32, content(par))
                    end
                end
                push!(props, TraceProperty(TracePropertyDef(label, description, stringtype2type(format, count), count), offset))
            end
            break
        end
    end
    names = ntuple(i->Symbol(props[i].def.label), length(props))
    return NamedTuple{names}(props)
end

function get_trace_properties(ndim, propertydefs, propertydefs_add, propertydefs_rm, axis_propdefs, similarto)
    local _propertydefs, _axis_propdefs
    if similarto == ""
        _propertydefs = propertydefs
        _axis_propdefs = axis_propdefs
    else
        iosim = jsopen(similarto, "r")

        # special handling for trace properties
        if length(propertydefs) == 0
            _propertydefs = propdef.(collect(iosim.properties))
        else
            @assert length(propertydefs_add) == 0
            @assert length(propertydefs_rm) == 0
        end

        if length(propertydefs_add) != 0
            for pdef in propertydefs_add
                if in(pdef, _propertydefs) == false
                    push!(_propertydefs, pdef)
                end
            end
        end

        if length(propertydefs_rm) != 0
            N = length(_propertydefs) - length(propertydefs_rm)
            propertydefs_new = Array{TracePropertyDef}(N)
            k = 1
            for i = 1:length(_propertydefs), j = 1:length(propertydefs_rm)
                if propertydefs_rm[j].lbl == _propertydefs[i].lbl
                    break
                end
                propertydefs_new[k] = _propertydefs[i]
                k += 1
            end
            _propertydefs = propertydefs_new
        end

        _axis_propdefs = length(axis_propdefs) == 0 ? collect(iosim.axis_propdefs) : axis_propdefs
    end

    # initialize trace properties to an empty array
    properties = Array{TraceProperty}(undef, 0)

    # trace properties, minimal set (as defined by SeisSpace / ProMAX)
    byteoffset = similarto == "" ? sspropset!(properties, 0) : 0

    # trace properties, user defined
    for pdef in _propertydefs
        if in(pdef, properties) == false
            push!(properties, TraceProperty(pdef, byteoffset))
            byteoffset += sizeof(pdef)
        end
    end

    # axis properties
    if length(_axis_propdefs) == 0
        _axis_propdefs = [stockprop[:SAMPLE], stockprop[:TRACE], stockprop[:FRAME], stockprop[:VOLUME], stockprop[:HYPRCUBE]][1:min(5,ndim)]
        map(idim->push!(_axis_propdefs, TracePropertyDef("DIM$(idim)", "dimension $(idim)", Int32, 1)), 6:ndim)
    end
    for (i,pdef) in enumerate(_axis_propdefs)
        @assert pdef.elementcount == 1
        # map from JavaSeis axis name to ProMax property label
        pdef = haskey(dictJStoPM, pdef.label) == true ? TracePropertyDef(dictJStoPM[pdef.label], pdef.description, pdef.format, pdef.elementcount) : pdef
        _axis_propdefs[i] = pdef
        if in(pdef, properties) == false
            push!(properties, TraceProperty(pdef, byteoffset))
            byteoffset += sizeof(pdef)
        end
    end
    propsymbols = ntuple(i->Symbol(properties[i].def.label), length(properties))
    axissymbols = ntuple(i->Symbol(_axis_propdefs[i].label), length(_axis_propdefs))
    NamedTuple{propsymbols}(properties),NamedTuple{axissymbols}(_axis_propdefs)
end

function get_dataproperties(xml::XMLDocument)
    dataprops = Array{DataProperty}(undef, 0)
    for parset in child_elements(root(xml))
        if attribute(parset, "name") == "CustomProperties"
            for par in child_elements(parset)
                name = attribute(par, "name")
                # complicated custom props, see below
                if name != "Geometry" && name != "FieldInstruments"  && name != "extendedParmTable"
                    format = attribute(par, "type")
                    value  = content(par)
                    push!(dataprops, DataProperty(name, format, value))
                end
            end
        end
    end
    return dataprops
end

function get_geom(xml::XMLDocument)
    for parset in child_elements(root(xml))
        if attribute(parset, "name") == "CustomProperties"
            for parset2 in child_elements(parset)
                if attribute(parset2, "name") == "Geometry"
                    try
                        g = Dict()
                        for par in child_elements(parset2)
                            parname = attribute(par, "name")
                            if in(parname, ("u1","un","v1","vn","w1","wn"))
                                g[parname] = parse(Int,content(par))
                            else
                                g[parname] = parse(Float64,content(par))
                            end
                        end
                        return Geometry(
                            g["u1"],g["un"],g["v1"],g["vn"],g["w1"],g["wn"],
                            g["ox"],g["oy"],g["oz"],
                            g["ux"],g["uy"],g["uz"],
                            g["vx"],g["vy"],g["vz"],
                            g["wx"],g["wy"],g["wz"])
                    catch
                        @warn "Corrupt geometry information"
                        return nothing
                    end
                end
            end
        end
    end
    return nothing
end

function get_description(io::IOStream)
    for ln in eachline(io)
        if ln[1] != '#'
            x = split(ln, '=')
            if x[1] == "DescriptiveName"
                return strip(x[2])
            end
        end
    end
    return " "
end

function get_status(io::IOStream)
    for ln in eachline(io)
        if ln[1] != '#'
            x = split(ln, '=')
            if length(x) < 2
                @warn "Corrupt status information. Status information, i.e. \"has traces\", may be incorrect."
                return false
            end
            if chomp(x[2]) == "true"
                return true
            end
        end
    end
    return false
end

function get_secondaries(xml::XMLDocument)
    n = get_nsecondaries(xml)
    secondaries = Array{String}(undef, n)
    for i=1:n
        secondaries[i] = get_secondary(xml, i)
    end
    return secondaries
end

function get_nsecondaries(xml::XMLDocument)
    for par in child_elements(root(xml))
        if attribute(par, "name") == "NDIR"
            return parse(Int, content(par))
        end
    end
end

function get_secondary(xml, i)
    for par in child_elements(root(xml))
        if attribute(par, "name") == "FILESYSTEM-$(i-1)"
            path = strip(split(content(par),',')[1])
            return path
        end
    end
end

get_nextents(xml::XMLDocument)     = parse(Int32, strip(content(get_extent_manager_element(xml, "VFIO_MAXFILE"))))
get_extentname(xml::XMLDocument)   = strip(content(get_extent_manager_element(xml, "VFIO_EXTNAME")))
get_extentsize(xml::XMLDocument)   = parse(Int64, strip(content(get_extent_manager_element(xml, "VFIO_EXTSIZE"))))
get_extentmaxpos(xml::XMLDocument) = parse(Int64, strip(content(get_extent_manager_element(xml, "VFIO_MAXPOS"))))

function get_file_property_element(xml::XMLDocument, name::String)
    for parset in child_elements(root(xml))
        if attribute(parset, "name") == "FileProperties"
            for par in child_elements(parset)
                if attribute(par, "name") == name
                    return par
                end
            end
        end
    end
    error("Malformed JavaSeis.")
end

function get_extent_manager_element(xml::XMLDocument, name::String)
    for par in child_elements(root(xml))
        if attribute(par, "name") == name
            return par
        end
    end
    error("Malformed JavaSeis.")
end

# write xml files ...
function make_primarydir(io::JSeis)
    if isdir(io.filename)
        rm(io.filename, recursive = true)
    end
    mkpath(io.filename)
end

function make_extentdirs(io::JSeis)
    for file in io.secondaries
        if isdir(extentdir(file, io.filename))
            rm(extentdir(file, io.filename), recursive = true)
        end
        mkpath(extentdir(file, io.filename))
    end
end

function delete_first_line(filename::AbstractString)
    io = open(filename)
    lines = readlines(io,keep=true)
    close(io)
    io = open(filename, "w")
    for i = 2:length(lines)
        write(io, lines[i])
    end
    close(io)
end

function write_fileproperties(io::JSeis)
    xdoc = XMLDocument()

    # preamble
    jsmetadata = create_root(xdoc, "parset")
    set_attribute(jsmetadata, "name", "JavaSeis Metadata")
    fileproperties = new_child(jsmetadata, "parset")
    set_attribute(fileproperties, "name", "FileProperties")

    # translate ProMax property labels to JavaSeis axis labels
    axislabels = proplabel.(collect(io.axis_propdefs))
    for (i,lbl) in enumerate(axislabels)
        axislabels[i] = haskey(dictPMtoJS, lbl) == true ? dictPMtoJS[lbl] : lbl
    end

    # file properties
    write_parproperty(fileproperties, "Comments",          "string",  " \"JavaSeis.jl - JavaSeis File Propertties 2006.3\" ")
    write_parproperty(fileproperties, "JavaSeisVersion",   "string",  " 2006.3 ")
    write_parproperty(fileproperties, "DataType",          "string",  " $(io.datatype) ")
    write_parproperty(fileproperties, "TraceFormat",       "string",  " $(asciidataformat(io.dataformat)) ")
    write_parproperty(fileproperties, "ByteOrder",         "string",  " $(io.dataorder) ")
    write_parproperty(fileproperties, "Mapped",            "boolean", " $(io.mapped == true ? "true" : "false") ")
    write_parproperty(fileproperties, "DataDimensions",    "int",     " $(length(io.axis_lengths)) ")
    write_parproperty(fileproperties, "AxisLabels",        "string",  formataxes(axislabels))
    write_parproperty(fileproperties, "AxisUnits",         "string",  formataxes(io.axis_units))
    write_parproperty(fileproperties, "AxisDomains",       "string",  formataxes(io.axis_domains))
    write_parproperty(fileproperties, "AxisLengths",       "long",    formataxes(io.axis_lengths))
    write_parproperty(fileproperties, "LogicalOrigins",    "long",    formataxes(io.axis_lstarts))
    write_parproperty(fileproperties, "LogicalDeltas",     "long",    formataxes(io.axis_lincs))
    write_parproperty(fileproperties, "PhysicalOrigins",   "double",  formataxes(io.axis_pstarts))
    write_parproperty(fileproperties, "PhysicalDeltas",    "double",  formataxes(io.axis_pincs))
    write_parproperty(fileproperties, "HeaderLengthBytes", "int",     " $(headerlength(io)) ")

    # trace properties
    traceproperties = new_child(jsmetadata, "parset")
    set_attribute(traceproperties, "name", "TraceProperties")

    i = 0
    for property in io.properties
        write_traceproperty(traceproperties, i, property)
        i += 1
    end

    # custom properties
    customproperties = new_child(jsmetadata, "parset")
    set_attribute(customproperties, "name", "CustomProperties")

    for dataprop in io.dataproperties
        write_parproperty(customproperties, dataprop.label, propertyformatstring(dataprop), " $(convert(dataprop.format, dataprop.value)) ")
    end

    # 3-point geometry
    if io.geom != nothing
        geometry = new_child(customproperties, "parset")
        set_attribute(geometry, "name", "Geometry")
        write_parproperty(geometry, "u1", "long",   " $(io.geom.u1) ")
        write_parproperty(geometry, "un", "long",   " $(io.geom.un) ")
        write_parproperty(geometry, "v1", "long",   " $(io.geom.v1) ")
        write_parproperty(geometry, "vn", "long",   " $(io.geom.vn) ")
        write_parproperty(geometry, "w1", "long",   " $(io.geom.w1) ")
        write_parproperty(geometry, "wn", "long",   " $(io.geom.wn) ")
        write_parproperty(geometry, "ox", "double", " $(io.geom.ox) ")
        write_parproperty(geometry, "oy", "double", " $(io.geom.oy) ")
        write_parproperty(geometry, "oz", "double", " $(io.geom.oz) ")
        write_parproperty(geometry, "ux", "double", " $(io.geom.ux) ")
        write_parproperty(geometry, "uy", "double", " $(io.geom.uy) ")
        write_parproperty(geometry, "uz", "double", " $(io.geom.uz) ")
        write_parproperty(geometry, "vx", "double", " $(io.geom.vx) ")
        write_parproperty(geometry, "vy", "double", " $(io.geom.vy) ")
        write_parproperty(geometry, "vz", "double", " $(io.geom.vz) ")
        write_parproperty(geometry, "wx", "double", " $(io.geom.wx) ")
        write_parproperty(geometry, "wy", "double", " $(io.geom.wy) ")
        write_parproperty(geometry, "wz", "double", " $(io.geom.wz) ")
    end

    # Write data
    save_file(xdoc, "$(io.filename)/FileProperties.xml")

    # Delete the first line from the file <?xml verion="1.0...
    delete_first_line("$(io.filename)/FileProperties.xml")
end

function write_traceproperty(parent::XMLElement, i::Int, property::TraceProperty)
    header = new_child(parent, "parset")
    set_attribute(header, "name", "entry_$(i)")
    write_parproperty(header, "label",        "string", " $(property.def.label) ")
    write_parproperty(header, "description",  "string", " \"$(property.def.description)\" ")
    write_parproperty(header, "format",       "string", " $(propertyformatstring(property)) ")
    write_parproperty(header, "elementCount", "int",    " $(property.def.elementcount) ")
    write_parproperty(header, "byteOffset",   "int",    " $(property.byteoffset) ")
end

function formataxes(items::Array)
    labels = "\n"
    for label in items
        labels = "$(labels)      $(label)\n"
    end
    labels = "$(labels)    "
end

function asciidataformat(dataformat::Type)
    if dataformat == Float32
        return "FLOAT"
    elseif dataformat == Float64
        return "DOUBLE"
    elseif dataformat == Int16
        return "COMPRESSED_INT16"
    end
    error("unsupported data format")
end

function write_nameproperties(io::JSeis)
    ioname = open(joinpath(io.filename,"Name.properties"), "w")
    write(ioname,
"#JavaSeis.jl - JavaSeis File Properties 2006.3
#$(datestamp())
DescriptiveName=$(io.description)")
    close(ioname)
end

function write_statusproperties(io::JSeis)
    iostatus = open(joinpath(io.filename, "Status.properties"), "w")
    write(iostatus,
"#JavaSeis.jl - JavaSeis File Properties 2006.3
#$(datestamp())
HasTraces=$(io.hastraces == true ? "true" : "false")")
    close(iostatus)
end

function datestamp()
    date = Dates.now()
    year = Dates.year(date)
    mon = Dates.monthabbr(date)
    wday = Dates.dayabbr(date)
    day = Dates.dayofmonth(date)
    hour = Dates.hour(date) < 10 ? "0$(Dates.hour(date))" : Dates.hour(date)
    min = Dates.minute(date) < 10 ? "0$(Dates.minute(date))" : Dates.minute(date)
    sec = Dates.second(date) < 10 ? "0$(Dates.second(date))" : Dates.second(date)
    return "$(wday) $(mon) $(day) $(hour):$(min):$(sec) $(year)"
end

function write_extentmanager(io::JSeis)
    xdoc = XMLDocument()
    extentman = create_root(xdoc, "parset")
    set_attribute(extentman, "name", "ExtentManager")
    write_parproperty(extentman, "VFIO_VERSION", "string", " 2006.2 ")
    write_parproperty(extentman, "VFIO_EXTSIZE", "long",   " $(io.trcextents[1].size) ")
    write_parproperty(extentman, "VFIO_MAXFILE", "int",    " $(length(io.trcextents)) ")
    write_parproperty(extentman, "VFIO_MAXPOS",  "long",   " $(prod(io.axis_lengths[2:end]) * tracelength(io) - 1) ")
    write_parproperty(extentman, "VFIO_EXTNAME", "string", " TraceFile ")
    write_parproperty(extentman, "VFIO_POLICY",  "string", " RANDOM ")

    save_file(xdoc, joinpath(io.filename, "TraceFile.xml"))
    delete_first_line(joinpath(io.filename, "TraceFile.xml"))

    xdoc = XMLDocument()
    extentman = create_root(xdoc, "parset")
    set_attribute(extentman, "name", "ExtentManager")
    write_parproperty(extentman, "VFIO_VERSION", "string", " 2006.2 ")
    write_parproperty(extentman, "VFIO_EXTSIZE", "long",   " $(io.hdrextents[1].size) ")
    write_parproperty(extentman, "VFIO_MAXFILE", "int",    " $(length(io.hdrextents)) ")
    write_parproperty(extentman, "VFIO_MAXPOS",  "long",   " $(prod(io.axis_lengths[2:end]) * headerlength(io) - 1) ")
    write_parproperty(extentman, "VFIO_EXTNAME", "string", " TraceHeaders ")
    write_parproperty(extentman, "VFIO_POLICY",  "string", " RANDOM ")

    save_file(xdoc, joinpath(io.filename, "TraceHeaders.xml"))
    delete_first_line(joinpath(io.filename, "TraceHeaders.xml"))
end

function write_virtualfolders(io::JSeis)
    xdoc = XMLDocument()
    virtman = create_root(xdoc, "parset")
    set_attribute(virtman, "name", "VirtualFolders")

    write_parproperty(virtman, "NDIR", "int", " $(length(io.secondaries)) ")
    for i = 1:length(io.secondaries)
        write_parproperty(virtman, "FILESYSTEM-$(i-1)", "string", " $(io.secondaries[i]),READ_WRITE ")
    end
    write_parproperty(virtman, "Version",   "string", " 2006.2 ")
    write_parproperty(virtman, "Header",    "string", " \"VFIO org.javaseis.VirtualFolder 2006.2\" ")
    write_parproperty(virtman, "Type",      "string", " SS ")
    write_parproperty(virtman, "POLICY_ID", "string", " RANDOM ")
    write_parproperty(virtman, "GLOBAL_REQUIRED_FREE_SPACE", "long",  " $(prod(io.axis_lengths[2:end]) * (io.axis_lengths[1] * sizeof(io.dataformat) + headerlength(io))) ")

    save_file(xdoc, joinpath(io.filename, "VirtualFolders.xml"))
    delete_first_line(joinpath(io.filename, "VirtualFolders.xml"))
end

function write_parproperty(parent::XMLElement, name::String, format::String, value::String)
    child = new_child(parent, "par")
    set_attribute(child, "name", name)
    set_attribute(child, "type", format)
    add_text(child, value)
end

# trace map
volumeindex(io::JSeis, frm::Int64) = div(frm-1, io.axis_lengths[3]) + 1
mapposition(io::JSeis, frm::Int64) = frm - (volumeindex(io, frm) - 1) * io.axis_lengths[3]

function readmap(io::JSeis, frm::Int64)
    vol = volumeindex(io, frm)
    if vol == io.currentvolume
        return
    end
    posn = (vol - 1) * io.axis_lengths[3] * sizeof(Int32)
    iomap = open(joinpath(io.filename, "TraceMap"), "r")
    seek(iomap, posn)
    read!(iomap, io.map)
    close(iomap)
    io.currentvolume = vol
end

function create_map(io::JSeis)
    iomap = open(joinpath(io.filename, "TraceMap"), "w")
    write(iomap, zeros(Int32, prod(io.axis_lengths[3:end])))
    close(iomap)
end

function fold_impl(io::JSeis, frm::Int64)
    if io.mapped == false
        return io.axis_lengths[2]
    end
    readmap(io, frm)
    idx = mapposition(io, frm)
    return Int(io.map[idx])
end

"""
    fold(io, hdrs)

Compute the fold of a frame where io is JSeis corresponding to the dataset, and hdrs are the headers for the frame.
For example: `io=jsopen("file.js"); fold(io, readframehdrs(io,1))`
"""
function fold(io::JSeis, hdrs::Array{UInt8,2})
    trctyp = prop(io, stockprop[:TRC_TYPE])
    mapreduce(i->get(trctyp, hdrs, i) == tracetype[:live] ? 1 : 0, +, 1:size(hdrs,2))
end

"""
    fold(io, idx...)

Compute the fold of a frame where idx is the frame/volume/hypercube indices.  For example, `fold(jsopen("file.js"),1)`
for a 3D dataset, `fold(jsopen("file.js",1,2))` for a 4D dataset, and `fold(jsopen("file.js"),1,2,3)` for a 5D dataset.
"""
fold(io::JSeis, idx::Int64...) = fold_impl(io::JSeis, sub2ind(io, idx))
fold(io::JSeis, idx::CartesianIndex) = fold_impl(io::JSeis, sub2ind(io, idx))

function fold!(io::JSeis, frm::Int64, fld::Int)
    if io.mapped == true
        if volumeindex(io,frm) == io.currentvolume
            io.map[mapposition(io, frm)] = unsafe_trunc(Int32,fld)
        end
        posn = (frm-1)*sizeof(Int32)
        iomap = open(joinpath(io.filename, "TraceMap"), "a")
        seek(iomap, posn)
        write(iomap, Int32(fld))
        close(iomap)
    end
end

# extents
extentindex(extents, offset) = extents[div(offset, extents[1].size) + 1]
nextents_heuristic(dims::Array{Int64,1}, format::Type) = ceil(Int, clamp(10.0 + prod(dims)*sizeof(format)/(2.0*1024.0^3), 1, 256))

function extentdir(secondary::String, filename::String)
    isrelative = isabspath(filename) == false
    datahome = haskey(ENV, "PROMAX_DATA_HOME") ? ENV["PROMAX_DATA_HOME"] : ""
    datahome = haskey(ENV, "JAVASEIS_DATA_HOME") ? ENV["JAVASEIS_DATA_HOME"] : datahome
    if secondary == "."
        return abspath(filename)
    elseif datahome != ""
        filename = abspath(filename)
        if occursin(datahome, filename) == true
            return normpath(replace(filename, datahome => (Sys.iswindows() ? "$(secondary)//" : "$(secondary)/")))
        end
        if isrelative == true && startswith(pwd(),datahome) == false
            error("JAVASEIS_DATA_HOME or PROMAX_DATA_HOME is set, and JavaSeis filename is relative,
but the working directory is not consistent with JAVASEIS_DATA_HOME: datahome=$(datahome), filename=$(filename).
Either unset JAVASEIS_DATA_HOME and PROMAX_DATA_HOME, make your working directory correspond to datahome, or use absolute file paths.")
        end
        error("JAVASEIS_DATA_HOME or PROMAX_DATA_HOME is set but does not seem correct: datahome=$(datahome), filename=$(filename)")
    elseif isrelative == true
        return joinpath(secondary, filename)
    else
        return joinpath(secondary, Sys.iswindows() ? filename[5:end] : filename[2:end])
    end
end

function get_extents(xml::XMLDocument, secondaries::Array{String,1}, filename::String)
    nextents = get_nextents(xml)
    basename = get_extentname(xml)
    size     = get_extentsize(xml)
    extents  = fill(Extent(), nextents)
    for secondary in secondaries
        base_extentpath = extentdir(secondary, filename)
        if isdir(base_extentpath) == true
            names = filter(s->startswith(s,basename) == true && endswith(s,".xml") == false, readdir(base_extentpath))
            for name in names
                i = parse(Int32,name[length(basename)+1:end]) + 1
                if i <= nextents
                    start = (i - 1) * size
                    path  = joinpath(base_extentpath, name)
                    extents[i] = Extent(name, path, i, start, size)
                end
            end
        end
    end

    # add missing extents (i.e. extents with all empty frames)
    isec, nsec = 1, length(secondaries)
    for i=1:nextents
        if missing(extents[i]) == true
            start = (i - 1) * size
            name  = "$(basename)$(i-1)"
            path  = joinpath(extentdir(secondaries[isec], filename), name)
            extents[i] = Extent(name, path, i, start, size)
            isec = isec == nsec ? 1 : isec + 1
        end
    end

    # the last extent might be a different size
    extents[nextents].size = get_extentmaxpos(xml) - extents[nextents].start

    return extents
end

function make_extents(nextents::Int, secondaries::Array{String,1}, filename::String, axis_lengths::Array{Int64,1}, bytespertrace::Int64, basename::String)
    isec, nsec = 1, length(secondaries)
    extents = Array{Extent}(undef, nextents)
    total_size = prod(axis_lengths[2:end]) * bytespertrace
    extent_size = ceil(Int64, prod(axis_lengths[3:end]) / nextents) * axis_lengths[2] * bytespertrace
    for i = 1:nextents
        extents[i] = Extent()
        extents[i].name = "$(basename)$(i-1)"
        extents[i].path = joinpath(extentdir(secondaries[isec], filename), "$(basename)$(i-1)")
        extents[i].index = i-1
        extents[i].start = (i-1) * extent_size
        extents[i].size = min(extent_size, total_size)
        isec = isec == nsec ? 1 : isec + 1
        total_size -= extent_size
    end
    return extents
end

# headers
function headerlength(properties)
    hdrlength = 0
    for key in keys(properties)
        hdrlength += sizeof(properties[key])
    end
    return hdrlength
end
headerlength(io::JSeis) = io.hdrlength

"""
    get(prop, hdr)

Get the value of the trace property `prop::TraceProperty` stored in the header `hdr::Array{UInt8,1}`.  For example,
`io=jsopen("data.js"); get(prop(io, "REC_X"), readframehdrs(io,1)[:,1])`
"""
function get(prop::TraceProperty{T}, hdr::AbstractArray{UInt8,1}) where T<:Number
    iohdr = IOBuffer(hdr, read=true)
    seek(iohdr, prop.byteoffset)
    return read(iohdr, T)
end
function get(prop::TraceProperty{Array{T,1}}, hdr::AbstractArray{UInt8,1}) where T<:Union{Int32,Int64,AbstractFloat}
    iohdr = IOBuffer(hdr, read=true)
    seek(iohdr, prop.byteoffset)
    return read!(iohdr, Array{T,1}(undef, prop.def.elementcount))
end
function get(prop::TraceProperty{Array{UInt8,1}}, hdr::AbstractArray{UInt8,1})
    iohdr = IOBuffer(hdr, read=true)
    seek(iohdr, prop.byteoffset)
    return strip(String(copy(read!(iohdr, Array{UInt8,1}(undef, prop.def.elementcount)))),'\0')
end
"""
    get(prop, hdrs, i)

Get the value of the trace property `prop::TraceProperty` stored in the header of the ith column of
`hdrs::Array{UInt8,2}`.  For example, `io=jsopen("data.js"); get(prop(io, "REC_X"), readframehdrs(io,1), 1)`.
"""
get(prop::TraceProperty, hdr::AbstractArray{UInt8,2}, i::Int64) = get(prop, @view(hdr[:,i]))

"""
    set!(prop, hdrs, i, value)

Set the value of the trace property `prop::TraceProperty` stored in the header of the ith column of
`hdrs::Array{UInt8,2}` to `value::T`.  For example,
`io=jsopen("test.js"); hdrs=readframehdrs(io,1); set!(prop(io,"REC_X"), 1, 10.0)`.
"""
function set!(prop::TraceProperty, hdrs::AbstractArray{UInt8,2}, i::Int64, value::T) where T<:Number
    @assert prop.def.elementcount == 1
    iohdr = IOBuffer(vec(hdrs), read=true, write=true)
    seek(iohdr, (i-1)*size(hdrs,1) + prop.byteoffset)
    write(iohdr, convert(prop.def.format, value))
end
function set!(prop::TraceProperty, hdrs::AbstractArray{UInt8,2}, i::Int64, value::Array{T}) where T<:Number
    @assert length(value) == prop.def.elementcount
    iohdr = IOBuffer(vec(hdrs), read=true, write=true)
    seek(iohdr, (i-1)*size(hdrs,1) + prop.byteoffset)
    write(iohdr, convert(prop.def.format, prop.def.elementcount == 1 ? value[1] : value))
end
function set!(prop::TraceProperty, hdrs::AbstractArray{UInt8,2}, i::Int64, value::AbstractString)
    @assert length(value) < prop.def.elementcount
    iohdr = IOBuffer(vec(hdrs), read=true, write=true)
    seek(iohdr, (i-1)*size(hdrs,1) + prop.byteoffset)
    write(iohdr, unsafe_wrap(Array{UInt8}, pointer(value), sizeof(value)))
end

"""
    prop(io, propertyname[, proptype=Any])

Get a trace property from `io::JSeis` where `propertyname` is either `String` or `TracePropertyDef`.
Note that if  `propertyname` is a String, then this method produces a type-unstable result.
For example:

 ```julia
io = jsopen("data.js")
p = prop(io, "REC_X")            # using a `String`, output type of prop is not inferred
p = prop(io, "REC_X", Float32)   # using a `String`, output type of prop is inferred using `Float32`
p = prop(io, stockprop[:REC_X])  # using a `TracePropertyDef`, output type of prop is inferred
```

Note that in the examples above, the string "REC_X" can be replaced by the symbol `REC_X`.
"""
prop(io::JSeis, _property::Symbol) = io.properties[_property]
prop(io::JSeis, _property::String) = prop(io, Symbol(_property))
prop(io::JSeis, _property::Symbol, _T::Type{T}) where {T} = io.properties[_property]::TraceProperty{T}
prop(io::JSeis, _property::String, _T::Type{T}) where {T} = prop(io, Symbol(_property), T)::TraceProperty{T}
prop(io::JSeis, _property::TracePropertyDef{T}) where {T} = prop(io, _property.label, T)

"""
    copy!(ioout, hdrsout, ioin, hdrsin)

Copy trace headers from `hdrsin::Array{Uint8,2}` to `hdrsout::Array{Uint8,2}` and where
`hdrsin` corresponds to `ioin::JSeis` and `hdrsout` corresponds to `ioout::JSeis`.  For example,

```julia
ioin = jsopen("data1.js")
ioout = jsopen("data2.js")
hdrsin = readframehdrs(ioin,1)
hdrsout = readframehdrs(ioout,1)
copy!(ioout, hdrsout, ioin, hdrsin)
```
"""
function copy!(ioout::JSeis, hdrsout::AbstractArray{UInt8,2}, ioin::JSeis, hdrsin::AbstractArray{UInt8,2})
    @assert size(hdrsout, 2) == size(hdrsin, 2)

    for propoutkey in keys(ioout.properties)
        if in(propoutkey, ioin.properties)
            propin = ioin.properties[propoutkey]
            propout = ioout.properties[propoutkey]
            for i = 1:size(hdrsout,2)
                set!(propout, hdrsout, i, get(propin, hdrsin, i))
            end
        end
    end
end

# from promax manual, this is the minimal (guaranteed) set of properties
function sspropset!(properties::Array{TraceProperty,1}, off::Int64)
    for p in (:SEQNO,
              :END_ENS,
              :EOJ,
              :TRACENO,
              :TRC_TYPE,
              :TLIVE_S,
              :TFULL_S,
              :TFULL_E,
              :TLIVE_E,
              :LEN_SURG,
              :TOT_STAT,
              :NA_STAT,
              :AMP_NORM,
              :TR_FOLD,
              :SKEWSTAT,
              :LINE_NO,
              :LSEG_END,
              :LSEG_SEQ)
        push!(properties, TraceProperty(stockprop[p], off))
        off += sizeof(stockprop[p])
    end
    return off
end

# global data properties
"""
    dataproperty(io, label)

Get a data property (data properties are per file, rather than per trace) from `io::JSeis` with
label `label::String`.  For example, `dataproperty(jsopen("data.js"), "FREQUENCY")`.
"""
function dataproperty(io::JSeis, label::String)
    for dataprop in io.dataproperties
        if dataprop.label == label
            return dataprop.value
        end
    end
    error("data property -- $(label) -- not found.")
end

"""
    hasdataproperty(io, label)

return true if `io::JSeis` contains the data property corresponding to `label`.  Otherwise, return false.
"""
function hasdataproperty(io, label)
    for dataprop in io.dataproperties
        if dataprop.label == label
            return true
        end
    end
    return false
end

# memory allocation
"""
    allocframe(io)

Allocate memory for one frame of JavaSeis dataset.  Returns `(Array{Float32,2},Array{UInt8,2})`.
For example, `trcs, hdrs = allocframe(jsopen("data.js"))`.
"""
allocframe(io::JSeis) = allocframetrcs(io), allocframehdrs(io)
"""
allocframehdrs(io)

Allocate memory for headers for one frame of JavaSeis dataset.  Returns `Array{UInt8,2}`.
For example, `hdrs = allocframehdrs(jsopen("data.js"))`.
"""
allocframehdrs(io::JSeis) = zeros(UInt8, headerlength(io), io.axis_lengths[2])::Array{UInt8,2}
"""
allocframetrcs(io)

Allocate memory for traces for one frame of JavaSeis dataset.  Returns `Array{Float32,2}`.
For example, `trcs = allocframetrcs(jsopen("data.js"))`.
"""
allocframetrcs(io::JSeis) = zeros(Float32, io.axis_lengths[1], io.axis_lengths[2])

# reading/writing
function readframetrcs_impl!(io::JSeis, trcs::AbstractArray{Float32,2}, frm::Int64)
    @assert io.mode != "w"
    fld = Int(fold_impl(io, frm))
    if fld == 0
        return 0
    end

    offset = (frm - 1) * tracelength(io) * io.axis_lengths[2]
    ext = extentindex(io.trcextents, offset)
    offset -= ext.start
    if io.dataformat == Float32
        localio = open(ext.path, "r")
        seek(localio, offset)
        unsafe_read(localio, convert(Ptr{UInt8}, pointer(trcs)), io.axis_lengths[1]*fld*sizeof(Float32))
        close(localio)
    elseif io.dataformat == Int16
        frmbuf = allocframebuf(io.compressor, fld)
        localio = open(ext.path, "r")
        seek(localio, offset)
        read!(localio, frmbuf.data)
        close(localio)
        unpackframe!(io.compressor, trcs, frmbuf, fld)
    else
        error("unsupported data format")
    end
    return fld
end
function readframetrcs_impl(io::JSeis, frm::Int64)
    trcs = allocframetrcs(io)
    readframetrcs_impl!(io, trcs, frm)
    return trcs
end

function readframehdrs_impl!(io::JSeis, hdrs::AbstractArray{UInt8,2}, frm::Int64)
    @assert io.mode != "w"
    fld = Int(fold_impl(io, frm))
    prop_trctype = prop(io, stockprop[:TRC_TYPE])
    map(i->set!(prop_trctype, hdrs, i, tracetype[:dead]), (fld+1):size(hdrs,2))
    if fld == 0
        return 0
    end
    hdrlen = headerlength(io)

    offset = (frm - 1) * hdrlen * io.axis_lengths[2]
    ext = extentindex(io.hdrextents, offset)
    offset -= ext.start
    localio = open(ext.path, "r")
    seek(localio, offset)
    unsafe_read(localio, pointer(hdrs), hdrlen*fld)
    close(localio)
    return fld
end
function readframehdrs_impl(io::JSeis, frm::Int64)
    hdrs = allocframehdrs(io)
    readframehdrs_impl!(io, hdrs, frm)
    return hdrs
end

function readframe_impl!(io::JSeis, trcs::AbstractArray{Float32,2}, hdrs::AbstractArray{UInt8,2}, frm::Int64)
    readframetrcs_impl!(io, trcs, frm)
    readframehdrs_impl!(io, hdrs, frm)
end
function readframe_impl(io::JSeis, frm::Int64)
    trcs, hdrs = allocframe(io)
    readframe_impl!(io, trcs, hdrs, frm)
    return trcs, hdrs
end

"""
    readframe!(io, trcs, hdrs, idx...)

In-place read of a single frame from a JavaSeis dataset.  For non full frame, the resulting traces
and headers are left justified.  Examples:

# 3D:

```julia
io = jsopen("data_3D.js")
trcs, hdrs = allocframe(io)
frm_idx = 1
readframe!(io, trcs, hdrs, frm_idx)
```

# 4D:

```julia
io = jsopen("data_4D.js")
trcs, hdrs = allocframe(io)
frm_idx, vol_idx = 1, 1
readframe!(io, trcs, hdrs, frm_idx, vol_idx)
```

# 5D:

```julia
io = jsopen("data_5D.js")
trcs, hdrs = allocframe(io)
frm_idx, vol_idx, hyp_idx = 1, 1, 1
readframe!(io, trcs, hdrs, frm_idx, vol_idx, hyp_idx)
```
"""
readframe!(io::JSeis, trcs::AbstractArray{Float32, 2}, hdrs::AbstractArray{UInt8, 2}, idx::Int...) = readframe_impl!(io, trcs, hdrs, sub2ind(io, idx))
readframe!(io::JSeis, trcs::AbstractArray{Float32, 2}, hdrs::AbstractArray{UInt8, 2}, idx::CartesianIndex) = readframe_impl!(io, trcs, hdrs, sub2ind(io, idx))

"""
    readframe(io, idx...)

Out-of-place read of a single frame from a JavaSeis dataset.  For non full frame, the resulting traces
and headers are left justified.  Examples:

# 3D:

```julia
frm_idx = 1
trcs, hdrs = readframe(jsopen("data_3D.js"), frm_idx)
```

# 4D:

```julia
frm_idx, vol_idx = 1, 1
trcs, hdrs = readframe(jsopen("data_4D.js"), frm_idx, vol_idx)
```

# 5D:

```julia
frm_idx, vol_idx, hyp_idx = 1, 1, 1
trcs, hdrs = readframe(jsopen("data_5D.js"), frm_idx, vol_idx, hyp_idx)
```
"""
readframe(io::JSeis, idx::Int...) = readframe_impl(io, sub2ind(io, idx))
readframe(io::JSeis, idx::CartesianIndex) = readframe_impl(io, sub2ind(io, idx))

"""
    readframetrcs!(io, trcs, hdrs, idx...)

In-place read of a single frame from a JavaSeis dataset (traces only).  For non full frame, the resulting traces
are left justified.  Examples:

# 3D:

```julia
io = jsopen("data_3D.js")
trcs = allocframetrcs(io)
frm_idx = 1
readframetrcs!(io, trcs, frm_idx)
```

# 4D:

```julia
io = jsopen("data_4D.js")
trcs = allocframetrcs(io)
frm_idx, vol_idx = 1, 1
readframetrcs!(io, trcs, frm_idx, vol_idx)
```

# 5D:

```julia
io = jsopen("data_5D.js")
trcs = allocframetrcs(io)
frm_idx, vol_idx, hyp_idx = 1, 1, 1
readframetrcs!(io, trcs, frm_idx, vol_idx, hyp_idx)
```
"""
readframetrcs!(io::JSeis, trcs::AbstractArray{Float32,2}, idx::Int...) = readframetrcs_impl!(io, trcs, sub2ind(io, idx))
readframetrcs!(io::JSeis, trcs::AbstractArray{Float32,2}, idx::CartesianIndex) = readframetrcs_impl!(io, trcs, sub2ind(io, idx))

"""
    readframetrcs(io, idx...)

Out-of-place read of a single frame (traces only) from a JavaSeis dataset.  For non full frame, the resulting traces
are left justified.  Examples:

# 3D:

```julia
frm_idx = 1
trcs = readframetrcs(jsopen("data_3D.js"), frm_idx)
```

# 4D:

```julia
frm_idx, vol_idx = 1, 1
trcs = readframetrcs(jsopen("data_4D.js"), frm_idx, vol_idx)
```

# 5D:

```julia
frm_idx, vol_idx, hyp_idx = 1, 1, 1
trcs = readframetrcs(jsopen("data_5D.js"), frm_idx, vol_idx, hyp_idx)
```
"""
readframetrcs(io::JSeis, idx::Int...) = readframetrcs_impl(io, sub2ind(io, idx))
readframetrcs(io::JSeis, idx::CartesianIndex) = readframetrcs_impl(io, sub2ind(io, idx))

"""
    readframehdrs!(io, hdrs, idx...)

In-place read of a single frame from a JavaSeis dataset (headers only).  For non full frame, the resulting headers
are left justified.  Examples:

# 3D:

```julia
io = jsopen("data_3D.js")
hdrs = allocframehdrs(io)
frm_idx = 1
readframehdrs!(io, hdrs, frm_idx)
```

# 4D:

```julia
io = jsopen("data_4D.js")
hdrs = allocframehdrs(io)
frm_idx, vol_idx = 1, 1
readframehdrs!(io, hdrs, frm_idx, vol_idx)
```

# 5D:

```julia
io = jsopen("data_5D.js")
hdrs = allocframehdrs(io)
frm_idx, vol_idx, hyp_idx = 1, 1, 1
readframehdrs!(io, hdrs, frm_idx, vol_idx, hyp_idx)
```
"""
readframehdrs!(io::JSeis, hdrs::AbstractArray{UInt8,2}, idx::Int...) = readframehdrs_impl!(io, hdrs, sub2ind(io, idx))
readframehdrs!(io::JSeis, hdrs::AbstractArray{UInt8,2}, idx::CartesianIndex) = readframehdrs_impl!(io, hdrs, sub2ind(io, idx))

"""
readframehdrs(io, idx...)

Out-of-place read of a single frame (headers only) from a JavaSeis dataset.  For non full frame, the resulting headers
are left justified.  Examples:

# 3D:

```julia
frm_idx = 1
hdrs = readframehdrs(jsopen("data_3D.js"), frm_idx)
```

# 4D:

```julia
frm_idx, vol_idx = 1, 1
hdrs = readframehdrs(jsopen("data_4D.js"), frm_idx, vol_idx)
```

# 5D:

```julia
frm_idx, vol_idx, hyp_idx = 1, 1, 1
hdrs = readframehdrs(jsopen("data_5D.js"), frm_idx, vol_idx, hyp_idx)
```
"""
readframehdrs(io::JSeis, idx::Int...) = readframehdrs_impl(io, sub2ind(io, idx))

function parserngs(io::JSeis, smprng::Union{Int,AbstractRange{Int},Colon}, trcrng::Union{Int,AbstractRange{Int},Colon}, rng::Vararg{Union{Int,AbstractRange{Int},Colon},N}) where N
    smprng = parserng(io, smprng, 1)
    trcrng = parserng(io, trcrng, 2)
    rng = ntuple(i->parserng(io, rng[i], 2+i), N)
    nrng = ntuple(i->length(rng[i]), N)::NTuple{N,Int}
    smprng::StepRange{Int,Int}, trcrng::StepRange{Int,Int}, rng::NTuple{N,StepRange{Int,Int}}, nrng::NTuple{N,Int}
end
parserng(io::JSeis,rng::Int,i) = StepRange(rng,1,rng)
parserng(io::JSeis,rng::StepRange{Int},i) = rng
parserng(io::JSeis,rng::AbstractRange{Int},i) = StepRange(rng)
parserng(io::JSeis,rng::Colon,i) = lrange(io,i)::StepRange{Int,Int}

parseindex(rng::Tuple{AbstractRange}, idx_n::CartesianIndex{1}) = CartesianIndex(rng[1][idx_n[1]])
parseindex(rng::Tuple{AbstractRange,AbstractRange}, idx_n::CartesianIndex{2}) = CartesianIndex(rng[1][idx_n[1]],rng[2][idx_n[2]])
parseindex(rng::Tuple{AbstractRange,AbstractRange,AbstractRange}, idx_n::CartesianIndex{3}) = CartesianIndex(rng[1][idx_n[1]],rng[2][idx_n[2]],rng[3][idx_n[3]])
parseindex(rng::NTuple{N,AbstractRange}, idx_n::CartesianIndex) where {N} = CartesianIndex(ntuple(i->rng[i][idx_n[i]], length(rng)))

function collect(io::JSeis, rng::AbstractRange{Int}, dim::Int)
    collect(div(rng[1]    - io.axis_lstarts[dim],io.axis_lincs[dim])+1:
            div(step(rng)                       ,io.axis_lincs[dim])  :
            div(rng[end]  - io.axis_lstarts[dim],io.axis_lincs[dim])+1)
end

function readtrcs_impl!(io::JSeis, trcs::AbstractArray{Float32}, smprng::AbstractRange{Int}, trcrng::AbstractRange{Int}, rng::Vararg{Union{Colon,Int,AbstractRange{Int}},N}) where N
    frmtrcs, frmhdrs = allocframe(io)
    frm_smprng = collect(io, smprng, 1)
    frm_trcrng = collect(io, trcrng, 2)

    n = ntuple(i->length(rng[i]), N)::NTuple{N,Int}
    for idx_n in CartesianIndices(n)
        idx = parseindex(rng, idx_n)
        if fold(io, idx) == size(io,2)
            readframetrcs_impl!(io, frmtrcs, sub2ind(io, idx))
        else
            readframe_impl!(io, frmtrcs, frmhdrs, sub2ind(io, idx))
            regularize!(io, frmtrcs, frmhdrs)
        end
        for (itrc,trc) in enumerate(frm_trcrng), (ismp,smp) in enumerate(frm_smprng)
            trcs[ismp,itrc,idx_n] = frmtrcs[smp,trc]
        end
    end
end

function readhdrs_impl!(io::JSeis, hdrs::AbstractArray{UInt8}, trcrng::AbstractRange{Int}, rng::Vararg{Union{Colon,Int,AbstractRange{Int}},N}) where N
    frmhdrs = allocframehdrs(io)
    frm_trcrng = collect(io, trcrng, 2)

    n = ntuple(i->length(rng[i]), length(rng))::NTuple{N,Int}
    for idx_n in CartesianIndices(n)
        idx = parseindex(rng, idx_n)
        readframehdrs_impl!(io, frmhdrs, sub2ind(io, idx))
        if fold(io, frmhdrs) < size(io, 2)
            regularize!(io, frmhdrs)
        end
        for (itrc,trc) in enumerate(frm_trcrng)
            hdrs[:,itrc,idx_n] = frmhdrs[:,trc]
        end
    end
end

function read_impl!(io::JSeis, trcs::AbstractArray{Float32}, hdrs::AbstractArray{UInt8}, smprng::AbstractRange{Int}, trcrng::AbstractRange{Int}, rng::Vararg{AbstractRange{Int}, N}) where N
    frmtrcs, frmhdrs = allocframe(io)
    frm_smprng = collect(io, smprng, 1)
    frm_trcrng = collect(io, trcrng, 2)
    n = ntuple(i->length(rng[i]), N)::NTuple{N,Int}
    for idx_n in CartesianIndices(n)
        idx = parseindex(rng, idx_n)
        readframe_impl!(io, frmtrcs, frmhdrs, sub2ind(io, idx))
        if fold(io, idx) < size(io, 2)
            regularize!(io, frmtrcs, frmhdrs)
        end
        for (itrc,trc) in enumerate(frm_trcrng)
            for ismp = 1:size(hdrs,1)
                hdrs[ismp,itrc,idx_n] = frmhdrs[ismp,frm_trcrng[itrc]]
            end
            for (ismp,smp) in enumerate(frm_smprng)
                trcs[ismp,itrc,idx_n] = frmtrcs[smp,trc]
            end
        end
    end
    nothing
end

"""
    readtrcs!(io, trcs, sample_range, trace_range, range...)

In-place read of a subset of data (traces only) from a JavaSeis file. If performance is important, then consider using `readframetrcs!` instead.  Examples:

# 3D:

```julia
readtrcs!(jsopen("data_3D.js"), trcs, :, :, :)
readtrcs!(jsopen("data_3D.js"), trcs, :, 1:2:end, 1:5)
```

# 4D:

```julia
readtrcs!(jsopen("data_4D.js"), trcs, :, :, :, :)
readtrcs!(jsopen("data_4D.js"), trcs, :, :, 2, 2:2:10)
```

# 5D:

```julia
readtrcs!(jsopen("data_5D.js"), trcs, :, :, :, :, :)
readtrcs!(jsopen("data_5D.js"), trcs, :, :, 2, 2:2:10, 1:10)
```
"""
function readtrcs!(io::JSeis, trcs::AbstractArray{Float32}, rng::Vararg{Union{Int,AbstractRange{Int},Colon},N}) where N
    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    @assert size(trcs)[1:2] == (length(smprng), length(trcrng)) && size(trcs)[3:end] == nrng
    readtrcs_impl!(io, trcs, smprng, trcrng, _rng...)
end

"""
    readtrcs(io, sample_range, trace_range, range...)

Out-of-place read of a subset of data (traces only) from a JavaSeis file. Returns an array of trace data. If performance is important, then consider using `readframetrcs` instead.  Examples:

# 3D:

```julia
trcs = readtrcs(jsopen("data_3D.js"), :, :, :)
trcs = readtrcs(jsopen("data_3D.js"), :, 1:2:end, 1:5)
```

# 4D:

```julia
trcs = readtrcs(jsopen("data_4D.js"), :, :, :, :)
trcs = readtrcs(jsopen("data_4D.js"), :, :, 2, 2:2:10)
```

# 5D:


```julia
trcs = readtrcs(jsopen("data_5D.js"), :, :, :, :, :)
trcs = readtrcs(jsopen("data_5D.js"), :, :, 2, 2:2:10, 1:10)
```
"""
function readtrcs(io::JSeis, rng::Vararg{Union{Int,AbstractRange{Int},Colon},N}) where N
    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    trcs = Array{Float32}(undef, length(smprng), length(trcrng), nrng...)
    readtrcs_impl!(io, trcs, smprng, trcrng, _rng...)
    trcs
end

"""
    readhdrs!(io, hdrs, smp_range, trace_range, range...)

In-place read of a subset of data (headers only) from a JavaSeis file. If performance is important, then consider using `readframehdrs!` instead.  Examples:

# 3D:

```julia
readhdrs!(jsopen("data_3D.js"), hdrs, :, :, :)
readhdrs!(jsopen("data_3D.js"), hdrs, :, 1:2:end, 1:5)
```

# 4D:

```julia
readhdrs!(jsopen("data_4D.js"), hdrs, :, :, :, :)
readhdrs!(jsopen("data_4D.js"), hdrs, :, :, 2, 2:2:10)
```

# 5D:


```julia
readhdrs!(jsopen("data_5D.js"), hdrs, :, :, :, :, :)
readhdrs!(jsopen("data_5D.js"), hdrs, :, :, 2, 2:2:10, 1:10)
```
"""
function readhdrs!(io::JSeis, hdrs::AbstractArray{UInt8}, rng::Vararg{Union{Int,AbstractRange{Int},Colon},N}) where N
    @assert rng[1] == Colon()
    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    @assert size(hdrs,1) == headerlength(io) && size(hdrs,2) == length(trcrng) && size(hdrs)[3:end] == nrng
    readhdrs_impl!(io, hdrs, trcrng, _rng...)
end

"""
    readhdrs(io, trace_range, range...)

Out-of-place read of a subset of data (headers only) from a JavaSeis file. Returns an array of trace data. If performance is important, then consider using `readframetrcs` instead.  Examples:

# 3D:

```julia
hdrs = readhdrs(jsopen("data_3D.js"), :, :, :)
hdrs = readhdrs(jsopen("data_3D.js"), :, 1:2:end, 1:5)
```

# 4D:

```julia
hdrs = readhdrs(jsopen("data_4D.js"), :, :, :, :)
hdrs = readhdrs(jsopen("data_4D.js"), :, :, 2, 2:2:10)
```

# 5D:

```julia
hdrs = readhdrs(jsopen("data_5D.js"), :, :, :, :, :)
hdrs = readhdrs(jsopen("data_5D.js"), :, :, 2, 2:2:10, 1:10)
```
"""
function readhdrs(io::JSeis, rng::Vararg{Union{Int,AbstractRange{Int},Colon},N}) where N
    @assert rng[1] == Colon()
    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    hdrs = Array{UInt8,N}(undef, headerlength(io), length(trcrng), nrng...)
    readhdrs_impl!(io, hdrs, trcrng, _rng...)
    hdrs
end

"""
    read!(io, trcs, sample_range, trace_range, range...)

In-place read of a subset of data from a JavaSeis file. If performance is important, then consider using `readframe!` instead.  Examples:

# 3D:

```julia
read!(jsopen("data_3D.js"), trcs, hdrs, :, :, :)
read!(jsopen("data_3D.js"), trcs, hdrs, :, 1:2:end, 1:5)
```

# 4D:

```julia
read!(jsopen("data_4D.js"), trcs, hdrs, :, :, :, :)
read!(jsopen("data_4D.js"), trcs, hdrs, :, :, 2, 2:2:10)
```

# 5D:

```julia
read!(jsopen("data_5D.js"), trcs, hdrs, :, :, :, :, :)
read!(jsopen("data_5D.js"), trcs, hdrs, :, :, 2, 2:2:10, 1:10)
```
"""
function read!(io::JSeis, trcs::AbstractArray{Float32}, hdrs::AbstractArray{UInt8}, rng::Vararg{Union{Int,AbstractRange{Int},Colon}, N}) where N
    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    @assert size(trcs)[1:2] == (length(smprng), length(trcrng)) && size(trcs)[3:end] == nrng
    @assert size(hdrs,1) == headerlength(io) && size(hdrs,2) == length(trcrng) && size(hdrs)[3:end] == nrng
    read_impl!(io, trcs, hdrs, smprng, trcrng, _rng...)
end

"""
    read(io, sample_range, trace_range, range...)

Out-of-place read of a subset of data from a JavaSeis file. Returns an array of trace data. If performance is important, then consider using `readframetrcs` instead.  Examples:

# 3D:

```julia
trcs, hdrs = read(jsopen("data_3D.js"), :, :, :)
trcs, hdrs = read(jsopen("data_3D.js"), :, 1:2:end, 1:5)
```

# 4D:

```julia
trcs, hdrs = read(jsopen("data_4D.js"), :, :, :, :)
trcs, hdrs = read(jsopen("data_4D.js"), :, :, 2, 2:2:10)
```

# 5D:

```julia
trcs, hdrs = read(jsopen("data_5D.js"), :, :, :, :, :)
trcs, hdrs = read(jsopen("data_5D.js"), :, :, 2, 2:2:10, 1:10)
```
"""
function read(io::JSeis, rng::Vararg{Union{Int,AbstractRange{Int},Colon},N}) where N
    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    trcs = Array{Float32}(undef, length(smprng), length(trcrng), nrng...)::Array{Float32,N}
    hdrs = Array{UInt8}(undef, headerlength(io), length(trcrng), nrng...)::Array{UInt8,N}
    read_impl!(io, trcs, hdrs, smprng, trcrng, _rng...)
    trcs, hdrs
end

function writeframe_impl(io::JSeis, trcs::AbstractArray{Float32,2}, hdrs::AbstractArray{UInt8,2}, fld::Int64, frm::Int64)
    hdrlen, trclen = headerlength(io), tracelength(io)

    # traces
    offset = (frm - 1) * trclen * io.axis_lengths[2]
    ext = extentindex(io.trcextents, offset)
    offset -= ext.start
    if io.dataformat == Float32
        localio = open(ext.path, "a")
        seek(localio, offset)
        unsafe_write(localio, convert(Ptr{UInt8}, pointer(trcs)), io.axis_lengths[1]*fld*sizeof(Float32))
        close(localio)
    elseif io.dataformat == Int16
        frmbuf = allocframebuf(io.compressor, fld)
        packframe!(io.compressor, frmbuf, trcs, fld)
        localio = open(ext.path, "a")
        seek(localio, offset)
        write(localio, frmbuf.data)
        close(localio)
    else
        error("unsupported data format")
    end

    # headers
    offset = (frm - 1) * hdrlen * io.axis_lengths[2]
    ext = extentindex(io.hdrextents, offset)
    offset -= ext.start
    localio = open(ext.path, "a")
    seek(localio, offset)
    unsafe_write(localio, pointer(hdrs), hdrlen*fld)
    close(localio)

    # tracemap
    fold!(io, frm, fld)

    # status
    if io.hastraces == false && fld > 0
        io.hastraces = true
        write_statusproperties(io)
    end

    return fld
end

"""
    writeframe(io, trcs, hdrs)

Write a frame of data to the JavaSeis dataset corresponding to `io::JSeis`.  `trcs` and `hdrs` are 2-dimensional arrays.
The location of the dataset written to is determined by the values of the framework headers stored in `hdrs`.
"""
writeframe(io::JSeis, trcs::AbstractArray{Float32, 2}, hdrs::AbstractArray{UInt8, 2}, fld::Int64) = writeframe_impl(io, trcs, hdrs, fld, sub2ind(io, hdrs))
writeframe(io::JSeis, trcs::AbstractArray{Float32, 2}, hdrs::AbstractArray{UInt8, 2}) = writeframe_impl(io, trcs, hdrs, fold(io,hdrs), sub2ind(io, hdrs))

writeframe(io::JSeis, trcs::AbstractArray{Float64, 2}, hdrs::AbstractArray{UInt8, 2}, fld::Int64) = writeframe(io, convert(Array{Float32, 2}, trcs), hdrs, fld)
writeframe(io::JSeis, trcs::AbstractArray{Float64, 2}, hdrs::AbstractArray{UInt8, 2}) = writeframe(io, convert(Array{Float32, 2}, trcs), hdrs)

"""
    writeframe(io, trcs, idx...)

Write a frame of data to the JavaSeis dataset corresponding to `io::JSeis`.  `trcs` is a 2-dimensional array.  The location
of the datset written to is determined by `idx...`.  For example:

# 3D:

```julia
writeframe(jsopen("data_3D.js"), trcs, 1) # write to frame 1
```

# 4D:

```julia
writeframe(jsopen("data_4D.js"), trcs, 1, 2) # write to frame 1, volume 2
```

# 5D:

```julia
writeframe(jsopen("data_5D.js"), trcs, 1, 2, 3) # write to frame 1, volume 2, hypercube 3
```
"""
function writeframe(io::JSeis, trcs::AbstractArray{Float32, 2}, idx::Int...)
    _wrongdims(io,idx) = length(idx) == ndims(io)-2 || error("Dimenions mismatch")
    hdrs = allocframehdrs(io)

    props = [prop(io, io.axis_propdefs[idim]) for idim = 1:ndims(io)]

    for i = 1:io.axis_lengths[2]
        set!(props[2], hdrs, i, Int(io.axis_lstarts[2] + (i-1)*io.axis_lincs[2]))
    end
    for idim = 3:ndims(io)
        for i = 1:io.axis_lengths[2]
            set!(props[idim], hdrs, i, idx[idim-2])
        end
    end
    proptt = prop(io, :TRC_TYPE, Int32)
    map(i->set!(proptt, hdrs, i, tracetype[:live]), 1:io.axis_lengths[2])
    writeframe_impl(io, trcs, hdrs, Int(io.axis_lengths[2]), sub2ind(io, idx))
end
writeframe(io::JSeis, trcs::AbstractArray{Float64, 2}, idx::Int...) = writeframe(io, convert(Array{Float32, 2}, trcs), idx...)
writeframe(io::JSeis, trcs::AbstractArray{Float32, 2}, idx::CartesianIndex) = writeframe(io, trcs, idx.I...)

"""
    write(io, trcs, hdrs[, smprng=:])

Write `trcs` and `hdrs` to the file corresponding to `io::JSeis`.  Optionally, you can limit which samples are written.
The locations that are written to are determined by the values corresponding to the framework headers `hdrs`.  Note that
the dimension of the arrays `trcs` and `hdrs` must match the number of dimensions in the framework.
"""
write(io::JSeis, trcs::AbstractArray{Float32}, hdrs::AbstractArray{UInt8}, smprng::Union{Colon,Int,AbstractRange{Int}}=:) = write_trcshdrs_helper(io, trcs, hdrs, smprng, ntuple(i->size(trcs,2+i), ndims(trcs)-2))
write(io::JSeis, trcs::AbstractArray{Float64}, hdrs::AbstractArray{UInt8}, smprng::Union{Colon,Int,AbstractRange{Int}}=:) = write(io, convert(Array{Float32}, trcs), hdrs, smprng)

function write_trcshdrs_helper(io::JSeis, trcs, hdrs, smprng, nrest::NTuple{N,Int}) where N
    ntrcs = size(trcs,2)
    hdrlen = headerlength(io)
    _smprng = parserng(io, smprng, 1)

    frmtrcs, frmhdrs = allocframe(io)
    trcprop = props(io, 2)
    frm_smprng = collect(io, _smprng, 1)

    for idx in CartesianIndices(nrest)
        if length(_smprng) != io.axis_lengths[1] || size(trcs,2) != io.axis_lengths[2]
            readframe_impl!(io, frmtrcs, frmhdrs, sub2ind(io, @view(hdrs[:,:,idx.I...])))
            regularize!(io, frmtrcs, frmhdrs)
        end
        for itrc = 1:ntrcs
            itrc_frm = div(get(trcprop, @view(hdrs[:,itrc,idx.I...])) - io.axis_lstarts[2], io.axis_lincs[2]) + 1
            for (ismp,smp) in enumerate(frm_smprng)
                frmtrcs[smp,itrc_frm] = trcs[ismp,itrc,idx]
            end
            for ismp = 1:hdrlen
                frmhdrs[ismp,itrc_frm] = hdrs[ismp,itrc,idx]
            end
        end
        leftjustify!(io, frmtrcs, frmhdrs)
        writeframe(io, frmtrcs, frmhdrs)
    end
end

"""
    write(io, trcs, sample_range, trace_range, range...)

Write trcs to the JavaSeis file corresponding to `io::JSeis`.  the dimension of `trcs` must be the same as
the dimension of `io`, and the size of each dimension corresponds to `range`.  Examples:

# 3D:

```julia
write(io, trcs, :, :, :)
```

# 4D:

```julia
write(io, trcs, :, :, :, :)
```

# 5D:

```julia
write(io, trcs, :, :, :, :, :)
```
"""
function write(io::JSeis, trcs::AbstractArray{Float32}, rng::Vararg{Union{Colon,Int,AbstractRange{Int}},N}) where N
    @assert ndims(trcs) == length(rng)

    smprng, trcrng, _rng, nrng = parserngs(io, rng...)
    @assert size(trcs,1) == length(smprng)
    @assert size(trcs,2) == length(trcrng)
    for i = 1:length(_rng)
        @assert size(trcs,2+i) == length(_rng[i])
    end

    frmtrcs = allocframetrcs(io)
    frm_smprng = collect(io, smprng, 1)
    frm_trcrng = collect(io, trcrng, 2)

    write_helper(io, trcs, frmtrcs, frm_smprng, frm_trcrng, smprng, nrng, _rng) # split-out to help type inference
end
write(io::JSeis, trcs::AbstractArray{Float64}, smprng::Union{Colon,Int,AbstractRange{Int}}, trcrng::Union{Colon,Int,AbstractRange{Int}}, rng::Union{Colon,Int,AbstractRange{Int}}...) = write(io, convert(Array{Float32}, trcs), smprng, trcrng, rng...)

function write_helper(io::JSeis, trcs, frmtrcs, frm_smprng, frm_trcrng, smprng, nrng, _rng::NTuple{N,StepRange{Int,Int}}) where N
    n = ntuple(i->length(_rng[i]), N)::NTuple{N,Int}

    frmhdrs = allocframehdrs(io)
    prop_trctype = prop(io, stockprop[:TRC_TYPE])
    map(itrace->set!(prop_trctype, frmhdrs, itrace, tracetype[:live]), 1:size(io,2))

    for idx_n in CartesianIndices(n)
        idx = parseindex(_rng, idx_n)
        if length(smprng) != io.axis_lengths[1] || size(trcs,2) != io.axis_lengths[2]
            readframetrcs_impl!(io, frmtrcs, sub2ind(io,idx))
        end
        for (itrc,trc) in enumerate(frm_trcrng), (ismp,smp) in enumerate(frm_smprng)
            frmtrcs[smp,trc] = trcs[ismp,itrc,idx_n]
        end

        for itrace = 1:io.axis_lengths[2]
            set!(props(io,2), frmhdrs, itrace, lstarts(io,2) + (itrace-1)*lincs(io,2))
            for idim = 3:ndims(io)
                set!(props(io,idim), frmhdrs, itrace, idx[idim-2])
            end
        end
        writeframe(io, frmtrcs, frmhdrs)
    end
end

function sub2ind(io::JSeis, idx::NTuple)
    n = length(idx)

    @assert n == length(io.axis_lengths) - 2
    for i = 1:length(idx)
        @assert io.axis_lstarts[2+i] <= idx[i] <= io.axis_lstarts[2+i] + io.axis_lincs[2+i] * (io.axis_lengths[2+i] - 1)
    end

    idx_lin, idx_mod = divrem(idx[1] - io.axis_lstarts[3], io.axis_lincs[3])
    @assert idx_mod == 0
    idx_lin += 1

    for i=2:n
        idx_lin_i, idx_mod = divrem(idx[i] - io.axis_lstarts[2+i], io.axis_lincs[2+i])
        @assert idx_mod == 0
        idx_lin += idx_lin_i * prod(io.axis_lengths[3:1+i])
    end
    return idx_lin
end
function sub2ind(io::JSeis, hdrs::AbstractArray{UInt8,2})
    ptrctype = prop(io, stockprop[:TRC_TYPE])
    props = [prop(io, io.axis_propdefs[i]) for i=3:ndims(io)]
    for itrc = 1:size(hdrs,2)
        if get(ptrctype, hdrs, itrc) == tracetype[:live]
            idx = ntuple(i->get(props[i], hdrs, itrc), length(io.axis_lengths) - 2)
            return sub2ind(io, idx)
        end
    end
    error("attempting to determine frame index in frame with no live traces.")
end
sub2ind(io::JSeis, idx::CartesianIndex) = sub2ind(io, idx.I)

"""
    ind2sub(io, i)

Return the (frame,volume...) tuple for the liner index `i`.  This is useful for
looping over all frames in a data-set that is more that 4 or more dimensions. For
example,

```julia
for i = 1:length(io)
    trcs, hdrs = readframe(io, ind2sub(io,i)...)
end
```
"""
function ind2sub(io::JSeis, i::Int)
    idx = Tuple(CartesianIndices(size(io)[3:end]))[i]
    return ntuple(i->io.axis_lstarts[2+i] + (idx[i] - 1) * io.axis_lincs[2+i], length(idx))
end

"""
    leftjustify(io, trcs, hdrs)

Left justify all live (non-dead) traces in a frame, moving them to the beginning
of `trcs` and `hdrs`.  See also `regularize!`
"""
function leftjustify!(io::JSeis, trcs::Array{Float32, 2}, hdrs::Array{UInt8, 2})
    if fold(io, hdrs) == io.axis_lengths[2]
        return
    end
    proptyp = prop(io, stockprop[:TRC_TYPE])
    j, ntrcs, nsamp, nhead = 1, size(trcs, 2), size(trcs,1), size(hdrs,1)
    tmp_trc, tmp_hdr = Array{Float32}(undef, size(io,1)), Array{UInt8}(undef, headerlength(io))
    for i = 1:ntrcs
        if get(proptyp, hdrs, i) != tracetype[:live]
            for j = i+1:ntrcs
                if get(proptyp, hdrs, j) == tracetype[:live]
                    for k = 1:nsamp
                        tmp = trcs[k,i]
                        trcs[k,i] = trcs[k,j]
                        trcs[k,j] = tmp
                    end

                    for k = 1:nhead
                        tmp = hdrs[k,i]
                        hdrs[k,i] = hdrs[k,j]
                        hdrs[k,j] = tmp
                    end
                    break
                end
            end
        end
    end
end

function regularize!(io::JSeis, trcs::Array{Float32, 2}, hdrs::Array{UInt8, 2}, trcpropdef::TracePropertyDef)
    if in(trcpropdef, io.properties) == false
        error("regularize!: $(trcpropdef.label) is not an existing trace property.")
    end
    fld = fold(io, hdrs)
    if fld == io.axis_lengths[2]
        return
    end
    nsamp, nhead, ntrcs = size(trcs,1), size(hdrs,1), size(trcs,2)
    proptrc, proptyp = prop(io, trcpropdef), prop(io, stockprop[:TRC_TYPE])
    trace_mask = zeros(Int32, ntrcs)
    for i = fld:-1:1
        ii = div(get(proptrc, hdrs, i) - io.axis_lstarts[2], io.axis_lincs[2]) + 1
        trace_mask[ii] = 1
        for j = 1:nsamp
            trcs[j,ii] = trcs[j,i]
        end
        for j = 1:nhead
            hdrs[j,ii] = hdrs[j,i]
        end
    end
    for i = 1:ntrcs
        if trace_mask[i] == 0
            set!(proptrc, hdrs, i, i)
            set!(proptyp, hdrs, i, tracetype[:dead])
            trcs[:,i] .= 0.0
        end
    end
end
"""
    regularize!(io, trcs, hdrs)

Regularize the traces in a frame, moving them from their left-justified state, to one
that reflects their trace location within a frame according to their trace framework definition.
"""
regularize!(io::JSeis, trcs::Array{Float32, 2}, hdrs::Array{UInt8, 2}) = regularize!(io, trcs, hdrs, io.axis_propdefs[2])

function regularize!(io::JSeis, hdrs::Array{UInt8, 2}, trcpropdef::TracePropertyDef)
    if in(trcpropdef, io.properties) == false
        error("regularize!: $(trcpropdef.label) is not an existing trace property.")
    end
    fld = fold(io, hdrs)
    if fld == io.axis_lengths[2]
        return
    end
    nhead, ntrcs = size(hdrs,1), size(hdrs,2)
    proptrc, proptyp = prop(io, trcpropdef), prop(io, stockprop[:TRC_TYPE])
    trace_mask = zeros(Int32, ntrcs)
    for i = fld:-1:1
        ii = div(get(proptrc, hdrs, i) - io.axis_lstarts[2], io.axis_lincs[2]) + 1
        trace_mask[ii] = 1
        for j = 1:nhead
            hdrs[j,ii] = hdrs[j,i]
        end
    end
    for i = 1:ntrcs
        if trace_mask[i] == 0
            set!(proptrc, hdrs, i, i)
            set!(proptyp, hdrs, i, tracetype[:dead])
        end
    end
end
regularize!(io::JSeis, hdrs::Array{UInt8, 2}) = regularize!(io, hdrs, io.axis_propdefs[2])

tracelength(io::JSeis) = tracelength(io.compressor)

# convenience methods
"""
    ndims(io)

Returns the numbers of dimensions of the JavaSeis dataset corresponding to `io::JSeis`.
"""
ndims(io::JSeis) = length(io.axis_lengths)
"""
    size(io)

Returns the lenths of all dimensions (as a tuple of integers) of a JavaSeis dataset corresponding to `io::JSeis`.
"""
size(io::JSeis) = ntuple(i->Int(io.axis_lengths[i]), ndims(io))
"""
    size(io, i)

Returns the lenth of dimension i of a JavaSeis dataset corresponding to `io::JSeis`.
"""
size(io::JSeis, i::Int) = io.axis_lengths[i]
"""
    length(io)

Returns the number of frames in a JavaSeis dataset corresponding to `io::JSeis`.
This is equivalent to `prod(size(io)[3:end])`, and is useful for iterating over
all frames in a JavaSeis dataset.
"""
length(io::JSeis) = prod(io.axis_lengths[3:end])
"""
    labels(io)

Returns the string labels corresponding to the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
labels(io::JSeis) = ntuple(i->io.axis_propdefs[i].label, ndims(io))
"""
    labels(io, i)

Returns the string label of the ith framework axis of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
labels(io::JSeis, i::Int) = io.axis_propdefs[i].label
"""
    propdefs(io)

Returns the property definitions of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
propdefs(io::JSeis) = ntuple(i->io.axis_propdefs[i], ndims(io))
"""
    propdefs(io, i)

Returns the property definition of the ith framework axis of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
propdefs(io::JSeis, i::Int) = io.axis_propdefs[i]
"""
    props(io)

Returns the trace properties of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
props(io::JSeis) = ntuple(i->prop(io, io.axis_propdefs[i]), ndims(io))
"""
    props(io, i)

Returns the trace property of the ith framework axis of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
props(io::JSeis, i::Int) = prop(io, io.axis_propdefs[i])
"""
    units(io)

Returns the unit of measure of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
units(io::JSeis) = ntuple(i->io.axis_units[i], ndims(io))
"""
    units(io, i)

Returns the unit of measure of the ith dimension of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
units(io::JSeis, i::Int) = io.axis_units[i]
"""
    domains(io)

Returns the domains of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
domains(io::JSeis) = ntuple(i->io.axis_domains[i], ndims(io))
"""
    domains(io, i)

Returns the domain of the ith dimension of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
domains(io::JSeis, i::Int) = io.axis_domains[i]
"""
    pstarts(io)

Returns the physical start of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
pstarts(io::JSeis) = ntuple(i->io.axis_pstarts[i], ndims(io))
"""
    pstarts(io, i)

Returns the physical start of the ith dimension of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
pstarts(io::JSeis, i::Int) = io.axis_pstarts[i]
"""
    pincs(io)

Returns the physical increments of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
pincs(io::JSeis) = ntuple(i->io.axis_pincs[i], ndims(io))
"""
    pincs(io, i)

Returns the physical increments of the framework axes for dimension `i` of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
pincs(io::JSeis, i::Int) = io.axis_pincs[i]
"""
    lstarts(io)

Returns the logical start of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
lstarts(io::JSeis) = ntuple(i->io.axis_lstarts[i], ndims(io))
"""
    lstarts(io,i)

Returns the logical start of the framework axes for dimension `i` of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
lstarts(io::JSeis, i::Int) = io.axis_lstarts[i]
"""
    lincs(io)

Returns the logical increments of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
lincs(io::JSeis) = ntuple(i->io.axis_lincs[i], ndims(io))
"""
    lincs(io,i)

Returns the logical increment of the framework axes for dimension `i` of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
lincs(io::JSeis, i::Int) = io.axis_lincs[i]
"""
    lrange(io)

Returns the logical ranges of the framework axes of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
lrange(io::JSeis) = ntuple(i->range(io.axis_lstarts[i], step=io.axis_lincs[i], length=io.axis_lengths[i]), ndims(io))
"""
    lrange(io, i)

Returns the logical range of the framework axes for dimension `i` of the JavaSeis dataset corresponding
to `io::JSeis`.
"""
lrange(io::JSeis, i::Int) = range(io.axis_lstarts[i], step=io.axis_lincs[i], length=io.axis_lengths[i])
"""
    isempty(io)

Returns true if the dataset correpsonding to `io` is empty (contains no data), and false
otherwise.
"""
isempty(io::JSeis) = !io.hastraces
"""
    in(trace_property, io)

Returns true if `trace_property` is in the header catalog of `io::JSeis`, and where `trace_property`
is one of `String`, `TracePropertyDef` or `TraceProperty`.
"""
in(prop::Union{String, TracePropertyDef, TraceProperty},  io::JSeis) = in(prop, io.properties)

"""
    geometry(io)

If `io::JSeis` contains a geometry definition, then return a geometry of type `Geometry`.  Otherwise,
return `nothing`.
"""
geometry(io::JSeis) = io.geom
