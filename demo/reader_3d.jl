using TeaSeis, PyPlot

io = jsopen("test.js", "r")

data = zeros(Float32, size(io))

trcs, hdrs = allocframe(io)
for ifrm = 1:size(io,3)
    readframe!(io, trcs, hdrs, ifrm)
    data[:,:,ifrm] = trcs
    write(STDOUT, "read frame, trcs and hdrs API $(get(prop(io,stockprop[:FRAME]),hdrs[:,1]))\n")
end

figure(1);imshow(data[:,:,3], aspect="auto", cmap="seismic_r", clim=maxabs(data[:,:,3])*[-1,1]); title("reader_3d, frame 3, trcs and hdrs API, fld=$(fold(io,hdrs))")

trcs = allocframetrcs(io)
for ifrm = 1:size(io,3)
    readframetrcs!(io, trcs, ifrm)
    data[:,:,ifrm] = trcs
end

figure(2);imshow(data[:,:,3], aspect="auto", cmap="seismic_r", clim=maxabs(data[:,:,3])*[-1,1]);title("reader_3d, frame 3, trcs API, fld=$(fold(io,3))")

hdrs = allocframehdrs(io)
for ifrm = 1:2
    readframehdrs!(io, hdrs, ifrm)
    for itrc = 1:3
        trcind = get(prop(io, stockprop[:TRACE]), hdrs[:,itrc])
        frmind = get(prop(io, stockprop[:FRAME]), hdrs, itrc)
        sou_x = get(prop(io, "SOU_X"), hdrs, itrc)
        write(STDOUT, "trcind=$(trcind), frmind=$(frmind), sou_x=$(sou_x)\n")
    end
end

close(io)
