# while this is an illustration of parallel write, it's not very efficient...
# the time will be dominated by data movement from the master process to the worker process
# this is just for illustration

addprocs(2)
using TeaSeis,PyPlot

io = jsopen("test.js", "w", axis_lengths=[501,40,6])
data = rand(Float32, size(io))

hdrs = allocframehdrs(io)
@sync @parallel for ifrm = 1:size(io,3)
    map(i->set!(prop(io, stockprop[:TRACE]),    hdrs, i, i),                1:size(io,2))
    map(i->set!(prop(io, stockprop[:FRAME]),    hdrs, i, ifrm),             1:size(io,2))
    map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live]), 1:size(io,2))
    writeframe(io, data[:,:,ifrm], hdrs)
end
close(io)

figure();imshow(data[:,:,3],cmap="seismic_r",clim=maxabs(data[:,:,3])*[-1,1],aspect="auto");title("writer_3d_parallel")

if isinteractive() == false
    PyPlot.show()
    sleep(999999)
end
