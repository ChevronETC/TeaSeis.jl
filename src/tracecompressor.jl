mutable struct TraceCompressor{T}
    nsamples::Int
    nwindows::Int
    windowln::Int
end

function TraceCompressor(nsamples::Int, T::Type)
    if T == Int16
        windowln = 100
        nwindows = floor(Int, (nsamples - 1.0) / windowln) + 1
        TraceCompressor{T}(nsamples, nwindows, windowln)
    elseif T == Float32
        windowlen = nsamples
        nwindows = 1
        TraceCompressor{T}(nsamples, nwindows, windowlen)
    else
        error("only support Float32 and Int16 storage.")
    end
end

function packtrace!(c::TraceCompressor{Int16}, buff::IOBuffer, trace32::AbstractArray{Float32,1}, off::Int)
    k1, k2 = 0, 0
    nsamples = length(trace32)
    for i=1:c.nwindows
        # set sample range
        k1 = k2 + 1
        k2 = min(k1 + c.windowln - 1, nsamples)

        # max absolute value in windowa
        valuemax = 0.0
        for k = k1:k2
            valuemax = max(abs(trace32[k]), valuemax)
        end

        # set scale factor
        scalar = valuemax > 0.0 ? 32766.0 / valuemax : 0.0

        # write scale factor to buffer
        seek(buff, off + 4*(i-1))
        write(buff, Float32(scalar))

        # scale and write 16-bit values to buffer
        seek(buff, off + 4*c.nwindows + 2*(k1-1))
        for k = k1:k2
            write(buff, unsafe_trunc(Int16, 32767 + scalar * trace32[k]))
        end
    end
end

function unpacktrace!(c::TraceCompressor{Int16}, trace32::AbstractArray{Float32,1}, buff::IOBuffer, off::Int)
    k1, k2 = 0, 0
    nsamples = length(trace32)
    for i=1:c.nwindows
        # set sample range
        k1 = k2 + 1
        k2 = min(k1 + c.windowln - 1, nsamples)

        # set inverse scalar
        seek(buff, off + 4*(i-1))
        scalar = read(buff, Float32)
        scalar = scalar > 0.0 ? 1.0 / scalar : 0.0

        # scale 16-bit values to float values
        seek(buff, off + 4*c.nwindows + 2*(k1-1))
        for k=k1:k2
            val = read(buff,Int16)
            trace32[k] = scalar * unsafe_trunc(Int16, val - 32767.0)
        end
    end
end

function packframe!(c::TraceCompressor{Int16}, buff::IOBuffer, frame32::Array{Float32,2}, fld::Int)
    trcoff = tracelength(c)
    for i = 1:fld
        trace32 = view(frame32, :, i)
        off = (i - 1) * trcoff
        packtrace!(c, buff, trace32, off)
    end
end

function unpackframe!(c::TraceCompressor{Int16}, frame32::Array{Float32,2}, buff::IOBuffer, fld::Int)
    fill!(frame32, 0.0)
    trcoff = tracelength(c)
    for i = 1:fld
        off = (i - 1) * trcoff
        trace32 = view(frame32, :, i)
        unpacktrace!(c, trace32, buff, off)
    end
end

function allocframebuf(c::TraceCompressor{Int16}, ntraces::Int)
    bufarray = Array{UInt8}(undef, ntraces * tracelength(c))
    IOBuffer(bufarray, read=true, write=true, maxsize=length(bufarray))
end

tracelength(c::TraceCompressor{Int16})   = iseven(c.nsamples) == true ? 4 * c.nwindows + 2 * c.nsamples : 4 * c.nwindows + 2 * (c.nsamples + 1)
tracelength(c::TraceCompressor{Float32}) = 4 * c.nsamples
