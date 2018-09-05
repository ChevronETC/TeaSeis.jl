module TeaSeis

using Dates, LightXML

import
Base.==,
Base.collect,
Base.copy,
Base.copy!,
Base.close,
Base.empty!,
Base.get,
Base.in,
Base.isempty,
Base.length,
Base.ndims,
Base.read,
Base.read!,
Base.sizeof,
Base.write,
Base.size,
Base.show,
Base.cp,
Base.mv,
Base.rm

if VERSION < v"1.0.0"
    import Base.ind2sub, Base.sub2ind
end

include("traceproperty.jl")
include("dataproperty.jl")
include("stockprops.jl")
include("compat.jl")
include("geometry.jl")
include("extent.jl")
include("tracecompressor.jl")
include("teaseisio.jl")

export
DataProperty,
Geometry,
JSeis,
TracePropertyDef,
dataproperty,
geometry,
hasdataproperty,
jsopen,
jscreate,
labels,
props,
propdefs,
label,
description,
format,
elementcount,
units,
domains,
pstarts,
pincs,
lstarts,
lincs,
lrange,
allocframe,
allocframetrcs,
allocframehdrs,
readframe,
readframe!,
readframetrcs,
readframetrcs!,
readframehdrs,
readframehdrs!,
readhdrs,
readhdrs!,
readtrcs,
readtrcs!,
writeframe,
prop,
propdef,
set!,
headerlength,
fold,
stockprop,
stockdomain,
stockunit,
stockdatatype,
tracetype,
leftjustify!,
regularize!

if VERSION >= v"1.0.0"
    export ind2sub, sub2ind
end

end
