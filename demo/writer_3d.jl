using TeaSeis, PyPlot

# custom prop with vector value
custompropdef = TracePropertyDef("SOU_X", "Source locations, x", Float64, 2)

io = jsopen("test.js", "w", axis_lengths=[501,40,6], properties=[custompropdef])

data = rand(Float32, size(io))

for ifrm = 1:size(io,3)
    writeframe(io, data[:,:,ifrm], ifrm)
end

figure(1);imshow(data[:,:,3], aspect="auto", cmap="seismic_r", clim=maxabs(data[:,:,3])*[-1,1]);title("writer_3d, frame 3, alternitive write API")

hdrs = allocframehdrs(io)
for ifrm = 1:size(io,3)
    map(i->set!(prop(io, stockprop[:TRACE]),    hdrs, i, i),                 1:size(io,2))
    map(i->set!(prop(io, stockprop[:FRAME]),    hdrs, i, ifrm),              1:size(io,2))
    map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live]),  1:size(io,2))
    map(i->set!(prop(io, custompropdef),        hdrs, i, i*ifrm*[1.0, 2.0]), 1:size(io,2))
    writeframe(io, data[:,:,ifrm], hdrs)
end

figure(2);imshow(data[:,:,3], aspect="auto", cmap="seismic_r", clim=maxabs(data[:,:,3])*[-1,1])
figure(3);imshow(data[:,:,3], aspect="auto", cmap="seismic_r", clim=maxabs(data[:,:,3])*[-1,1]);title("writer_3d, frame 3")

close(io)
