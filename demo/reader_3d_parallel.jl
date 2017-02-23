# while this is an illustration of parallel read, it's not very efficient...
# the time will be dominated by data movement from the master process to the worker process
# this is just for illustration
addprocs(2)
using TeaSeis
io = jsopen("test.js", "r")

@sync begin
@parallel for ifrm = 1:size(io,3)
    trcs, hdrs = readframe(io, ifrm)
    write(STDOUT, "read frame $(get(prop(io,stockprop[:FRAME]),hdrs[:,1]))\n")
    if ifrm == 3
        @show size(trcs)
    end
end
end

close(io)
