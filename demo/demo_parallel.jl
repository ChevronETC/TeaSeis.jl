# while this is an illustration of parallel write, it's not very efficient...
# the time will be dominated by data movement from the master process to the worker process
# this is just for illustration

addprocs(2)
using TeaSeis

# create and open a javaseis file for writing:
io = jsopen("test.js", "w", axis_lengths=[501,40,6])

# create some data:
data_write = rand(Float32, size(io))

# parallel write data and headers to the javaseis file:
hdrs = allocframehdrs(io)
@sync @parallel for ifrm = 1:size(io,3)
    map(i->set!(prop(io, stockprop[:TRACE]),    hdrs, i, i),                1:size(io,2))
    map(i->set!(prop(io, stockprop[:FRAME]),    hdrs, i, ifrm),             1:size(io,2))
    map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live]), 1:size(io,2))
    writeframe(io, data_write[:,:,ifrm], hdrs)
end

# close the javaseis file:
close(io)

# open the javaseis file for reading:
io = jsopen("test.js", "r")

# parallel read demonstration:
@sync @parallel for ifrm = 1:size(io,3)
    trcs, hdrs = readframe(io, ifrm)
    write(STDOUT, "read frame $(get(prop(io,stockprop[:FRAME]),hdrs[:,1]))\n")
    @show get(prop(io,stockprop[:FRAME]), hdrs[:,1]), extrema(trcs)
end

# delete javaseis file:
rm(io)

