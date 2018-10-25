using TeaSeis, BenchmarkTools, Random

const fs="."
const N1,N2,N3,N4,N5=100,11,12,2,3

makefname() = joinpath(fs, "teaseis-benchmarks-$(randstring())")
rmjsfile(f) = rm(jsopen(f))

const SUITE = BenchmarkGroup()

makeframe(T) = begin f=makefname();io=jsopen(f,"w",axis_lengths=[N1,N2,1],dataformat=T); writeframe(io, rand(Float32,N1,N2), 1); io,f end
makeframewrite(T) = begin io,f=makeframe(T); io,f,readframe(jsopen(f),1)... end
makeframeread(T) = begin io,f=makeframe(T); jsopen(f),f end
makeframeread!(T) = begin io,f=makeframe(T); jsopen(f),f,readframe(jsopen(f),1)... end

SUITE["Frame operations"] = BenchmarkGroup()
for T in (Float32,Int16)
    SUITE["Frame operations"]["write,$T"] = @benchmarkable writeframe(io,d,h) setup=begin io,f,d,h=makeframewrite($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["read,$T"] = @benchmarkable  readframe(io,1) setup=begin io,f=makeframeread($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["readtrcs,$T"] = @benchmarkable  readframetrcs(io,1) setup=begin io,f=makeframeread($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["readhdrs,$T"] = @benchmarkable  readframehdrs(io,1) setup=begin io,f=makeframeread($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["read!,$T"] = @benchmarkable  readframe!(io,d,h,1) setup=begin io,f,d,h=makeframeread!($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["readtrcs!,$T"] = @benchmarkable  readframetrcs!(io,d,1) setup=begin io,f,d,h=makeframeread!($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["readhdrs!,$T"] = @benchmarkable  readframehdrs!(io,h,1) setup=begin io,f,d,h=makeframeread!($T) end teardown=rmjsfile(f)

    SUITE["Frame operations"]["write,indexed,$T"] = @benchmarkable  writeframe(io,d,1) setup=begin io,f,d,h=makeframewrite($T) end teardown=rmjsfile(f)

    SUITE["Frame operations"]["allocframe,$T"] = @benchmarkable  allocframe(io) setup=begin io,f=makeframe($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["allocframetrcs,$T"] = @benchmarkable  allocframetrcs(io) setup=begin io,f=makeframe($T) end teardown=rmjsfile(f)
    SUITE["Frame operations"]["allocframehdrs,$T"] = @benchmarkable  allocframehdrs(io) setup=begin io,f=makeframe($T) end teardown=rmjsfile(f)

    SUITE["Frame operations"]["binary write,$T"] = @benchmarkable  begin io=open(f,"w");write(io,A);close(io) end setup=begin f=makefname();A=rand($T,$N1,$N2) end teardown=rm(f)
    SUITE["Frame operations"]["binary read!,$T"] = @benchmarkable  begin io=open(f);read!(io,A);close(io) end setup=begin f=makefname();A=rand($T,$N1,$N2);write(f,A) end teardown=rm(f)
end

makevolume(N,S) = begin f=makefname(); io=jsopen(f,"w",axis_lengths=[N...]); write(io, rand(Float32,N...), S...); io,f end
makevolumewrite(N,S) = begin io,f=makevolume(N,S); io,f,read(jsopen(f),S...)... end
makevolumeread(N,S) = begin io,f=makevolume(N,S); jsopen(f),f end
makevolumeread!(N,S) = begin io,f=makevolume(N,S); jsopen(f),f,read(jsopen(f),S...)... end

SUITE["Slice IO"] = BenchmarkGroup()
for (N,S) in (
        ((N1,N2,N3), (Colon(),Colon(),Colon())),
        ((N1,N2,N3,N4), (Colon(),Colon(),Colon(),Colon())),
        ((N1,N2,N3,N4,N5), (Colon(),Colon(),Colon(),Colon(),Colon()))
        )
    D = string(" ",length(N),"D")

    SUITE["Slice IO"][string("write",D)] = @benchmarkable write(io,d,h) setup=begin io,f,d,h=makevolumewrite($N,$S); end teardown=rmjsfile(f)
    SUITE["Slice IO"][string("writetrcs",D)] = @benchmarkable write(io,d,$(S)...) setup=begin io,f,d,h=makevolumewrite($N,$S) end teardown=rmjsfile(f)
    SUITE["Slice IO"][string("readtrcs",D)] = @benchmarkable readtrcs(io,$(S)...) setup=begin io,f=makevolumeread($N,$S) end teardown=rmjsfile(f)
    SUITE["Slice IO"][string("readtrcs!",D)] = @benchmarkable readtrcs!(io,d,$(S)...) setup=begin io,f,d,h=makevolumeread!($N,$S) end teardown=rmjsfile(f)
    SUITE["Slice IO"][string("readhdrs!",D)] = @benchmarkable readhdrs!(io,h,$(S)...) setup=begin io,f,d,h=makevolumeread!($N,$S) end teardown=rmjsfile(f)

    SUITE["Slice IO"][string("binary write",D)] = @benchmarkable begin io=open(f,"w");write(io,d);close(io) end setup=begin f=makefname(); d=rand(Float32,$(N)...) end teardown=rm(f)
    SUITE["Slice IO"][string("binary read!",D)] = @benchmarkable begin io=open(f);read!(io,d);close(io) end setup=begin d=zeros(Float32,$(N)...); f=makefname(); write(f,d) end teardown=rm(f)
end

function makepartialframe()
    f = makefname()
    io = jsopen(f,"w",axis_lengths=[N1,N2,1])
    d,h = allocframe(io)
    Random.seed!(0)
    rand!(d)
    alive = fill(false, N2)
    alive[randperm(N2)[1:div(N2,2)]] .= true
    for i = 1:N2
        set!(props(io,2), h, i, i)
        set!(props(io,3), h, i, 1)
        set!(prop(io,stockprop[:TRC_TYPE]), h, i, alive[i] ? tracetype[:live] : tracetype[:dead])
    end
    io,f,d,h
end

SUITE["Partial frame"] = BenchmarkGroup()

SUITE["Partial frame"]["leftjustify!"] = @benchmarkable leftjustify!(io, d, h) setup=begin io,f,d,h=makepartialframe() end teardown=rmjsfile(f)
SUITE["Partial frame"]["regularize!"] = @benchmarkable regularize!(io, d, h) setup=begin io,f,d,h=makepartialframe(); leftjustify!(io,d,h) end teardown=rmjsfile(f)
SUITE["Partial frame"]["fold"] = @benchmarkable fold(io,h) setup=begin io,f,d,h=makepartialframe() end teardown=rmjsfile(f)
SUITE["Partial frame"]["fold,1"] = @benchmarkable fold(io,1) setup=begin io,f,d,h=makepartialframe() end teardown=rmjsfile(f)
