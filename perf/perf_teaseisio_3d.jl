using TeaSeis

macro bench(nm::AbstractString, ex::Expr)
    return quote
        tic()
        al = @allocated $ex
        el = toq()
        write(STDOUT, "elapsed time: $(el) seconds ($(al) bytes allocated)\n")
        ($nm,el,al)
    end
end

function main(disk=".")
    ENV["JAVASEIS_DATA_HOME"] = ""
    #
    # write 1G of samples
    #
    n1=1024
    n2=1024
    n3=250

    # JavaSeis data context and in memory data/headers
    iojs = jsopen("test.js", "w", axis_lengths=[n1,n2,n3], secondaries=[disk])

    d = rand(Float32, n1, n2, n3)
    h = zeros(UInt8, headerlength(iojs), n2, n3)
    dd = Array{Array{Float32,2}}(n3)
    hh = Array{Array{UInt8,2}}(n3)
    for i = 1:n3
        dd[i] = d[:,:,i]
        hh[i] = h[:,:,i]
    end
    for i = 1:n3
        hhh = unsafe_wrap(Array, pointer(h, headerlength(iojs)*n2*(i-1)+1), (headerlength(iojs), n2), false)
        for j = 1:n2
            set!(prop(iojs, stockprop[:TRACE]), hh[i], j, j)
            set!(prop(iojs, stockprop[:FRAME]), hh[i], j, i)
            set!(prop(iojs, stockprop[:TRC_TYPE]), hh[i], j, tracetype[:live])
            set!(prop(iojs, stockprop[:TRACE]), hhh, j, j)
            set!(prop(iojs, stockprop[:FRAME]), hhh, j, i)
            set!(prop(iojs, stockprop[:TRC_TYPE]), hhh, j, tracetype[:live])
        end
    end

    bytes = n1*n2*(4*n3 + headerlength(iojs))
    stats = Array{Any}(0)

    # flat 1GB file
    io = open("$(disk)/test.bin", "w")
    write(io, d)
    write(io, h)
    close(io)
    rm("$(disk)/test.bin")
    write(STDOUT, "Write,Julia\n")
    x = @bench "Write,Julia" begin
        io = open("$(disk)/test.bin", "w")
        write(io, d)
        write(io, h)
        close(io)
    end
    push!(stats, identity(x))
    rm("$(disk)/test.bin")

    # flat 1GB of data using C
    fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test.bin", "wb")
    ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), d, 4, n1*n2*n3, fp)
    ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), h, 1, headerlength(iojs)*n2*n3, fp)
    ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    rm("$(disk)/test.bin")
    write(STDOUT, "Write,C\n")
    x = @bench "Write,C" begin
        fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test.bin", "wb")
        ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), d, 4, n1*n2*n3, fp)
        ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), h, 1, headerlength(iojs)*n2*n3, fp)
        ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    end
    push!(stats, identity(x))

    # collection of 100 10MB files
    for i = 1:n3
        io = open("$(disk)/test$(i).bin", "w")
        write(io, dd[i])
        write(io, hh[i])
        close(io)
    end
    for i = 1:n3
        rm("$(disk)/test$(i).bin")
    end
    write(STDOUT, "Write,Julia,Extents\n")
    x = @bench "Write,Julia,Extents" for i = 1:n3
        io = open("$(disk)/test$(i).bin", "w")
        write(io, dd[i])
        write(io, hh[i])
        close(io)
    end
    push!(stats, identity(x))
    for i = 1:n3
        rm("$(disk)/test$(i).bin")
    end

    # collection of 250 files using C
    for i = 1:n3
        fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test$(i).bin", "wb")
        ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), dd[i], 4, n1*n2, fp)
        ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), hh[i], 1, headerlength(iojs)*n2, fp)
        ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    end
    for i = 1:n3
        rm("$(disk)/test$(i).bin")
    end
    write(STDOUT, "Write,C,Extents\n")
    x = @bench "Write,C,Extents" for i = 1:n3
        fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test$(i).bin", "wb")
        ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), dd[i], 4, n1*n2, fp)
        ccall((:fwrite, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), hh[i], 1, headerlength(iojs)*n2, fp)
        ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    end
    push!(stats, identity(x))

    # JavaSeis, using writeframe with hdrs
    for i = 1:n3
        writeframe(iojs, dd[i], hh[i])
    end
    empty!(iojs)
    write(STDOUT, "Write,TeaSeis.jl::writeframe(io,trcs,hdrs)\n")
    x = @bench "Write,TeaSeis.jl::writeframe(io,trcs,hdrs)" for i = 1:n3
        writeframe(iojs, dd[i], hh[i])
    end
    push!(stats, identity(x))
    empty!(iojs)

    # JavaSeis, using writeframe without hdrs
    for i = 1:n3
        writeframe(iojs, dd[i], i)
    end
    empty!(iojs)
    write(STDOUT, "Write,TeaSeis.jl::writeframe(io,trcs,i)\n")
    x = @bench "Write,TeaSeis.jl::writeframe(io,trcs,i)" for i = 1:n3
        writeframe(iojs, dd[i], i)
    end
    push!(stats, identity(x))
    empty!(iojs)

    # JavaSeis, using write with hdrs
    write(iojs, d, h)
    empty!(iojs)
    write(STDOUT, "Write,TeaSeis.jl::write(io,d,h)\n")
    x = @bench "Write,TeaSeis.jl::write(io,d,h)" write(iojs, d, h)
    push!(stats, identity(x))
    empty!(iojs)

    # JavaSeis, using write without hdrs
    write(iojs, d, :, :, :)
    empty!(iojs)
    write(STDOUT, "Write,TeaSeis.jl::write(io,d,:,:,:)\n")
    x = @bench "Write,TeaSeis.jl::write(io,d,:,:,:)" write(iojs, d, :, :, :)
    push!(stats, identity(x))

    #
    # Read 1GB of samples
    #
    iojs = jsopen("test.js")

    # flat file
    io = open("$(disk)/test.bin")
    read!(io, d)
    close(io)
    write(STDOUT, "Read,Julia\n")
    x = @bench "Read,Julia" begin
        io = open("$(disk)/test.bin")
        read!(io, d)
        read!(io, h)
        close(io)
    end
    push!(stats, identity(x))

    # flat file, C
    fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test.bin", "rb")
    ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), d, 4, n1*n2*n3, fp)
    ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), h, 1, headerlength(iojs)*n2*n3, fp)
    ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)

    write(STDOUT, "Read,C\n")
    x = @bench "Read,C" begin
        fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test.bin", "rb")
        ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), d, 4, n1*n2*n3, fp)
        ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), h, 1, headerlength(iojs)*n2*n3, fp)
        ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    end
    push!(stats, identity(x))
    rm("$(disk)/test.bin")

    # many flat files
    for i = 1:n3
        io = open("$(disk)/test$(i).bin")
        read!(io, dd[i])
        read!(io, hh[i])
        close(io)
    end
    write(STDOUT, "Read,Julia,Extents\n")
    x = @bench "Read,Julia,Extents" for i = 1:n3
        io = open("$(disk)/test$(i).bin")
        read!(io, dd[i])
        read!(io, hh[i])
        close(io)
    end
    push!(stats, identity(x))

    # many flat files, C
    for i = 1:n3
        fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test$(i).bin", "rb")
        ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), dd[i], 4, n1*n2, fp)
        ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), hh[i], 1, headerlength(iojs)*n2, fp)
        ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    end
    write(STDOUT, "Read,C,Extents\n")
    x = @bench "Read,C,Extents" for i = 1:n3
        fp = ccall((:fopen, "libc"), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), "$(disk)/test$(i).bin", "rb")
        ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), dd[i], 4, n1*n2, fp)
        ccall((:fread, "libc"), UInt64, (Ptr{Void}, UInt64, UInt64, Ptr{Void}), hh[i], 1, headerlength(iojs)*n2, fp)
        ccall((:fclose, "libc"), Void, (Ptr{Void},), fp)
    end
    push!(stats, identity(x))

    for i = 1:n3
        rm("$(disk)/test$(i).bin")
    end

    # JavaSeis, one frame at a time
    for i = 1:n3
        readframe!(iojs, dd[i], hh[i], i)
    end
    write(STDOUT, "Read,TeaSeis.jl::readframe!(io,d,h,i)\n")
    x = @bench "Read,TeaSeis.jl::readframe!(io,d,h,i)" for i = 1:n3
        readframe!(iojs, dd[i], hh[i], i)
    end
    push!(stats, identity(x))

    # JavaSeis, all frames at once
    read!(iojs, d, h, :, :, :)
    write(STDOUT, "Read,TeaSeis.jl::read!(io,d,h,:,:,:)\n")
    x = @bench "Read,TeaSeis.jl::read!(io,d,h,:,:,:)" read!(iojs, d, h, :, :, :)
    push!(stats, identity(x))

    rm(jsopen("test.js"))

    stats, bytes
