using TeaSeis

# custom property with vector value:
custompropdef = TracePropertyDef("SOU_X", "Source locations, x", Float64, 2)

# create and open a new javaseis file:
io = jsopen("test.js", "w", axis_lengths=[501,40,6], properties=[custompropdef])

# create some data:
data_write = rand(Float32, size(io))

# write data (with headers) to the javaseis file:
hdrs = allocframehdrs(io)
for ifrm = 1:size(io,3)
    map(i->set!(prop(io, stockprop[:TRACE]),    hdrs, i, i),                 1:size(io,2))
    map(i->set!(prop(io, stockprop[:FRAME]),    hdrs, i, ifrm),              1:size(io,2))
    map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live]),  1:size(io,2))
    map(i->set!(prop(io, custompropdef),        hdrs, i, i*ifrm*[1.0, 2.0]), 1:size(io,2))
    writeframe(io, data_write[:,:,ifrm], hdrs)
end

# close the javaseis file:
close(io)

# open the dataset for reading:
io = jsopen("test.js", "r")

# allocate some memory for storing the read data:
data_read = zeros(Float32, size(io))

trcs, hdrs = allocframe(io)
for ifrm = 1:size(io,3)
    readframe!(io, trcs, hdrs, ifrm)
    data_read[:,:,ifrm] = trcs
    write(stdout, "read frame, trcs and hdrs API $(get(prop(io,stockprop[:FRAME]),hdrs[:,1]))\n")
end

# demonstrate that the extrema of the written and read data agree with each other:
@show extrema(data_write)
@show extrema(data_read)

# delete the javaseis file:
rm(io)

