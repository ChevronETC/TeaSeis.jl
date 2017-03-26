
[![Build Status](https://travis-ci.org/ChevronETC/TeaSeis.jl.svg?branch=master)](https://travis-ci.org/ChevronETC/TeaSeis.jl) [![Coverage Status](https://coveralls.io/repos/github/ChevronETC/TeaSeis.jl/badge.svg?branch=master)](https://coveralls.io/github/ChevronETC/TeaSeis.jl?branch=master)


<h1>TeaSeis.jl</h1> TeaSeis.jl is a Julia library for reading and writing JavaSeis files (The name `TeaSeis.jl` was chosen instead of `JavaSeis.jl` due to potential trademark issues).  The JavaSeis file format is used in various software projects including [SeisSpace](https://www.landmark.solutions/seisspace-promax).  The original library is written in [Java](http://sourceforge.net/projects/javaseis).  There are also [C++](http://www.jseisio.com) and [Python](https://github.com/asbjorn/pyjavaseis) implementations available.  Similar to the C++ library, TeaSeis.jl is a stripped down version of the original Java library.  In particular, the intent is to only supply methods for reading and writing from and to JavaSeis files.

- [Trademarks](README.md#Trademarks-1)
- [License and copyright](README.md#License-and-copyright-1)
- [Dependencies](README.md#Dependencies-1)
- [Obtaining TeaSeis.jl](README.md#Obtaining-TeaSeis.jl-1)
- [Using TeaSeis.jl](README.md#Using-TeaSeis.jl-1)
    - [Quick start guide](README.md#Quick-start-guide-1)
    - [writing](README.md#writing-1)
    - [reading](README.md#reading-1)
- [jsopen / jscreate](README.md#jsopen-/-jscreate-1)
- [Available options when creating a new JavaSeis file](README.md#Available-options-when-creating-a-new-JavaSeis-file-1)
- [Read/write methods](README.md#Read/write-methods-1)
    - [Alternative read/write methods (N-Dimensional slices)](README.md#Alternative-read/write-methods-(N-Dimensional-slices)-1)
    - [Alternative write methods for full frames](README.md#Alternative-write-methods-for-full-frames-1)
- [Trace Properties](README.md#Trace-Properties-1)
    - [TRC_TYPE](README.md#TRC_TYPE-1)
- [Data properties](README.md#Data-properties-1)
- [Secondaries](README.md#Secondaries-1)
- [Geometry](README.md#Geometry-1)
- [Convenience methods and dictionaries](README.md#Convenience-methods-and-dictionaries-1)
- [API](README.md#API-1)


<a id='Trademarks-1'></a>

# Trademarks


  * SEISSPACE and PROMAX are registered trademarks of LANDMARK GRAPHICS CORPORATION
  * Java is a registred trademark of Oracle


<a id='License-and-copyright-1'></a>

# License and copyright


The License and copyright information can be found in the source distribution: `LICENSE.txt`, `COPYRIGHT.txt`


<a id='Dependencies-1'></a>

# Dependencies


TeaSeis.jl depends on the [LightXML.jl](http://www.github.com/lindahua/LightXML.jl) package.


<a id='Obtaining-TeaSeis.jl-1'></a>

# Obtaining TeaSeis.jl


```
Pkg.add("TeaSeis")
```


<a id='Using-TeaSeis.jl-1'></a>

# Using TeaSeis.jl


<a id='Quick-start-guide-1'></a>

## Quick start guide


First, load  the TeaSeis.jl library:


```julia
using TeaSeis
```


<a id='writing-1'></a>

## writing


  * Create a new JavaSeis file with a 3D framework (128 samples per trace, 32 traces per frame, and 16 frames per volume):


```julia
io = jsopen("filename.js", "w", axis_lengths=[128, 32, 16])
```


Note that by default, `SAMPLE`, `TRACE`, and `FRAME` will be the axes properties.


  * Allocate traces and headers for a single frame:


```julia
trcs, hdrs = allocframe(io)
```


  * Populate `trcs`, and `hdrs` with values.  For example, write random values to all traces in the first frame:


```julia
map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live]), 1:size(io,2))
map(i->set!(prop(io, stockprop[:TRACE]   ), hdrs, i, i               ), 1:size(io,2))
map(i->set!(prop(io, stockprop[:FRAME]   ), hdrs, i, 1               ), 1:size(io,2))
rand!(trcs)
writeframe(io, trcs, hdrs)
```


  * Close the file


```julia
close(io)
```


<a id='reading-1'></a>

## reading


  * Open a new JavaSeis file from an existing dataset:


```julia
io = jsopen("filename.js", "r")
```


  * Read the first frame:


```julia
trcs, hdrs = readframe(io, 1)
```


or a similar in-place version:


```julia
trcs, hdrs = allocframe(io)
readframe!(io, trcs, hdrs, 1)
```


  * Access values stored in a trace property for the first trace in the frame:


```julia
get(prop(io, stockprop[:TRACE]), hdrs, 1)
```


or, slightly less efficient:


```julia
get(prop(io, stockprop[:TRACE]), hdrs[:,1])
```


  * Close the file


```julia
close(io)
```


<a id='jsopen-/-jscreate-1'></a>

# jsopen / jscreate


A JavaSeis dataset is created/opened with the `jsopen` method which returns a `JSeis`. A JavaSeis dataset must have a minimum of 3 dimensions.  


Create a 3D JavaSeis file with 10 samples per trace, 11 traces per frame, and 12 frames per volume:


```julia
io = jsopen("file.js", "w", axis_lengths=[10,11,12])
```


Open an existing JavaSeis file in read-only mode:


```julia
io = jsopen("file.js", "r")
io = jsopen("file.js")      # equivalent to previous line
```


Open an existing JavaSeis file for reading and writing:


```julia
io = jsopen("file.js", "r+")
```


To close an open dataset:


```julia
close(io)
```


To create a dataset:


```julia
jscreate("file.js", axis_lengths=[10,11,12])
```


This is useful for when you need to create the data-set on the master process, and write to it on worker processes.


<a id='Available-options-when-creating-a-new-JavaSeis-file-1'></a>

# Available options when creating a new JavaSeis file


The `jscreate` and, when operating in write `"w"` mode, `jsopen` functions take the following named optional arguments:


  * `similarto::String`<br>


An existing JavaSeis dataset.  If set, then all other named arguments can be used to modify the data context that belongs to the existing JavaSeis dataset.


  * `description::String`<br>


Description of dataset, if not set, then a description is parsed from the filename.


  * `mapped::Bool`<br>


If the dataset is full (no missing frames/traces), then it may be more efficient to set this to `false`.  Defaults to `true`.


  * `nextents::Int`<br>


The number of file-extents used to store the data.  If not set, then a heuristic is used to choose the number of extents.


  * `secondaries::Array{String, 1}`<br>


An array of file-system locations used to store the file extents.  If not set, then *primary* storage is used.


  * `datatype::String`<br>


Examples are `CMP`, `SHOT`, etc.  If not set, then `UNKNOWN` is used.


  * `dataformat::Type`<br>


Choose from `Float32`, and `Int16`.  If not set, then `Float32` is used.


  * `dataorder::String`<br>


(not supported)


  * `axis_propdefs::Array{TracePropertyDef, 1}`<br>


Trace properties corresponding to JavaSeis axes.  If not set, then `SAMPLE`, `TRACE`, `FRAME`, `VOLUME` and `HYPRCUBE` are used.


  * `axis_units::Array{String, 1}`<br>


Units corresponding to JavaSeis axes. e.g. `SECONDS`, `METERS`, etc.  If not set, then `UNKNOWN` is used.


  * `axis_domains::Array{String, 1}`<br>


Domains corresponding to JavaSeis axes. e.g. `SPACE`, `TIME`, etc.  If not set, then `UNKNOWN` is used.


  * `axis_lstarts::Array{Int32, 1}`<br>


Logical origins for each axis.  If not set, then `1` is used for the logical origin of each axis.


  * `axis_lincs::Array{Int32, 1}`<br>


Logical increments for each axis.  If not set, then `1` is used for the logical increments of each axis.


  * `axis_pstarts::Array{Float64, 1}`<br>


Physical origins for each axis.  If not set, then `0.0` is used for the physical origin of each axis.


  * `axis_pincs::Array{Float64, 1}`<br>


Physical increments for each axis.  If not set, then `1.0` is used for the physical increments of each axis.


  * `properties::Array{TracePropertyDef, 1}`<br>


An array of custom trace properties.  These are in addition to a minimal set of trace properties listed in the ProMax manual.


  * `dataproperties::Array{DataProperty, 1}`<br>


An array of custom data properties.  One property per data-set rather than one property per trace as in `properties` above.


  * `geom::Geometry`<br>


An optional three point geometry can be embedded in the JavaSeis file.


  * `properties_add::Array{TracePropertyDef}`


When `similarto` is specified, use this to add trace properties to those already existing in the `similarto` file.


  * `properties_rm::Array{TracePropertyDef}`


When `similarto` is specified, use this to remove trace properties to those already existing in the `similarto` file.


  * `dataproperties_add::Array{DataProperty}`


When `similarto` is specfied, use this to add dataset properties to those aloready existing in the `similarto` file.


  * `dataproperties_rm::Array{DataProperty}`


When `similarto` is specified, use this to remove dataset properties to those already existing in the `similarto` file.


For example:


```julia
io = jsopen("file.js", "w", axis_lengths=[10,11,12], dataformat=Float16, axis_pincs=[0.004,10.0,20.0])
```


<a id='Read/write-methods-1'></a>

# Read/write methods


JavaSeis is a frame based file format.


For `io::JSeis`, allocate memory for a single frame:


```julia
trcs, hdrs = allocframe(io) # allocate memory for traces and headers for a single frame
trcs = allocframetrcs(io)   # allocate memory for traces for a single frame
hdrs = allocframehdrs(io)   # allocate memory for headers for a single frame
```


Read a frame. `ifrm::Int`, `ivol::Int`, `ihyp::Int` and `i6::Int` must be consistent with the JavaSeis data context.


```julia
trcs, hdrs = readframe(io, ifrm)                 # read from 3D data
trcs, hdrs = readframe(io, ifrm, ivol)           # read from 4D data
trcs, hdrs = readframe(io, ifrm, ivol, ihyp)     # read from 5D data
trcs, hdrs = readframe(io, ifrm, ivol, ihyp, i6) # read from 6D data
...
```


Read a frame (in-place) using pre-allocated memory:


```julia
ifrm = 1
readframe!(io, trcs, hdrs, ifrm)                # read from 3D data
readframe!(io, trcs, hdrs, ifrm, ivol)          # read from 4D data
readframe!(io, trcs, hdrs, ifrm, ivol, ihyp)    # read from 5D data
readframe!(io, trcs, hdrs, ifrm, ivol, ihyp, i6) # read from 6D data
...
```


Note that `readframe!` methods returns the <b>fold</b> (number of live traces in the frame).


Similar methods exist for reading only headers:


```julia
ifrm = 1
hdrs = readframehdrs(io, ifrm)                 # read from 3D data
hdrs = readframehdrs(io, ifrm, ivol)           # read from 4D data
hdrs = readframehdrs(io, ifrm, ivol, ihyp)     # read from 5D data
hdrs = readframehdrs(io, ifrm, ivol, ihyp, i6) # read from 6D data
...
readframehdrs!(io, hdrs, ifrm)                 # in-place read from 3D data
readframehdrs!(io, hdrs, ifrm, ivol)           # in-place read from 4D data
readframehdrs!(io, hdrs, ifrm, ivol, ihyp)     # in-place read from 5D data
readframehdrs!(io, hdrs, ifrm, ivol, ihyp, i6) # in-place read from 6D data
...
```


or only traces:


```julia
ifrm = 1
trcs = readframetrcs(io, ifrm)                 # read from 3D data
trcs = readframetrcs(io, ifrm, ivol)           # read from 4D data
trcs = readframetrcs(io, ifrm, ivol, ihyp)     # read from 5D data
trcs = readframetrcs(io, ifrm, ivol, ihyp, i6) # read from 6D data
...
readframetrcs!(io, trcs, ifrm)                 # in-place read from 3D data
readframetrcs!(io, trcs, ifrm, ivol)           # in-place read from 4D data
readframetrcs!(io, trcs, ifrm, ivol, ihyp)     # in-place read from 5D data
readframetrcs!(io, trcs, ifrm, ivol, ihyp, i6) # in-place read from 6D data
...
```


Write a frame. The frame, volume, and hypercube indices are determined from the trace properties (`hdrs::Array{UInt8,2}`)


```julia
writeframe(io, trcs, hdrs)
```


To loop over all frames in a dataset of arbitrary dimension, TeaSeis.jl provides an iterator-type API:


```julia
for i=1:length(io)
    trcs, hdrs = readframe(io, ind2sub(io,i)...)
end
```


where `length(io)` is the number of frames in `io`, `ind2sub` converts the linear index `i` into n-tuple indexing dimensions 3 and higher.  Of course, this can also be used with `readframe!`, `readframetrcs`, `readframetrcs!`, `readframehdrs` and `readframehdrs!`.


<h3> IMPORTANT NOTE: </h3>


It is <b>very</b> important to note that the JavaSeis format left-justifies all live traces in a frame.  This makes reading and writing data more efficient. However, if you are reading or writing non-full frames, extra care must be taken.  Two methods (`leftjustify!` and `regularize!`) are provided to help with this situation.


Writing a non-full frame:


```julia
leftjustify!(io, trcs, hdrs)
writeframe(io, trcs, hdrs)
```


Reading a non-full frame:


```julia
readframe!(io, trcs, hdrs, 1)
regularize!(io, trcs, hdrs)
regularize!(io, trcs, hdrs, stockprop[:TRACE]) # used when the trace label does not correspond to a trace property
```


Please note that the regularize method sets the `:TRC_TYPE` property appropriately.  That is, a padded trace is of `tracetype[:dead]`.


Methods for finding the fold of a frame:


```julia
fold(io, hdrs)                 # get fold by examining the headers `hdrs` from a frame
fold(io, ifrm)                 # get fold from a 3D data set using the JavaSeis `TraceMap` file
fold(io, ifrm, ivol)           # get fold from a 4D data set using the JavaSeis `TraceMap` file
fold(io, ifrm, ivol, ihyp)     # get fold from a 5D data set using the JavaSeis `TraceMap` file
fold(io, ifrm, ivol, ihyp, i6) # get fold from a 6D data set using the JavaSeis `TraceMap` file
...
```


<a id='Alternative-read/write-methods-(N-Dimensional-slices)-1'></a>

## Alternative read/write methods (N-Dimensional slices)


We supply convenience methods for reading and writing arbitrary patches of data.  If frames are not full, then the read algorithms include automatic regularization of the frames, and the write algorithms include automatic left justification.  In turn, this means that the convenience of the following methods may come at the expense of extra I/O operations.  This is especially true for JavaSeis datasets that are of 6 or more dimensions.


**Reading:**


```julia
trcs, hdrs = read(io, 1:10, 2:3, 4)              # read from 3D data (frame 4, traces 2-3, and time samples 1-10)
trcs, hdrs = read(io, 1:10, 2:3, 4, :)           # read from 4D data (all volumes, frame 4, traces 2-3, and time samples 1-10)
trcs, hdrs = read(io, 1:10, 2:3, 4, :, 2:2:4)    # read from 5D data (Hypercubes 2 and 4, all volumes, frame 4, traces 2-3 and time samples 1-10)
trcs, hdrs = read(io, 1:10, 2:3, 4, :, 2:2:4, 1) # read from 6D data (element 1 from the 6th dimension, hypercubes 2 and 4, all volumnes, frame 4, traces 2-3 and time samples 1-10)
...
read!(io, trcs, hdrs, 1:10, 2:3, 4)              # in-place read from 3D data
read!(io, trcs, hdrs, 1:10, 2:3, 4, :)           # in-place read from 4D data
read!(io, trcs, hdrs, 1:10, 2:3, 4, :, 2:2:4)    # in-place read from 5D data
read!(io, trcs, hdrs, 1:10, 2:3, 4, :, 2:2:4, 1) # in-place read from 6D data
...
```


Similar methods exist for reading only traces (for example):


```julia
trcs = readtrcs(io, 1:10, 2:3, 4)
readtrcs!(io, trcs, 1:10, 2:3, 4) # in-place version of previous line
```


and only headers (for example):


```julia
hdrs = readhdrs(io, 2:3, 4)
readhdrs!(io, hdrs, 2:3, 4) # in-place version of previous line//
```


Note that when using `readhdrs` and `readhdrs!` one does not specify a slice range for the first dimension.


**Writing:**


```julia
write(io, trcs, hdrs)       # trcs::Array{Float32,N}, hdrs::Array{Float32,N} where N is either 3,4 or 5.
write(io, trcs, hdrs, 1:10) # same as previous except only time samples 1:10 are written.
```


In the above listing, the locations that are written to are determined by the header values.


<a id='Alternative-write-methods-for-full-frames-1'></a>

## Alternative write methods for full frames


it is sometimes not convenient to set headers before writing full frames.  This might be true when, for example, one is doing research work where geometry (and other) information does not need to be stored in trace headers.  For this scenario, we provide two sets of alternative API.


The first set of API is for writing one frame at a time:


```julia
writeframe(io, trcs, ifrm)                 # write to 3D data
writeframe(io, trcs, ifrm, ivol)           # write to 4D data
writeframe(io, trcs, ifrm, ivol, ihyp)     # write to 5D data
writeframe(io, trcs, ifrm, ivol, ihyp, i6) # write to 6D data
...
```


The second set of API is for writing arbitrary N-dimensional slices of data:


```julia
write(io, trcs, :, 1:10, 3:2:5)            # write to 3D data, all samples; traces 1-10; frames 3, 5
write(io, trcs, :, 1:10, 3:2:5, 6)         # write to 4D data, all samples; traces 1-10; frames 3, 5; volume 6
write(io, trcs, :, 1:10, 3:2:5, 6, :)      # write to 5D data, all samples; traces 1-10; frames 3, 5; volume 6, all hypercubes
write(io, trcs, :, 1:10, 3:2:5, 6, :, 1:2) # write to 6D data, all samples; traces 1-10; frames 3, 5; volume 6, all hypercubes, elements 1 and 2 from dimension 6
...
```


Please note that in these forms, the writeframe and write methods will create headers for you, and populate the `:TRC_TYPE` property along with the properties corresponding to the trace and frame axes of your data.  In the case of 4D data, the volume property is also populated, and in the case of 5D data, the volume and hypercube properties are also populated.


In addition, please note that in the `write` method, `trcs` must have the same number of dimensions as `io`.  In practice this can be accomplished using `reshape`.  For example if `size(io)=(10,20,3)` and `size(trcs)=(10,)`, then to write `trcs` to the first trace of the first frame of `io` one could write:


```julia
write(io, rehsape(trcs, 10, 1, 1), :, 1, 1)
```


<a id='Trace-Properties-1'></a>

# Trace Properties


The JavaSeis data format does not specify any trace properties.  However, there are commonly used (<b>stock</b>) properties (listed in [STOCKPROPS.md](STOCKPROPS.md), as well as a minimal set of properties that are expected by SeisSpace (listed in [SSPROPS.md](SSPROPS.md)).  It is unusual when a stock property does not suit your needs.  But, if need be, you can define a custom property using the `TracePropertyDef` constructor:


```julia
pdef = TracePropertyDef("label", "description", Float32, 1)
```


The arguments to `TracePropertyDef` are the <b>label</b>, <b>description</b>, <b>type</b>, and the <b>number of elements</b> stored in the property. The stock properties are defined in [src/stockprops.jl](src/stockprops.jl) using a Julia dictionary: `stockprop`.  For example, access a stock definition for the `TRACE` property:


```julia
pdef = stockprop[:TRACE]
```


Given a JavaSeis file `io::JSeis` and a stock definition, we can access the corresponding property of a JavaSeis file:


```julia
p = prop(io, pdef)    # access using a `TracePropertyDef`
p = prop(io, "TRACE") # alternatively, access using the trace property definition label
```


Given, additionally, a frame of headers `hdrs::Array{UInt8,2}`, we can get and set the values stored in a property:


```julia
@show get(p, hdrs[:,1])
@show get(p, hdrs, 1)      # equivalent to the previous line of code
set!(p, hdrs, 1, 5)        # set the first header in `hdrs` to 5
writeframe(io, trcs, hdrs) # the JavaSeis file does not know about the updated header until you call `writeframe`
```


In the above code listing `trcs` is of type `Array{Float32,2}`.


<a id='TRC_TYPE-1'></a>

## TRC_TYPE


The `TRC_TYPE` property is used to indicate if a trace is dead, live or auxiliary within any given frame.  It is stored as an `Int32`.  We provide a second dictionary to map between the `Int32` and human readable code:


```julia
tracetype[:live]
tracetype[:dead]
tracetype[:aux]
```


For example,


```julia
io = jsopen("file.js", "r")
trcs, hdrs = readframe(io, 1)
prop_trctype = prop(io, stockprop[:TRC_TYPE])
for i=1:size(hdrs,2)
    if get(prop_trctype, hdrs, i) == tracetype[:live]
        write(STDOUT, "trace $(i) is a live trace\n")
    elseif get(prop_trctype, hdrs, i) == tracetype[:dead]
        write(STDOUT, "trace $(i) is a dead trace\n")
    elseif get(prop_trctype, hdrs, i) == tracetype[:aux]
        write(STDOUT, "trace $(i) is a aux trace\n"
    end
end
close(io)
```


<a id='Data-properties-1'></a>

# Data properties


TeaSeis.jl provides support for storing custum data properties.  This is accomplished by passing an array of `DataProperty`'s to the `jsopen` function.  For example, a data property could be defined as:


```julia
p = DataProperty("Survey date", Int32, 120977")
```


<a id='Secondaries-1'></a>

# Secondaries


If you choose to use secondary storage, then it is recommended to set the `JAVASEIS_DATA_HOME` environment variable.  This is used to determine the file-path for the secondary storage.  For example if,


```
ENV["JAVASEIS_DATA_HOME"] = "/home/joe/projects"
cd("/home/joe/projects/some/dir/here")
io = jsopen("data.js", "w", axis_lengths=[10,11,12], secondaries=["/bigdisk/joe"])
close(io)
```


Then the secondary location is determined by replacing `/home/joe/projects` in `/home/joe/projects/some/dir/here/data.js` with `/bigdisk/joe` resulting in `/bigdisk/joe/some/dir/here/data.js` being the secondary storage for this example.


<a id='Geometry-1'></a>

# Geometry


TeaSeis.jl provides support for storing survey geometry using three-points to define rotated/translated coordinate system.


```julia
geom = Geometry(min_inline, max_inline, min_crossline, max_crossline, x1, y1, x2, y2, x3, y3)
```


where (x1,y1) is at the intersection of the inline and crossline axes.  (x2,y2) is the end of the first crossline, and (x3,y3) is the end of the first inline.  TeaSeis.jl does not provide any tools for using this geometry to manipulate trace coordinates.  I would recommend that this functionality be put into a separate package.


<center>![](geometry.png)</center>


<a id='Convenience-methods-and-dictionaries-1'></a>

# Convenience methods and dictionaries


For convenience and consistency, we supply several dictionaries.  In addition to the dictionary for trace property definitions and trace type (both described above), there are dictionaries for <b>data domain</b> `stockdomain`, <b>units</b> `stockunit`, and <b>data type</b> `stockdatatype`.  All of these are listed in [STOCKPROPS.md](STOCKPROPS.md).


Example usage within the jsopen method:


```julia
io = jsopen("file.js", "w", axis_lengths=[12,11,10], axis_units=[stockunit[:SECONDS], stockunit[:METERS], stockunit[:METERS]], axis_domains=[stockdomain[:TIME], stockdomain[:SPACE], stockdomain[:SPACE], datatype=stockdatatype[:SOURCE])
```


Several convenience methods are supplied for querying `io::JSeis`:


```julia
ndims(io)            # returns `Int`, number of dimensions in the JavaSeis dataset
length(io)           # returns `Int`, the number of frames in the JavaSeis dataset, equivalent to `prod(size(io)[3:end])`
size(io)             # returns `NTuple{Int}`, size of JavaSeis dataset
size(io,i)           # returns `Int`, size of JavaSeis dataset along dimension `i::Int`
props(io)            # returns `NTuple{TraceProperty}`, trace property along all dimensions
props(io,i)          # returns `TraceProperty`, trace property along dimension `i::Int`
propdefs(io)         # returns `NTuple{TracePropertyDef}`, trace property definition along all dimensions
propdefs(io,i)       # returns `TracePropertyDef`, trace property along dimension `i::Int`
labels(io)           # returns `NTuple{String}`, trace property labels along all dimensions
labels(io,i)         # returns `String`, trace property label along dimension `i::Int`
units(io)            # returns `NTuple{String}`, units along all dimensions
units(io,i)          # returns `String, unit along dimension `i::Int`
domains(io)          # returns `NTuple{String}`, data domains along all dimensions
domains(io,i)        # returns `String`, data domain along dimension `i::Int`
pstarts(io)          # returns `NTuple{Float64}`, physical starts along all dimensions
pstarts(io,i)        # returns `Float64`, physical start along dimension `i::Int`
pincs(io)            # returns `NTuple{Float64}`, physical increments along all dimensions
pincs(io,i)          # returns `Float64`, physical increment along dimension `i::Int`
lstarts(io)          # returns `NTuple{Int32}`, logical starts along all dimensions
lstarts(io,i)        # returns `Int32`, logical start along dimension `i::Int`
lincs(io)            # returns `NTuple{Int32}`, logical increments along all dimensions
lincs(io,i)          # returns `Int32`, logical increment along dimension `i::Int`
lrange(io)           # returns `NTuple{StepRange{Int64}}`, logical range along all dimensions
lrange(io,i)         # returns `StepRange{Int64}`, logical range along dimension `i::Int`
isempty(io)          # returns true if the dataset is empty (without trace or header extents)
in(prop,io)          # returns true if the trace property `prop` exists in `io` --  `prop` can be of types `::TraceProperty`, `::TracePropertyDef`, or `::String`
dataproperty(io,nm)  # returns the value held in the data property: `nm::String`
```


Convenience methods are supplied for manipulating `io::JSeis`:


```julia
rm(io)                      # remove (delete) the file and all of its extent files and secondary folders
empty!(io)                  # remove extends and secondary folders, but keep meta-data
cp(src, dst)                # create a new JavaSeis file `dst::AbstractString` that is a copy of `src::JSeis`, optional named argument: `secondaries=` - change file extents location
mv(src, dst)                # move a JavaSeis file to `dst::AbstractString` from `src::JSeis`, optional named argument: `secondaries=` - change file extents location
copy!(io, hdrs, io1, hdrs1) # copy values from `hdrs1::Array{UInt8,2}` to `hdrs::Array{UInt8,2}`
```


<a id='API-1'></a>

# API

- [`Base.Filesystem.cp`](README.md#Base.Filesystem.cp-Tuple{TeaSeis.JSeis,AbstractString})
- [`Base.Filesystem.mv`](README.md#Base.Filesystem.mv-Tuple{TeaSeis.JSeis,AbstractString})
- [`Base.Filesystem.rm`](README.md#Base.Filesystem.rm-Tuple{TeaSeis.JSeis})
- [`Base.close`](README.md#Base.close-Tuple{TeaSeis.JSeis})
- [`Base.copy!`](README.md#Base.copy!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,2},TeaSeis.JSeis,AbstractArray{UInt8,2}})
- [`Base.empty!`](README.md#Base.empty!-Tuple{TeaSeis.JSeis})
- [`Base.get`](README.md#Base.get-Tuple{TeaSeis.TraceProperty,AbstractArray{UInt8,2},Int64})
- [`Base.get`](README.md#Base.get-Tuple{TeaSeis.TraceProperty{T<:Number},Array{UInt8,1}})
- [`Base.in`](README.md#Base.in-Tuple{Union{String,TeaSeis.TracePropertyDef,TeaSeis.TraceProperty},TeaSeis.JSeis})
- [`Base.ind2sub`](README.md#Base.ind2sub-Tuple{TeaSeis.JSeis,Int64})
- [`Base.isempty`](README.md#Base.isempty-Tuple{TeaSeis.JSeis})
- [`Base.length`](README.md#Base.length-Tuple{TeaSeis.JSeis})
- [`Base.ndims`](README.md#Base.ndims-Tuple{TeaSeis.JSeis})
- [`Base.read`](README.md#Base.read-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`Base.read!`](README.md#Base.read!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},AbstractArray{UInt8,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`Base.size`](README.md#Base.size-Tuple{TeaSeis.JSeis})
- [`Base.size`](README.md#Base.size-Tuple{TeaSeis.JSeis,Int64})
- [`Base.write`](README.md#Base.write-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`Base.write`](README.md#Base.write)
- [`TeaSeis.allocframe`](README.md#TeaSeis.allocframe-Tuple{TeaSeis.JSeis})
- [`TeaSeis.allocframehdrs`](README.md#TeaSeis.allocframehdrs-Tuple{TeaSeis.JSeis})
- [`TeaSeis.allocframetrcs`](README.md#TeaSeis.allocframetrcs-Tuple{TeaSeis.JSeis})
- [`TeaSeis.dataproperty`](README.md#TeaSeis.dataproperty-Tuple{TeaSeis.JSeis,String})
- [`TeaSeis.domains`](README.md#TeaSeis.domains-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.domains`](README.md#TeaSeis.domains-Tuple{TeaSeis.JSeis})
- [`TeaSeis.fold`](README.md#TeaSeis.fold-Tuple{TeaSeis.JSeis,Array{UInt8,2}})
- [`TeaSeis.fold`](README.md#TeaSeis.fold-Tuple{TeaSeis.JSeis,Vararg{Int64,N}})
- [`TeaSeis.jscreate`](README.md#TeaSeis.jscreate-Tuple{String})
- [`TeaSeis.jsopen`](README.md#TeaSeis.jsopen-Tuple{String})
- [`TeaSeis.jsopen`](README.md#TeaSeis.jsopen-Tuple{String,String})
- [`TeaSeis.labels`](README.md#TeaSeis.labels-Tuple{TeaSeis.JSeis})
- [`TeaSeis.labels`](README.md#TeaSeis.labels-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.leftjustify!`](README.md#TeaSeis.leftjustify!-Tuple{TeaSeis.JSeis,Array{Float32,2},Array{UInt8,2}})
- [`TeaSeis.lincs`](README.md#TeaSeis.lincs-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.lincs`](README.md#TeaSeis.lincs-Tuple{TeaSeis.JSeis})
- [`TeaSeis.lrange`](README.md#TeaSeis.lrange-Tuple{TeaSeis.JSeis})
- [`TeaSeis.lrange`](README.md#TeaSeis.lrange-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.lstarts`](README.md#TeaSeis.lstarts-Tuple{TeaSeis.JSeis})
- [`TeaSeis.lstarts`](README.md#TeaSeis.lstarts-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.pincs`](README.md#TeaSeis.pincs-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.pincs`](README.md#TeaSeis.pincs-Tuple{TeaSeis.JSeis})
- [`TeaSeis.prop`](README.md#TeaSeis.prop-Tuple{TeaSeis.JSeis,String})
- [`TeaSeis.propdefs`](README.md#TeaSeis.propdefs-Tuple{TeaSeis.JSeis})
- [`TeaSeis.propdefs`](README.md#TeaSeis.propdefs-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.props`](README.md#TeaSeis.props-Tuple{TeaSeis.JSeis})
- [`TeaSeis.props`](README.md#TeaSeis.props-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.pstarts`](README.md#TeaSeis.pstarts-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.pstarts`](README.md#TeaSeis.pstarts-Tuple{TeaSeis.JSeis})
- [`TeaSeis.readframe`](README.md#TeaSeis.readframe-Tuple{TeaSeis.JSeis,Vararg{Int64,N}})
- [`TeaSeis.readframe!`](README.md#TeaSeis.readframe!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},AbstractArray{UInt8,2},Vararg{Int64,N}})
- [`TeaSeis.readframehdrs`](README.md#TeaSeis.readframehdrs-Tuple{TeaSeis.JSeis,Vararg{Int64,N}})
- [`TeaSeis.readframehdrs!`](README.md#TeaSeis.readframehdrs!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,2},Vararg{Int64,N}})
- [`TeaSeis.readframetrcs`](README.md#TeaSeis.readframetrcs-Tuple{TeaSeis.JSeis,Vararg{Int64,N}})
- [`TeaSeis.readframetrcs!`](README.md#TeaSeis.readframetrcs!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},Vararg{Int64,N}})
- [`TeaSeis.readhdrs`](README.md#TeaSeis.readhdrs-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`TeaSeis.readhdrs!`](README.md#TeaSeis.readhdrs!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,N},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`TeaSeis.readtrcs`](README.md#TeaSeis.readtrcs-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`TeaSeis.readtrcs!`](README.md#TeaSeis.readtrcs!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}})
- [`TeaSeis.regularize!`](README.md#TeaSeis.regularize!-Tuple{TeaSeis.JSeis,Array{Float32,2},Array{UInt8,2}})
- [`TeaSeis.set!`](README.md#TeaSeis.set!-Tuple{TeaSeis.TraceProperty,AbstractArray{UInt8,2},Int64,T<:Number})
- [`TeaSeis.units`](README.md#TeaSeis.units-Tuple{TeaSeis.JSeis,Int64})
- [`TeaSeis.units`](README.md#TeaSeis.units-Tuple{TeaSeis.JSeis})
- [`TeaSeis.writeframe`](README.md#TeaSeis.writeframe-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},AbstractArray{UInt8,2},Int64})
- [`TeaSeis.writeframe`](README.md#TeaSeis.writeframe-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},Vararg{Int64,N}})

<a id='TeaSeis.allocframe-Tuple{TeaSeis.JSeis}' href='#TeaSeis.allocframe-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.allocframe`** &mdash; *Method*.



```
allocframe(io)
```

Allocate memory for one frame of JavaSeis dataset.  Returns `(Array{Float32,2},Array{UInt8,2})`. For example, `trcs, hdrs = allocframe(jsopen("data.js"))`.

<a id='TeaSeis.allocframehdrs-Tuple{TeaSeis.JSeis}' href='#TeaSeis.allocframehdrs-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.allocframehdrs`** &mdash; *Method*.



allocframehdrs(io)

Allocate memory for headers for one frame of JavaSeis dataset.  Returns `Array{UInt8,2}`. For example, `hdrs = allocframehdrs(jsopen("data.js"))`.

<a id='TeaSeis.allocframetrcs-Tuple{TeaSeis.JSeis}' href='#TeaSeis.allocframetrcs-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.allocframetrcs`** &mdash; *Method*.



allocframetrcs(io)

Allocate memory for traces for one frame of JavaSeis dataset.  Returns `Array{Float32,2}`. For example, `trcs = allocframetrcs(jsopen("data.js"))`.

<a id='TeaSeis.dataproperty-Tuple{TeaSeis.JSeis,String}' href='#TeaSeis.dataproperty-Tuple{TeaSeis.JSeis,String}'>#</a>
**`TeaSeis.dataproperty`** &mdash; *Method*.



```
dataproperty(io, label)
```

Get a data property (data properties are per file, rather than per trace) from `io::JSeis` with label `label::String`.  For example, `dataproperty(jsopen("data.js"), "FREQUENCY")`.

<a id='TeaSeis.domains-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.domains-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.domains`** &mdash; *Method*.



```
domains(io, i)
```

Returns the domain of the ith dimension of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.domains-Tuple{TeaSeis.JSeis}' href='#TeaSeis.domains-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.domains`** &mdash; *Method*.



```
domains(io)
```

Returns the domains of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.fold-Tuple{TeaSeis.JSeis,Array{UInt8,2}}' href='#TeaSeis.fold-Tuple{TeaSeis.JSeis,Array{UInt8,2}}'>#</a>
**`TeaSeis.fold`** &mdash; *Method*.



```
fold(io, hdrs)
```

Compute the fold of a frame where io is JSeis corresponding to the dataset, and hdrs are the headers for the frame. For example: `io=jsopen("file.js"); fold(io, readframehdrs(io,1))`

<a id='TeaSeis.fold-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}' href='#TeaSeis.fold-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}'>#</a>
**`TeaSeis.fold`** &mdash; *Method*.



```
fold(io, idx...)
```

Compute the fold of a frame where idx is the frame/volume/hypercube indices.  For example, `fold(jsopen("file.js"),1)` for a 3D dataset, `fold(jsopen("file.js",1,2))` for a 4D dataset, and `fold(jsopen("file.js"),1,2,3)` for a 5D dataset.

<a id='TeaSeis.jscreate-Tuple{String}' href='#TeaSeis.jscreate-Tuple{String}'>#</a>
**`TeaSeis.jscreate`** &mdash; *Method*.



```
jscreate(filename)
```

Create a JavaSeis dataset without opening it.  This method has the same optional arguments as `jsopen`

<a id='TeaSeis.jsopen-Tuple{String,String}' href='#TeaSeis.jsopen-Tuple{String,String}'>#</a>
**`TeaSeis.jsopen`** &mdash; *Method*.



```
jsopen(filename, mode, [parameters])
```

Open a new or existing JavaSeis dataset with name `filename::String` and in `mode::String`. `mode` can be one of `"r"` (read), `"w"` (write/create) or `"r+"` (read and write). It is convention for filename to havea ".js" extention.

If `"w"` is used for the value of `mode`, then the `axis_lengths` named parameter is required, and several optional named function parameters are available:

**parameters**

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
  * `geom::Geometry` An optional three point geometry can be embedded in the JavaSeis file.
  * `secondaries::Array{String}` An array of file-system locations used to store the file extents.  If not set, then *primary* storage is used.
  * `nextents::Int64` The number of file-extents used to store the data.  If not set, then a heuristic is used to choose the number of extents.  The heuristic is: min(256,10 + (FRAMEWORK_SIZE)/(2*1024^3)).
  * `properties_add::Array{TracePropertyDef}` When `similarto` is specified, use this to add trace properties to those already existing in the `similarto` file.
  * `properties_rm::Array{TracePropertyDef}` When `similarto` is specified, use this to remove trace properties to those already existing in the `similarto` file.
  * `dataproperties_add::Array{DataProperty}` When `similarto` is specfied, use this to add dataset properties to those aloready existing in the `similarto` file.
  * `dataproperties_rm::Array{DataProperty}` When `similarto` is specified, use this to remove dataset properties to those already existing in the `similarto` file.

<a id='TeaSeis.jsopen-Tuple{String}' href='#TeaSeis.jsopen-Tuple{String}'>#</a>
**`TeaSeis.jsopen`** &mdash; *Method*.



```
jsopen(filename)
```

Equivalent to `jsopen(filename, "r")`

<a id='TeaSeis.labels-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.labels-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.labels`** &mdash; *Method*.



```
labels(io, i)
```

Returns the string label of the ith framework axis of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.labels-Tuple{TeaSeis.JSeis}' href='#TeaSeis.labels-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.labels`** &mdash; *Method*.



```
labels(io)
```

Returns the string labels corresponding to the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.leftjustify!-Tuple{TeaSeis.JSeis,Array{Float32,2},Array{UInt8,2}}' href='#TeaSeis.leftjustify!-Tuple{TeaSeis.JSeis,Array{Float32,2},Array{UInt8,2}}'>#</a>
**`TeaSeis.leftjustify!`** &mdash; *Method*.



```
leftjustify(io, trcs, hdrs)
```

Left justify all live (non-dead) traces in a frame, moving them to the beginning of `trcs` and `hdrs`.  See also `regularize!`

<a id='TeaSeis.lincs-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.lincs-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.lincs`** &mdash; *Method*.



```
lincs(io,i)
```

Returns the logical increment of the framework axes for dimension `i` of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.lincs-Tuple{TeaSeis.JSeis}' href='#TeaSeis.lincs-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.lincs`** &mdash; *Method*.



```
lincs(io)
```

Returns the logical increments of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.lrange-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.lrange-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.lrange`** &mdash; *Method*.



```
lrange(io, i)
```

Returns the logical range of the framework axes for dimension `i` of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.lrange-Tuple{TeaSeis.JSeis}' href='#TeaSeis.lrange-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.lrange`** &mdash; *Method*.



```
lrange(io)
```

Returns the logical ranges of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.lstarts-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.lstarts-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.lstarts`** &mdash; *Method*.



```
lstarts(io,i)
```

Returns the logical start of the framework axes for dimension `i` of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.lstarts-Tuple{TeaSeis.JSeis}' href='#TeaSeis.lstarts-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.lstarts`** &mdash; *Method*.



```
lstarts(io)
```

Returns the logical start of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.pincs-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.pincs-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.pincs`** &mdash; *Method*.



```
pincs(io, i)
```

Returns the physical increments of the framework axes for dimension `i` of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.pincs-Tuple{TeaSeis.JSeis}' href='#TeaSeis.pincs-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.pincs`** &mdash; *Method*.



```
pincs(io)
```

Returns the physical increments of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.prop-Tuple{TeaSeis.JSeis,String}' href='#TeaSeis.prop-Tuple{TeaSeis.JSeis,String}'>#</a>
**`TeaSeis.prop`** &mdash; *Method*.



```
prop(io, propertyname)
```

Get a trace property from `io::JSeis` where `propertyname` is either `String` or `TracePropertyDef`. For example:

```julia
io = jsopen("data.js")
p = prop(io, "REC_X")            # using an `String`
p = prop(io, stockprop[:REC_X])  # using a `TracePropertyDef`
```

<a id='TeaSeis.propdefs-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.propdefs-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.propdefs`** &mdash; *Method*.



```
propdefs(io, i)
```

Returns the property definition of the ith framework axis of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.propdefs-Tuple{TeaSeis.JSeis}' href='#TeaSeis.propdefs-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.propdefs`** &mdash; *Method*.



```
propdefs(io)
```

Returns the property definitions of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.props-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.props-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.props`** &mdash; *Method*.



```
props(io, i)
```

Returns the trace property of the ith framework axis of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.props-Tuple{TeaSeis.JSeis}' href='#TeaSeis.props-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.props`** &mdash; *Method*.



```
props(io)
```

Returns the trace properties of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.pstarts-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.pstarts-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.pstarts`** &mdash; *Method*.



```
pstarts(io, i)
```

Returns the physical start of the ith dimension of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.pstarts-Tuple{TeaSeis.JSeis}' href='#TeaSeis.pstarts-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.pstarts`** &mdash; *Method*.



```
pstarts(io)
```

Returns the physical start of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.readframe!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},AbstractArray{UInt8,2},Vararg{Int64,N}}' href='#TeaSeis.readframe!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},AbstractArray{UInt8,2},Vararg{Int64,N}}'>#</a>
**`TeaSeis.readframe!`** &mdash; *Method*.



```
readframe!(io, trcs, hdrs, idx...)
```

In-place read of a single frame from a JavaSeis dataset.  For non full frame, the resulting traces and headers are left justified.  Examples:

**3D:**

```julia
io = jsopen("data_3D.js")
trcs, hdrs = allocframe(io)
frm_idx = 1
readframe!(io, trcs, hdrs, frm_idx)
```

**4D:**

```julia
io = jsopen("data_4D.js")
trcs, hdrs = allocframe(io)
frm_idx, vol_idx = 1, 1
readframe!(io, trcs, hdrs, frm_idx, vol_idx)
```

**5D:**

```julia
io = jsopen("data_5D.js")
trcs, hdrs = allocframe(io)
frm_idx, vol_idx, hyp_idx = 1, 1, 1
readframe!(io, trcs, hdrs, frm_idx, vol_idx, hyp_idx)
```

<a id='TeaSeis.readframe-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}' href='#TeaSeis.readframe-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}'>#</a>
**`TeaSeis.readframe`** &mdash; *Method*.



```
readframe(io, idx...)
```

Out-of-place read of a single frame from a JavaSeis dataset.  For non full frame, the resulting traces and headers are left justified.  Examples:

**3D:**

```julia
frm_idx = 1
trcs, hdrs = readframe(jsopen("data_3D.js"), frm_idx)
```

**4D:**

```julia
frm_idx, vol_idx = 1, 1
trcs, hdrs = readframe(jsopen("data_4D.js"), frm_idx, vol_idx)
```

**5D:**

```julia
frm_idx, vol_idx, hyp_idx = 1, 1, 1
trcs, hdrs = readframe(jsopen("data_5D.js"), frm_idx, vol_idx, hyp_idx)
```

<a id='TeaSeis.readframehdrs!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,2},Vararg{Int64,N}}' href='#TeaSeis.readframehdrs!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,2},Vararg{Int64,N}}'>#</a>
**`TeaSeis.readframehdrs!`** &mdash; *Method*.



```
readframehdrs!(io, hdrs, idx...)
```

In-place read of a single frame from a JavaSeis dataset (headers only).  For non full frame, the resulting headers are left justified.  Examples:

**3D:**

```julia
io = jsopen("data_3D.js")
hdrs = allocframehdrs(io)
frm_idx = 1
readframehdrs!(io, hdrs, frm_idx)
```

**4D:**

```julia
io = jsopen("data_4D.js")
hdrs = allocframehdrs(io)
frm_idx, vol_idx = 1, 1
readframehdrs!(io, hdrs, frm_idx, vol_idx)
```

**5D:**

```julia
io = jsopen("data_5D.js")
hdrs = allocframehdrs(io)
frm_idx, vol_idx, hyp_idx = 1, 1, 1
readframehdrs!(io, hdrs, frm_idx, vol_idx, hyp_idx)
```

<a id='TeaSeis.readframehdrs-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}' href='#TeaSeis.readframehdrs-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}'>#</a>
**`TeaSeis.readframehdrs`** &mdash; *Method*.



readframehdrs(io, idx...)

Out-of-place read of a single frame (headers only) from a JavaSeis dataset.  For non full frame, the resulting headers are left justified.  Examples:

**3D:**

```julia
frm_idx = 1
hdrs = readframehdrs(jsopen("data_3D.js"), frm_idx)
```

**4D:**

```julia
frm_idx, vol_idx = 1, 1
hdrs = readframehdrs(jsopen("data_4D.js"), frm_idx, vol_idx)
```

**5D:**

```julia
frm_idx, vol_idx, hyp_idx = 1, 1, 1
hdrs = readframehdrs(jsopen("data_5D.js"), frm_idx, vol_idx, hyp_idx)
```

<a id='TeaSeis.readframetrcs!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},Vararg{Int64,N}}' href='#TeaSeis.readframetrcs!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},Vararg{Int64,N}}'>#</a>
**`TeaSeis.readframetrcs!`** &mdash; *Method*.



```
readframetrcs!(io, trcs, hdrs, idx...)
```

In-place read of a single frame from a JavaSeis dataset (traces only).  For non full frame, the resulting traces are left justified.  Examples:

**3D:**

```julia
io = jsopen("data_3D.js")
trcs = allocframetrcs(io)
frm_idx = 1
readframetrcs!(io, trcs, frm_idx)
```

**4D:**

```julia
io = jsopen("data_4D.js")
trcs = allocframetrcs(io)
frm_idx, vol_idx = 1, 1
readframetrcs!(io, trcs, frm_idx, vol_idx)
```

**5D:**

```julia
io = jsopen("data_5D.js")
trcs = allocframetrcs(io)
frm_idx, vol_idx, hyp_idx = 1, 1, 1
readframetrcs!(io, trcs, frm_idx, vol_idx, hyp_idx)
```

<a id='TeaSeis.readframetrcs-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}' href='#TeaSeis.readframetrcs-Tuple{TeaSeis.JSeis,Vararg{Int64,N}}'>#</a>
**`TeaSeis.readframetrcs`** &mdash; *Method*.



```
readframetrcs(io, idx...)
```

Out-of-place read of a single frame (traces only) from a JavaSeis dataset.  For non full frame, the resulting traces are left justified.  Examples:

**3D:**

```julia
frm_idx = 1
trcs = readframetrcs(jsopen("data_3D.js"), frm_idx)
```

**4D:**

```julia
frm_idx, vol_idx = 1, 1
trcs = readframetrcs(jsopen("data_4D.js"), frm_idx, vol_idx)
```

**5D:**

```julia
frm_idx, vol_idx, hyp_idx = 1, 1, 1
trcs = readframetrcs(jsopen("data_5D.js"), frm_idx, vol_idx, hyp_idx)
```

<a id='TeaSeis.readhdrs!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,N},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#TeaSeis.readhdrs!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,N},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`TeaSeis.readhdrs!`** &mdash; *Method*.



```
readhdrs!(io, hdrs, trace_range, range...)
```

In-place read of a subset of data (headers only) from a JavaSeis file. If performance is important, then consider using `readframehdrs!` instead.  Examples:

**3D:**

```julia
readhdrs!(jsopen("data_3D.js"), hdrs, :, :)
readhdrs!(jsopen("data_3D.js"), hdrs, 1:2:end, 1:5)
```

**4D:**

```julia
readhdrs!(jsopen("data_4D.js"), hdrs, :, :, :)
readhdrs!(jsopen("data_4D.js"), hdrs, :, 2, 2:2:10)
```

**5D:**

```julia
readhdrs!(jsopen("data_5D.js"), hdrs, :, :, :, :)
readhdrs!(jsopen("data_5D.js"), hdrs, :, 2, 2:2:10, 1:10)
```

<a id='TeaSeis.readhdrs-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#TeaSeis.readhdrs-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`TeaSeis.readhdrs`** &mdash; *Method*.



```
readhdrs(io, trace_range, range...)
```

Out-of-place read of a subset of data (headers only) from a JavaSeis file. Returns an array of trace data. If performance is important, then consider using `readframetrcs` instead.  Examples:

**3D:**

```julia
hdrs = readhdrs(jsopen("data_3D.js"), :, :, :)
hdrs = readhdrs(jsopen("data_3D.js"), :, 1:2:end, 1:5)
```

**4D:**

```julia
hdrs = readhdrs(jsopen("data_4D.js"), :, :, :, :)
hdrs = readhdrs(jsopen("data_4D.js"), :, :, 2, 2:2:10)
```

**5D:**

```julia
hdrs = readhdrs(jsopen("data_5D.js"), :, :, :, :, :)
hdrs = readhdrs(jsopen("data_5D.js"), :, :, 2, 2:2:10, 1:10)
```

<a id='TeaSeis.readtrcs!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#TeaSeis.readtrcs!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`TeaSeis.readtrcs!`** &mdash; *Method*.



```
readtrcs!(io, trcs, sample_range, trace_range, range...)
```

In-place read of a subset of data (traces only) from a JavaSeis file. If performance is important, then consider using `readframetrcs!` instead.  Examples:

**3D:**

```julia
readtrcs!(jsopen("data_3D.js"), trcs, :, :, :)
readtrcs!(jsopen("data_3D.js"), trcs, :, 1:2:end, 1:5)
```

**4D:**

```julia
readtrcs!(jsopen("data_4D.js"), trcs, :, :, :, :)
readtrcs!(jsopen("data_4D.js"), trcs, :, :, 2, 2:2:10)
```

**5D:**

```julia
readtrcs!(jsopen("data_5D.js"), trcs, :, :, :, :, :)
readtrcs!(jsopen("data_5D.js"), trcs, :, :, 2, 2:2:10, 1:10)
```

<a id='TeaSeis.readtrcs-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#TeaSeis.readtrcs-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`TeaSeis.readtrcs`** &mdash; *Method*.



```
readtrcs(io, sample_range, trace_range, range...)
```

Out-of-place read of a subset of data (traces only) from a JavaSeis file. Returns an array of trace data. If performance is important, then consider using `readframetrcs` instead.  Examples:

**3D:**

```julia
trcs = readtrcs(jsopen("data_3D.js"), :, :, :)
trcs = readtrcs(jsopen("data_3D.js"), :, 1:2:end, 1:5)
```

**4D:**

```julia
trcs = readtrcs(jsopen("data_4D.js"), :, :, :, :)
trcs = readtrcs(jsopen("data_4D.js"), :, :, 2, 2:2:10)
```

**5D:**

```julia
trcs = readtrcs(jsopen("data_5D.js"), :, :, :, :, :)
trcs = readtrcs(jsopen("data_5D.js"), :, :, 2, 2:2:10, 1:10)
```

<a id='TeaSeis.regularize!-Tuple{TeaSeis.JSeis,Array{Float32,2},Array{UInt8,2}}' href='#TeaSeis.regularize!-Tuple{TeaSeis.JSeis,Array{Float32,2},Array{UInt8,2}}'>#</a>
**`TeaSeis.regularize!`** &mdash; *Method*.



```
regularize!(io, trcs, hdrs)
```

Regularize the traces in a frame, moving them from their left-justified state, to one that reflects their trace location within a frame according to their trace framework definition.

<a id='TeaSeis.set!-Tuple{TeaSeis.TraceProperty,AbstractArray{UInt8,2},Int64,T<:Number}' href='#TeaSeis.set!-Tuple{TeaSeis.TraceProperty,AbstractArray{UInt8,2},Int64,T<:Number}'>#</a>
**`TeaSeis.set!`** &mdash; *Method*.



```
set!(prop, hdrs, i, value)
```

Set the value of the trace property `prop::TraceProperty` stored in the header of the ith column of `hdrs::Array{UInt8,2}` to `value::T`.  For example, `io=jsopen("test.js"); hdrs=readframehdrs(io,1); set!(prop(io,"REC_X"), 1, 10.0)`.

<a id='TeaSeis.units-Tuple{TeaSeis.JSeis,Int64}' href='#TeaSeis.units-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`TeaSeis.units`** &mdash; *Method*.



```
units(io, i)
```

Returns the unit of measure of the ith dimension of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.units-Tuple{TeaSeis.JSeis}' href='#TeaSeis.units-Tuple{TeaSeis.JSeis}'>#</a>
**`TeaSeis.units`** &mdash; *Method*.



```
units(io)
```

Returns the unit of measure of the framework axes of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='TeaSeis.writeframe-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},AbstractArray{UInt8,2},Int64}' href='#TeaSeis.writeframe-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},AbstractArray{UInt8,2},Int64}'>#</a>
**`TeaSeis.writeframe`** &mdash; *Method*.



```
writeframe(io, trcs, hdrs)
```

Write a frame of data to the JavaSeis dataset corresponding to `io::JSeis`.  `trcs` and `hdrs` are 2-dimensional arrays. The location of the dataset written to is determined by the values of the framework headers stored in `hdrs`.

<a id='TeaSeis.writeframe-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},Vararg{Int64,N}}' href='#TeaSeis.writeframe-Tuple{TeaSeis.JSeis,AbstractArray{Float32,2},Vararg{Int64,N}}'>#</a>
**`TeaSeis.writeframe`** &mdash; *Method*.



```
writeframe(io, trcs, idx...)
```

Write a frame of data to the JavaSeis dataset corresponding to `io::JSeis`.  `trcs` is a 2-dimensional array.  The location of the datset written to is determined by `idx...`.  For example:

**3D:**

```julia
writeframe(jsopen("data_3D.js"), trcs, 1) # write to frame 1
```

**4D:**

```julia
writeframe(jsopen("data_4D.js"), trcs, 1, 2) # write to frame 1, volume 2
```

**5D:**

```julia
writeframe(jsopen("data_5D.js"), trcs, 1, 2, 3) # write to frame 1, volume 2, hypercube 3
```

<a id='Base.Filesystem.cp-Tuple{TeaSeis.JSeis,AbstractString}' href='#Base.Filesystem.cp-Tuple{TeaSeis.JSeis,AbstractString}'>#</a>
**`Base.Filesystem.cp`** &mdash; *Method*.



```
cp(src, dst, [secondaries=nothing])
```

Copy a file from `src` (of type `JSeis`) to `dst` of type `String`.  For example, `cp(jsopen("copyfrom.js"), "copyto.js")`. Use the optional named argument `secondaries` to change the JavaSeis secondary location.

<a id='Base.Filesystem.mv-Tuple{TeaSeis.JSeis,AbstractString}' href='#Base.Filesystem.mv-Tuple{TeaSeis.JSeis,AbstractString}'>#</a>
**`Base.Filesystem.mv`** &mdash; *Method*.



```
mv(src, dst, [secondaries=nothing])
```

Move a file from `src` (of type `JSeis`) to `dst` of type `String`.  For example, `cp(jsopen("movefrom.js"), "moveto.js")`. Use the optional named argument `secondaries` to change the JavaSeis secondary location.

<a id='Base.Filesystem.rm-Tuple{TeaSeis.JSeis}' href='#Base.Filesystem.rm-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.Filesystem.rm`** &mdash; *Method*.



```
rm(io)
```

Remove a JavaSeis dataset from disk.  For example: `rm(jsopen("deleteme.js"))`

<a id='Base.close-Tuple{TeaSeis.JSeis}' href='#Base.close-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.close`** &mdash; *Method*.



```
close(io)
```

Close an open JavaSeis dataset where `io` is of type `JSeis` created using, for example, `jsopen`.

<a id='Base.copy!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,2},TeaSeis.JSeis,AbstractArray{UInt8,2}}' href='#Base.copy!-Tuple{TeaSeis.JSeis,AbstractArray{UInt8,2},TeaSeis.JSeis,AbstractArray{UInt8,2}}'>#</a>
**`Base.copy!`** &mdash; *Method*.



```
copy!(ioout, hdrsout, ioin, hdrsin)
```

Copy trace headers from `hdrsin::Array{Uint8,2}` to `hdrsout::Array{Uint8,2}` and where `hdrsin` corresponds to `ioin::JSeis` and `hdrsout` corresponds to `ioout::JSeis`.  For example,

```julia
ioin = jsopen("data1.js")
ioout = jsopen("data2.js")
hdrsin = readframehdrs(ioin,1)
hdrsout = readframehdrs(ioout,1)
copy!(ioout, hdrsout, ioin, hdrsin)
```

<a id='Base.empty!-Tuple{TeaSeis.JSeis}' href='#Base.empty!-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.empty!`** &mdash; *Method*.



```
empty!(io)
```

Empty a JavaSeis dataset from disk, retaining the meta-information.  For example: `empty!(jsopen("emptyme.js"))`

<a id='Base.get-Tuple{TeaSeis.TraceProperty,AbstractArray{UInt8,2},Int64}' href='#Base.get-Tuple{TeaSeis.TraceProperty,AbstractArray{UInt8,2},Int64}'>#</a>
**`Base.get`** &mdash; *Method*.



```
get(prop, hdrs, i)
```

Get the value of the trace property `prop::TraceProperty` stored in the header of the ith column of `hdrs::Array{UInt8,2}`.  For example, `io=jsopen("data.js"); get(prop(io, "REC_X"), readframehdrs(io,1), 1)`.

<a id='Base.get-Tuple{TeaSeis.TraceProperty{T<:Number},Array{UInt8,1}}' href='#Base.get-Tuple{TeaSeis.TraceProperty{T<:Number},Array{UInt8,1}}'>#</a>
**`Base.get`** &mdash; *Method*.



```
get(prop, hdr)
```

Get the value of the trace property `prop::TraceProperty` stored in the header `hdr::Array{UInt8,1}`.  For example, `io=jsopen("data.js"); get(prop(io, "REC_X"), readframehdrs(io,1)[:,1])`

<a id='Base.in-Tuple{Union{String,TeaSeis.TracePropertyDef,TeaSeis.TraceProperty},TeaSeis.JSeis}' href='#Base.in-Tuple{Union{String,TeaSeis.TracePropertyDef,TeaSeis.TraceProperty},TeaSeis.JSeis}'>#</a>
**`Base.in`** &mdash; *Method*.



```
in(trace_property, io)
```

Returns true if `trace_property` is in the header catalog of `io::JSeis`, and where `trace_property` is one of `String`, `TracePropertyDef` or `TraceProperty`.

<a id='Base.ind2sub-Tuple{TeaSeis.JSeis,Int64}' href='#Base.ind2sub-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`Base.ind2sub`** &mdash; *Method*.



```
ind2sub(io, i)
```

Return the (frame,volume...) tuple for the liner index `i`.  This is useful for looping over all frames in a data-set that is more that 4 or more dimensions. For example,

```julia
for i = 1:length(io)
    trcs, hdrs = readframe(io, ind2sub(io,i)...)
end
```

<a id='Base.isempty-Tuple{TeaSeis.JSeis}' href='#Base.isempty-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.isempty`** &mdash; *Method*.



```
isempty(io)
```

Returns true if the dataset correpsonding to `io` is empty (contains no data), and false otherwise.

<a id='Base.length-Tuple{TeaSeis.JSeis}' href='#Base.length-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.length`** &mdash; *Method*.



```
length(io)
```

Returns the number of frames in a JavaSeis dataset corresponding to `io::JSeis`. This is equivalent to `prod(size(io)[3:end])`, and is useful for iterating over all frames in a JavaSeis dataset.

<a id='Base.ndims-Tuple{TeaSeis.JSeis}' href='#Base.ndims-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.ndims`** &mdash; *Method*.



```
ndims(io)
```

Returns the numbers of dimensions of the JavaSeis dataset corresponding to `io::JSeis`.

<a id='Base.read!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},AbstractArray{UInt8,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#Base.read!-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},AbstractArray{UInt8,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`Base.read!`** &mdash; *Method*.



```
read!(io, trcs, sample_range, trace_range, range...)
```

In-place read of a subset of data from a JavaSeis file. If performance is important, then consider using `readframe!` instead.  Examples:

**3D:**

```julia
read!(jsopen("data_3D.js"), trcs, hdrs, :, :, :)
read!(jsopen("data_3D.js"), trcs, hdrs, :, 1:2:end, 1:5)
```

**4D:**

```julia
read!(jsopen("data_4D.js"), trcs, hdrs, :, :, :, :)
read!(jsopen("data_4D.js"), trcs, hdrs, :, :, 2, 2:2:10)
```

**5D:**

```julia
read!(jsopen("data_5D.js"), trcs, hdrs, :, :, :, :, :)
read!(jsopen("data_5D.js"), trcs, hdrs, :, :, 2, 2:2:10, 1:10)
```

<a id='Base.read-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#Base.read-Tuple{TeaSeis.JSeis,Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`Base.read`** &mdash; *Method*.



```
read(io, sample_range, trace_range, range...)
```

Out-of-place read of a subset of data from a JavaSeis file. Returns an array of trace data. If performance is important, then consider using `readframetrcs` instead.  Examples:

**3D:**

```julia
trcs, hdrs = read(jsopen("data_3D.js"), :, :, :)
trcs, hdrs = read(jsopen("data_3D.js"), :, 1:2:end, 1:5)
```

**4D:**

```julia
trcs, hdrs = read(jsopen("data_4D.js"), :, :, :, :)
trcs, hdrs = read(jsopen("data_4D.js"), :, :, 2, 2:2:10)
```

**5D:**

```julia
trcs, hdrs = read(jsopen("data_5D.js"), :, :, :, :, :)
trcs, hdrs = read(jsopen("data_5D.js"), :, :, 2, 2:2:10, 1:10)
```

<a id='Base.size-Tuple{TeaSeis.JSeis,Int64}' href='#Base.size-Tuple{TeaSeis.JSeis,Int64}'>#</a>
**`Base.size`** &mdash; *Method*.



```
size(io, i)
```

Returns the lenth of dimension i of a JavaSeis dataset corresponding to `io::JSeis`.

<a id='Base.size-Tuple{TeaSeis.JSeis}' href='#Base.size-Tuple{TeaSeis.JSeis}'>#</a>
**`Base.size`** &mdash; *Method*.



```
size(io)
```

Returns the lenths of all dimensions (as a tuple of integers) of a JavaSeis dataset corresponding to `io::JSeis`.

<a id='Base.write' href='#Base.write'>#</a>
**`Base.write`** &mdash; *Function*.



```
write(io, trcs, hdrs[, smprng=:])
```

Write `trcs` and `hdrs` to the file corresponding to `io::JSeis`.  Optionally, you can limit which samples are written. The locations that are written to are determined by the values corresponding to the framework headers `hdrs`.  Note that the dimension of the arrays `trcs` and `hdrs` must match the number of dimensions in the framework.

<a id='Base.write-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}' href='#Base.write-Tuple{TeaSeis.JSeis,AbstractArray{Float32,N},Union{Colon,Int64,Range{Int64}},Union{Colon,Int64,Range{Int64}},Vararg{Union{Colon,Int64,Range{Int64}},N}}'>#</a>
**`Base.write`** &mdash; *Method*.



```
write(io, trcs, sample_range, trace_range, range...)
```

Write trcs to the JavaSeis file corresponding to `io::JSeis`.  the dimension of `trcs` must be the same as the dimension of `io`, and the size of each dimension corresponds to `range`.  Examples:

**3D:**

```julia
write(io, trcs, :, :, :)
```

**4D:**

```julia
write(io, trcs, :, :, :, :)
```

**5D:**

```julia
write(io, trcs, :, :, :, :, :)
```