end

function datestamp()
    tms = TmStruct(time())
    mday = tms.mday+1 < 10 ? "0$(tms.mday+1)" : tms.mday+1
    mont = tms.month+1
    year = 1900+tms.year
    return "$(mont)-$(mday)-$(year)"
end

function makeplots(stats, bytes)
    titled = Array{String}(length(stats))
    ellapd = zeros(length(stats))
    allocd = zeros(length(stats))

    # all tests
    mbytes = bytes / (1024^2)
    for i = 1:length(stats)
        titled[i] = stats[i][1]
        ellapd[i] = mbytes / stats[i][2]
        allocd[i] = stats[i][3] / (1024^2)
    end

    # make a plot
    x = collect(1:length(ellapd))
    figure(1);close();figure(1,figsize=(12,8));
    subplot(121);bar(x,ellapd,align="center");ylabel("MB/s (more is better)");xticks(x,titled,rotation=90);title("I/O Speeds")
    subplot(122);bar(x,allocd,align="center");ylabel("MB (less is better)");xticks(x,titled,rotation=90);title("Allocated memory")
    subplots_adjust(bottom=.45)
    savefig("perf_teaseisio_3d.png")
end

disk="."
stats, bytes = main(disk)
@show stats

using PyPlot
makeplots(stats, bytes)
