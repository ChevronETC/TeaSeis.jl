using TeaSeis, Test, Random

ENV["JAVASEIS_DATA_HOME"] = ""
ENV["PROMAX_DATA_HOME"] = ""

rundir = "./tmp"
rm(rundir, recursive=true,force=true)
mkdir(rundir)
@testset "teaseisio Tests" begin
    # issue with tracetype of number other than 1 or 2.
    # The new expectation is that the leftjustify! method considers TRC_TYPE = 1 to be live
    # and TRC_TYPE != 1 to be not live.  The previous behavior was TRC_TYPE = 1 to be live
    # and TRC_TYPE = 2 to be dead.  The new behavior should be more robust than the old behavior.
    io = jsopen(joinpath(rundir,"data.js"), "w", axis_lengths=[10,11,1], axis_lstarts=[0,1000,500])
    trcs, hdrs = allocframe(io)
    rand!(trcs)
    for i = 1:3
        set!(prop(io,stockprop[:TRC_TYPE]), hdrs, i, 0)
    end
    for i = 4:8
        set!(prop(io,stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live])
        set!(prop(io,stockprop[:TRACE]), hdrs, i, 999+i)
        set!(prop(io,stockprop[:FRAME]), hdrs, i, 500)
    end
    for i = 9:11
        set!(prop(io,stockprop[:TRC_TYPE]), hdrs, i, tracetype[:dead])
    end
    trcs0 = copy(trcs)
    hdrs0 = copy(hdrs)
    leftjustify!(io, trcs, hdrs)
    @test trcs0[:,4:8] == trcs[:,1:5]
    @test hdrs0[:,4:8] == hdrs[:,1:5]
    rm(jsopen("$(rundir)/data.js"))

    # issue with large number of frames and a large number of extents
    io = jsopen(joinpath(rundir,"data.js"), "w", axis_lengths=[1501,701-301+1,648-248+1,5684], axis_lstarts=[1,301,248,1], dataformat=Int16, nextents=261670)
    trcs,hdrs = allocframe(io)
    rand!(trcs)
    map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live]), 1:307)
    map(i->set!(prop(io, stockprop[:TRC_TYPE]), hdrs, i, tracetype[:dead]), 308:401)
    map(i->set!(prop(io, stockprop[:TRACE])   , hdrs, i, i               ), 1:307)
    map(i->set!(prop(io, stockprop[:FRAME])   , hdrs, i, 251             ), 1:307)
    map(i->set!(prop(io, stockprop[:VOLUME])  , hdrs, i, 1001            ), 1:307)
    writeframe(io,trcs,hdrs)
    close(io)
    io = jsopen(joinpath(rundir, "data.js"))
    trcs_tst, hdrs_tst = readframe(io, 251, 1001)
    @test trcs[:,1:307] ≈ trcs_tst[:,1:307]
    @test hdrs[:,1:307] == hdrs_tst[:,1:307]
    rm(jsopen(joinpath(rundir, "data.js")))

    # issue with regularize function for non-unitary lstart
    io = jsopen(joinpath(rundir, "data.js"), "w", axis_lengths=[10,11,12], axis_lstarts=[0,1000,500], dataformat=Int16)
    trcs, hdrs = allocframe(io)
    for i = 1:12
        for j = 1:6
            set!(prop(io,stockprop[:TRC_TYPE]), hdrs, j, tracetype[:live])
            set!(prop(io,stockprop[:TRACE]), hdrs, j, 999+j)
            set!(prop(io,stockprop[:FRAME]), hdrs, j, 499+i)
        end
        for j = 7:11
            set!(prop(io,stockprop[:TRC_TYPE]), hdrs, j, tracetype[:dead])
        end
        writeframe(io, trcs, hdrs)
    end
    close(io)
    io = jsopen(joinpath(rundir, "data.js"))
    hdrs = view(readhdrs(io, :, :, 511), :, :, 1)
    for j = 1:6
        @test get(prop(io, stockprop[:TRACE]), hdrs, j) == 999+j
    end
    rm(jsopen(joinpath(rundir, "data.js")))

    # issue with regularize function for non-unitary lstart
    io = jsopen(joinpath(rundir, "data.js"), "w", axis_lengths=[10,11,12], axis_lstarts=[0,1000,500], dataformat=Int16)
    @test io.description == "data"
    close(io)
    rm(jsopen(joinpath(rundir, "data.js")))
    io = jsopen(joinpath(rundir, "group@data.js"), "w", axis_lengths=[10,11,12], axis_lstarts=[0,1000,500], dataformat=Int16)
    @test io.description == "data"
    close(io)
    rm(jsopen(joinpath(rundir, "group@data.js")))
    io = jsopen(joinpath(rundir, "group@data.js"), "w", axis_lengths=[10,11,12], axis_lstarts=[0,1000,500], dataformat=Int16, description="group@data")
    @test io.description == "group@data"
    close(io)
    rm(jsopen(joinpath(rundir, "group@data.js")))

    # fileset that does not have a correct sample header, passes abstract string to TracePropertyDef
    pdef = TracePropertyDef(split("hello world")[1], split("again again")[1], Int32, 1)
    @test pdef.label == "hello"
    @test pdef.description == "again"

    # description should always be in quotes in FileProperties.xml, but with no quotes when read in:
    pdef = TracePropertyDef("HDR", "HDR DESCRIPTON", Int32, 1)
    io = jsopen(joinpath(rundir, "data.js"), "w", axis_lengths=[10,11,12], properties=[pdef])
    close(io)
    io = jsopen(joinpath(rundir, "data.js"))
    @test strip(prop(io,"HDR").def.description, ['"']) == prop(io,"HDR").def.description
    close(io)
    io = jsopen(joinpath(rundir, "data2.js"), "w", similarto="$(rundir)/data.js")
    @test strip(prop(io,"HDR").def.description, ['"']) == prop(io,"HDR").def.description
    close(io)
    rm(jsopen(joinpath(rundir, "data.js")))
    rm(jsopen(joinpath(rundir, "data2.js")))

    # create/open an existing incomplete/corrupted data-set
    isdir(joinpath(rundir, "data-dummy.js")) && rm("$(rundir)/data-dummy.js", recursive=true)
    mkdir(joinpath(rundir, "data-dummy.js"))
    touch(joinpath(rundir, "data-dummy.js/nothing"))
    jsopen(joinpath(rundir, "data-dummy.js"), "w", axis_lengths=[1,2,3])
    @test size(jsopen(joinpath(rundir, "data-dummy.js"))) == (1,2,3)
    rm(jsopen(joinpath(rundir, "data-dummy.js")))

    isdir(joinpath(rundir, "data-dummy.js")) && rm("$(rundir)/data-dummy.js", recursive=true)
    mkdir(joinpath(rundir, "data-dummy.js"))
    touch(joinpath(rundir, "data-dummy.js/nothing"))
    jscreate(joinpath(rundir, "data-dummy.js"), axis_lengths=[1,2,3])
    @test size(jsopen(joinpath(rundir, "data-dummy.js"))) == (1,2,3)
    rm(jsopen(joinpath(rundir, "data-dummy.js")))

    # repeated in-place read of frames with different folds
    jscreate(joinpath(rundir, "data.js"), axis_lengths=[10,11,12])
    io = jsopen(joinpath(rundir, "data.js"), "r+")
    trcs,hdrs = allocframe(io)
    for i = 1:size(io,2)
        set!(props(io,2), hdrs, i, i)
        set!(props(io,3), hdrs, i, 1)
        set!(prop(io,stockprop[:TRC_TYPE]), hdrs, i, tracetype[:live])
    end
    writeframe(io, trcs, hdrs)
    for i = 1:size(io,2)
        set!(props(io,2), hdrs, i, i)
        set!(props(io,3), hdrs, i, 2)
        set!(prop(io,stockprop[:TRC_TYPE]), hdrs, i, i<6 ? tracetype[:live] : tracetype[:dead])
    end
    writeframe(io, trcs, hdrs)
    trcs,hdrs = allocframe(io)
    readframe!(io, trcs, hdrs, 1)
    @test fold(io, hdrs) == 11
    @test fold(io, 1) == 11
    readframe!(io, trcs, hdrs, 2)
    @test fold(io, hdrs) == 5
    @test fold(io, 2) == 5
    readframe!(io, trcs, hdrs, 3)
    @test fold(io, hdrs) == 0
    @test fold(io, 3) == 0
    rm(jsopen(joinpath(rundir,"data.js")))

    # don't fail on a corrupt status file
    io = jsopen(joinpath(rundir, "data.js"), "w", axis_lengths=[10,11,12])
    io = open(joinpath(rundir, "data.js", "Status.properties"))
    lines = readlines(io)
    close(io)
    io = open(joinpath(rundir,"data.js", "Status.properties"),"w")
    for line in lines
        if !startswith(line,"#")
            write(io,split(line,'=')[1]*"\n")
        else
            write(io,line*"\n")
        end
    end
    close(io)
    @test_warn "" jsopen(joinpath(rundir,"data.js"))
    rm(jsopen(joinpath(rundir,"data.js")))

    @testset "lstrt=$(lstrt),lincrs=$(lincrs),sz=$(sz),second=$(second),T=$(T)" for lstrt in ([1,1,1,1,1], [10,20,30,40,50]), lincrs in ([1,1,1,1,1],[1,2,3,4,5]), sz in ([5,6,7], [5,6,7,8], [5,6,7,8,9]), second in (["."],["$(rundir)/second"]), T in (Float32, Int16)
        write(stdout, "lstrt=$(lstrt),lincrs=$(lincrs),sz=$(sz),second=$(second),T=$(T)\n")
        labls = ["SAMPLE", "TRACE", "FRAME", "VOLUME", "HYPRCUBE"]
        pdefs = [stockprop[:SAMPLE], stockprop[:TRACE], stockprop[:FRAME], stockprop[:VOLUME], stockprop[:HYPRCUBE]]
        unts  = [stockunit[:UNKNOWN], "unknown", "unknown", "unknown", "unknown"]
        domns = [stockdomain[:UNKNOWN], "unknown", "unknown", "unknown", "unknown"]
        pstrt = [0.0, 0.0, 0.0, 0.0, 0.0]
        pincrs = [1.0, 1.0, 1.0, 1.0, 1.0]

        filename1 = "$(rundir)/file-1-$(randstring()).js"
        propF32  = TracePropertyDef("PF32",  "PF32X",  Float32)
        propF64  = TracePropertyDef("PF64",  "PF64X",  Float64)
        propI32  = TracePropertyDef("PI32",  "PI32X",  Int32)
        propI64  = TracePropertyDef("PI64",  "PI64X",  Int64)
        propVF32 = TracePropertyDef("PVF32", "PVF32X", Vector{Float32}, 2)
        propVF64 = TracePropertyDef("PVF64", "PVF64X", Vector{Float64}, 2)
        propVI32 = TracePropertyDef("PVI32", "PVI32X", Vector{Int32}, 2)
        propVI64 = TracePropertyDef("PVI64", "PVI64X", Vector{Int64}, 2)
        propSTR  = TracePropertyDef("PSTR",  "PSTRX",  Vector{UInt8}, 10)

        propSTD  = TracePropertyDef("PSTD")
        @test propSTD.label == "PSTD"
        @test propSTD.description == ""
        @test propSTD.format == Int32
        @test propSTD.elementcount == 1

        io = jsopen(filename1, "w", axis_lengths=sz, properties=[propF32, propF64, propI32, propI64, propVF32, propVF64, propVI32, propVI64, propSTR], secondaries=second, nextents=3, dataformat=T, axis_lstarts=lstrt[1:length(sz)], axis_lincs=lincrs[1:length(sz)])
        n = length(sz)

        #
        # convenience function tests
        #
        @test ndims(io) == n
        @test length(io) == prod(sz[3:end])
        map(i->begin @test size(io)[i] == sz[i] end, 1:n)
        map(i->begin @test labels(io)[i] == labls[i] end, 1:n)
        map(i->begin @test units(io)[i] == unts[i] end, 1:n)
        map(i->begin @test domains(io)[i] == domns[i] end, 1:n)
        map(i->begin @test propdefs(io)[i] == pdefs[i] end, 1:n)
        map(i->begin @test props(io)[i] == prop(io,pdefs[i]) end, 1:n)
        map(i->begin @test pstarts(io)[i] ≈ pstrt[i] end, 1:n)
        map(i->begin @test pincs(io)[i] ≈ pincrs[i] end, 1:n)
        map(i->begin @test lstarts(io)[i] == lstrt[i] end, 1:n)
        map(i->begin @test lincs(io)[i] == lincrs[i] end, 1:n)
        map(i->begin @test lrange(io)[i] == lstrt[i]:lincrs[i]:(lstrt[i]+(sz[i]-1)*lincrs[i]) end, 1:n)
        map(i->begin @test size(io,i) == size(io)[i] end, 1:n)
        map(i->begin @test labels(io,i) == labels(io)[i] end, 1:n)
        map(i->begin @test units(io,i) == units(io)[i] end, 1:n)
        map(i->begin @test domains(io,i) == domains(io)[i] end, 1:n)
        map(i->begin @test propdefs(io,i) == propdefs(io)[i] end, 1:n)
        map(i->begin @test props(io,i) == props(io)[i] end, 1:n)
        map(i->begin @test pstarts(io,i) == pstarts(io)[i] end, 1:n)
        map(i->begin @test pincs(io,i) == pincs(io)[i] end, 1:n)
        map(i->begin @test lstarts(io,i) == lstarts(io)[i] end, 1:n)
        map(i->begin @test lincs(io,i) == lincs(io)[i] end, 1:n)
        map(i->begin @test lrange(io,i) == lstrt[i]:lincrs[i]:(lstrt[i]+(sz[i]-1)*lincrs[i]) end, 1:n)
        @test in("DOESNOTEXIST",io) == false
        @test in("TRACE",io) == true
        @test in("PF32",io) == true
        @test in(props(io,1),io) == true
        @test in(propdefs(io,1),io) == true

        #
        # trace map tests:
        #
        @test isfile(joinpath(filename1, "TraceMap"))
        @test filesize(joinpath(filename1, "TraceMap")) == prod(sz[3:end]) * sizeof(Int32)
        @test io.mapped == true
        iotrcmp = open(joinpath(filename1, "TraceMap"))
        @test read!(iotrcmp,Array{Int32}(undef,prod(sz[3:end]))) == zeros(Int32,prod(sz[3:end]))
        close(iotrcmp)

        #
        # extents tests:
        #
        @test length(io.trcextents) == length(io.hdrextents)
        @test mapreduce(i->io.trcextents[i].size, +, 1:length(io.trcextents)) == prod(size(io)[2:end]) * TeaSeis.tracelength(io)
        @test mapreduce(i->io.hdrextents[i].size, +, 1:length(io.hdrextents)) == prod(size(io)[2:end]) * headerlength(io)

        #
        # memory allocation tests:
        #
        @test size(allocframetrcs(io)) == (sz[1],sz[2])
        @test size(allocframehdrs(io)) == (headerlength(io),sz[2])
        @test isa(allocframetrcs(io),Array{Float32,2}) == true
        @test isa(allocframehdrs(io),Array{UInt8,2}) == true
        trcs, hdrs = allocframe(io)
        @test size(trcs) == (sz[1],sz[2])
        @test size(hdrs) == (headerlength(io),sz[2])
        @test isa(trcs, Array{Float32,2}) == true
        @test isa(hdrs, Array{UInt8,2}) == true
        trcs = allocframetrcs(io)
        hdrs = allocframehdrs(io)
        @test size(trcs) == (sz[1],sz[2])
        @test size(hdrs) == (headerlength(io),sz[2])
        @test isa(trcs, Array{Float32,2}) == true
        @test isa(hdrs, Array{UInt8,2}) == true

        #
        # test ind2sub and sub2ind
        #
        if ndims(io) == 3
            for i3 = 1:sz[3]
                @test ind2sub(io,i3) == (lstrt[3]+(i3-1)*lincrs[3],)
                @test sub2ind(io,(lstrt[3]+(i3-1)*lincrs[3],)) == i3
            end
        elseif ndims(io) == 4
            for i4 = 1:sz[4], i3 = 1:sz[3]
                @test ind2sub(io,(i4-1)*sz[3]+i3) == (lstrt[3]+(i3-1)*lincrs[3],lstrt[4]+(i4-1)*lincrs[4])
                @test sub2ind(io,(lstrt[3]+(i3-1)*lincrs[3],lstrt[4]+(i4-1)*lincrs[4])) == (i4-1)*sz[3]+i3
            end
        elseif ndims(io) == 5
            for i5 = 1:sz[5], i4 = 1:sz[4], i3 = 1:sz[3]
                @test ind2sub(io,(i5-1)*sz[4]*sz[3]+(i4-1)*sz[3]+i3) == (lstrt[3]+(i3-1)*lincrs[3],lstrt[4]+(i4-1)*lincrs[4],lstrt[5]+(i5-1)*lincrs[5])
                @test sub2ind(io,(lstrt[3]+(i3-1)*lincrs[3],lstrt[4]+(i4-1)*lincrs[4],lstrt[5]+(i5-1)*lincrs[5])) == (i5-1)*sz[4]*sz[3]+(i4-1)*sz[3]+i3
            end
        end

        #
        # frame based write test, explicit fold and headers, multiple extents
        #
        trcs = rand(Float32,sz...)
        hdrs = allocframehdrs(io)
        @test isempty(io) == true
        for i = 1:length(io)
            idxs = ind2sub(io,i)
            map(itrc->set!(prop(io,stockprop[:TRC_TYPE]), hdrs, itrc, tracetype[:live]  ), 1:sz[2])
            map(itrc->set!(prop(io,stockprop[:TRACE]),    hdrs, itrc, lrange(io,2)[itrc]), 1:sz[2])
            map(itrc->set!(prop(io,stockprop[:FRAME]),    hdrs, itrc, idxs[1]           ), 1:sz[2])
            if n > 3
                map(itrc->set!(prop(io,stockprop[:VOLUME]), hdrs, itrc, idxs[2]), 1:sz[2])
            end
            if n > 4
                map(itrc->set!(prop(io,stockprop[:HYPRCUBE]), hdrs, itrc, idxs[3]), 1:sz[2])
            end
            map(itrc->set!(prop(io,propF32),  hdrs, itrc, itrc          ), 1:sz[2])
            map(itrc->set!(prop(io,propF64),  hdrs, itrc, itrc          ), 1:sz[2])
            map(itrc->set!(prop(io,propI32),  hdrs, itrc, itrc          ), 1:sz[2])
            map(itrc->set!(prop(io,propI64),  hdrs, itrc, itrc          ), 1:sz[2])
            map(itrc->set!(prop(io,propI64),  hdrs, itrc, [itrc]        ), 1:sz[2]) # set single property from array of length 1
            map(itrc->set!(prop(io,propVF32), hdrs, itrc, [itrc,idxs[1]]), 1:sz[2])
            map(itrc->set!(prop(io,propVF64), hdrs, itrc, [itrc,idxs[1]]), 1:sz[2])
            map(itrc->set!(prop(io,propVI32), hdrs, itrc, [itrc,idxs[1]]), 1:sz[2])
            map(itrc->set!(prop(io,propVI64), hdrs, itrc, [itrc,idxs[1]]), 1:sz[2])
            map(itrc->set!(prop(io,propSTR), hdrs, itrc, "TEST"         ), 1:sz[2])
            writeframe(io, reshape(trcs[:,:,CartesianIndices(size(io)[3:end])[i]],sz[1],sz[2]), hdrs)
            @test isempty(io) == false
        end

        # ensure TraceMap was correctly written
        iotrcmap = open(joinpath(filename1, "TraceMap"))
        @test read!(iotrcmap, Array{Int32}(undef,length(io))) == sz[2]*ones(Int32,prod(sz[3:end]))
        close(iotrcmap)

        # ensure that the trace extents were written properly
        @test length(io.trcextents) == 3
        @test length(io.trcextents) == length(io.hdrextents)
        for i = 1:length(io.trcextents)
            @test io.trcextents[i].name == "TraceFile$(i-1)"
            @test io.hdrextents[i].name == "TraceHeaders$(i-1)"
            @test isfile(io.trcextents[i].path) == true
            @test filesize(io.trcextents[i].path) == io.trcextents[i].size

            if T == Float32
                ioext = open(io.trcextents[i].path)
                trcstest = convert(Array{Float32,1}, read!(ioext, Array{T}(undef, div(io.trcextents[i].size, sizeof(T)))))
                close(ioext)
                strt = div(io.trcextents[i].start, sizeof(T)) + 1
                stop = strt + div(io.trcextents[i].size, sizeof(T)) - 1
                @test length(trcstest) == length(vec(trcs[strt:stop]))
                @test trcstest ≈ vec(trcs[strt:stop])
            end
            # TODO -- to test the above for 16 bit will need to make use of the trace compressor
        end

        #
        # read test, explicit fold and headers, multiple extents
        #
        close(io)
        io = jsopen(filename1)

        # trace map via fold meethod
        for i = 1:length(io)
            @test fold(io, ind2sub(io,i)...) == sz[2]
        end

        # frame based read
        for i = 1:length(io)
            idxs = ind2sub(io,i)
            trcstest, hdrs = readframe(io, idxs...)
            @test typeof(trcstest) == Array{Float32,2}
            @test typeof(hdrs) == Array{UInt8,2}
            @test size(trcstest) == (sz[1],sz[2])
            @test size(hdrs) == (headerlength(io),sz[2])
            @test vec(trcstest) ≈ vec(trcs[:,:,CartesianIndices(size(io)[3:end])[i]])
            for itrc = 1:sz[2]
                @test get(prop(io,stockprop[:TRACE]), hdrs, itrc) == lstrt[2] + (itrc-1)*lincrs[2]
                @test get(prop(io,stockprop[:FRAME]), hdrs, itrc) == idxs[1]
                @test get(prop(io,stockprop[:TRC_TYPE]), hdrs, itrc) == tracetype[:live]
                @test get(prop(io,stockprop[:TRACE]), hdrs[:,itrc]) == lstrt[2] + (itrc-1)*lincrs[2]
                @test get(prop(io,stockprop[:FRAME]), hdrs[:,itrc]) == idxs[1]
                @test get(prop(io,stockprop[:TRC_TYPE]), hdrs[:,itrc]) == tracetype[:live]
                @test get(prop(io,"PF32"), hdrs, itrc) ≈ itrc
                @test get(prop(io,"PF64"), hdrs, itrc) ≈ itrc
                @test get(prop(io,"PI32"), hdrs, itrc) ≈ itrc
                @test get(prop(io,"PI64"), hdrs, itrc) ≈ itrc
                @test get(prop(io,"PVF32"), hdrs, itrc) ≈ [itrc, idxs[1]]
                @test get(prop(io,"PVF64"), hdrs, itrc) ≈ [itrc, idxs[1]]
                @test get(prop(io,"PVI32"), hdrs, itrc) ≈ [itrc, idxs[1]]
                @test get(prop(io,"PVI64"), hdrs, itrc) ≈ [itrc, idxs[1]]
                @test get(prop(io,"PSTR"), hdrs, itrc) == "TEST"
            end

            # alternative frame based read methods:
            @test trcstest ≈ readframetrcs(io, idxs...)
            @test hdrs == readframehdrs(io, idxs...)
            trcstest2, hdrstest = allocframe(io)
            @test readframe!(io, trcstest2, hdrstest, idxs...) == sz[2]
            @test trcstest2 ≈ trcstest
            @test hdrstest == hdrs
            @test readframetrcs!(io, trcstest2, idxs...) == sz[2]
            @test readframehdrs!(io, hdrstest, idxs...) == sz[2]
            @test trcstest2 ≈ trcstest
            @test hdrstest == hdrs
        end

        #
        # write/read test using alternative API's -- TODO: flesh this out
        #
        if n == 3
            write(io, trcs, :, :, :)
            @test readtrcs(io, :, :, :) ≈ trcs
            write(io, trcs[:,:,1:1], :, :, lstrt[3])
            @test readtrcs(io, :, :, lstrt[3]) ≈ trcs[:,:,1:1]
            trcstst, hdrs = read(io, :, :, :)
            @test trcs ≈ trcstst
            write(io, 2*trcs[:,1:4,2:2], :, lstrt[2]:lincrs[2]:(lstrt[2]+3*lincrs[2]), (lstrt[3]+1*lincrs[3]):lincrs[3]:(lstrt[3]+1*lincrs[3]))
            trcstst, hdrs = read(io, :, lstrt[2]:lincrs[2]:(lstrt[2]+3*lincrs[2]), (lstrt[3]+1*lincrs[3]):lincrs[3]:(lstrt[3]+1*lincrs[3]))
            @test vec(trcstst) ≈ vec(2*trcs[:,1:4,2])
            trcstst, hdrstst = read(io,lstrt[1]:lincrs[1]:(lstrt[1]+lincrs[1]),lstrt[2]:lincrs[2]:(lstrt[2]+lincrs[2]),lstrt[3]:lincrs[3]:(lstrt[3]+lincrs[3]))
            write(io, trcstst, hdrstst, lstrt[1]:lincrs[1]:(lstrt[1]+lincrs[1]))
            trcs = readtrcs(io,:,:,:)
            @test trcstst ≈ trcs[1:2,1:2,1:2]
        elseif n == 4
            write(io, trcs, :, :, :, :)
            @test readtrcs(io, :, :, :, :) ≈ trcs
            write(io, trcs[:,:,:,1:1], :, :, :, lstrt[4])
            @test readtrcs(io, :, :, :, lstrt[4]) ≈ trcs[:,:,:,1:1]
            trcstst, hdrs = read(io, :, :, :, :)
            @test trcs ≈ trcstst
            write(io, 2*trcs[:,1:4,2:2,1:3], :, lstrt[2]:lincrs[2]:(lstrt[2]+3*lincrs[2]), (lstrt[3]+1*lincrs[3]):lincrs[3]:(lstrt[3]+1*lincrs[3]), lstrt[4]:lincrs[4]:(lstrt[4]+2*lincrs[4]))
            trcstst, hdrs = read(io, :, lstrt[2]:lincrs[2]:(lstrt[2]+3*lincrs[2]), (lstrt[3]+1*lincrs[3]):lincrs[3]:(lstrt[3]+1*lincrs[3]), lstrt[4]:lincrs[4]:(lstrt[4]+2*lincrs[4]))
            @test vec(trcstst) ≈ vec(2*trcs[:,1:4,2:2,1:3])
            trcstst, hdrstst = read(io,lstrt[1]:lincrs[1]:(lstrt[1]+lincrs[1]),lstrt[2]:lincrs[2]:(lstrt[2]+lincrs[2]),lstrt[3]:lincrs[3]:(lstrt[3]+lincrs[3]),lstrt[4]:lincrs[4]:(lstrt[4]+lincrs[4]))
            write(io, trcstst, hdrstst, lstrt[1]:lincrs[1]:(lstrt[1]+lincrs[1]))
            trcs = readtrcs(io,:,:,:,:)
            @test trcstst ≈ trcs[1:2,1:2,1:2,1:2]
        elseif n == 5
            write(io, trcs, :, :, :, :, :)
            @test readtrcs(io, :, :, :, :, :) ≈ trcs
            write(io, trcs[:,:,:,:,1:1], :, :, :, :, lstrt[5])
            @test readtrcs(io, :, :, :, :, lstrt[5]) ≈ trcs[:,:,:,:,1:1]
            trcstst, hdrs = read(io, :, :, :, :, :)
            @test trcs ≈ trcstst
            write(io, 2*trcs[:,1:4,2:2,1:3,1:2], :, lstrt[2]:lincrs[2]:(lstrt[2]+3*lincrs[2]), (lstrt[3]+1*lincrs[3]):lincrs[3]:(lstrt[3]+1*lincrs[3]), lstrt[4]:lincrs[4]:(lstrt[4]+2*lincrs[4]), lstrt[5]:lincrs[5]:(lstrt[5]+1*lincrs[5]))
            trcstst, hdrs = read(io, :, lstrt[2]:lincrs[2]:(lstrt[2]+3*lincrs[2]), (lstrt[3]+1*lincrs[3]):lincrs[3]:(lstrt[3]+1*lincrs[3]), lstrt[4]:lincrs[4]:(lstrt[4]+2*lincrs[4]), lstrt[5]:lincrs[5]:(lstrt[5]+1*lincrs[5]))
            @test vec(trcstst) ≈ vec(2*trcs[:,1:4,2:2,1:3,1:2])
            trcstst, hdrstst = read(io,lstrt[1]:lincrs[1]:(lstrt[1]+lincrs[1]),lstrt[2]:lincrs[2]:(lstrt[2]+lincrs[2]),lstrt[3]:lincrs[3]:(lstrt[3]+lincrs[3]),lstrt[4]:lincrs[4]:(lstrt[4]+lincrs[4]),lstrt[5]:lincrs[5]:(lstrt[5]+lincrs[5]))
            write(io, trcstst, hdrstst, lstrt[1]:lincrs[1]:(lstrt[1]+lincrs[1]))
            trcs = readtrcs(io,:,:,:,:,:)
            @test trcstst ≈ trcs[1:2,1:2,1:2,1:2,1:2]
        end

        filename6 = joinpath(rundir, "file-6-" * randstring() * ".js")
        jscreate(filename6, similarto=filename1)
        io2 = jsopen(filename6, "r+")
        if n == 3
            @test fold(io2, lstrt[3]) == 0
            write(io2, trcs[:,:,1:1], :, :, lstrt[3])
            @test fold(io2, lstrt[3]) == size(io2, 2)
        elseif n == 4
            @test fold(io2, lstrt[3], lstrt[4]) == 0
            write(io2, trcs[:,:,1:1,1:1], :, :, lstrt[3], lstrt[4])
            @test fold(io2, lstrt[3], lstrt[4]) == size(io2, 2)
        elseif n == 5
            @test fold(io2, lstrt[3], lstrt[4], lstrt[5]) == 0
            write(io2, trcs[:,:,1:1,1:1,1:1], :, :, lstrt[3], lstrt[4], lstrt[5])
            @test fold(io2, lstrt[3], lstrt[4], lstrt[5]) == size(io2, 2)
        end
        rm(jsopen(filename6))

        #
        # similar method tests, TODO -- more of these
        #
        filename3 = joinpath(rundir, "file-3-" * randstring() * ".js")
        filename4 = joinpath(rundir, "file-4-" * randstring() * ".js")
        filename5 = joinpath(rundir, "file-5-" * randstring() * ".js")
        io3 = jsopen(filename3, "w", similarto=filename1)
        io4 = jsopen(filename4, "w", similarto=filename1, axis_lengths=[9,10,11,12,13][1:n], axis_lincs=[1,2,1,2,1][1:n])
        io5 = jsopen(filename5, "w", similarto=filename1, properties_add = [stockprop[:CDP_X]])
        for iox in (io3, io4, io5)
            @test io.mapped == iox.mapped
            @test io.datatype == iox.datatype
            @test io.dataformat == iox.dataformat
            @test io.dataorder == iox.dataorder
            if iox == io4
                @test [9,10,11,12,13][1:n] == iox.axis_lengths
            else
                @test io.axis_lengths == iox.axis_lengths
            end
            @test length(io.axis_propdefs) == length(iox.axis_propdefs)
            for i = 1:length(io.axis_propdefs)
                @test io.axis_propdefs[i].label == iox.axis_propdefs[i].label
                @test io.axis_propdefs[i].description == iox.axis_propdefs[i].description
                @test io.axis_propdefs[i].format == iox.axis_propdefs[i].format
                @test io.axis_propdefs[i].elementcount == iox.axis_propdefs[i].elementcount
            end
            @test io.axis_units == iox.axis_units
            @test io.axis_domains == iox.axis_domains
            @test io.axis_lstarts == iox.axis_lstarts
            if iox == io4
                @test [1,2,1,2,1][1:n] == iox.axis_lincs
            else
                @test io.axis_lincs == iox.axis_lincs
            end
            @test io.axis_pstarts ≈ iox.axis_pstarts
            @test io.axis_pincs ≈ iox.axis_pincs
            if iox == io3 || iox == io4
                @test length(io.properties) == length(iox.properties)
                for i = 1:length(io.properties)
                    @test io.properties[i].byteoffset == iox.properties[i].byteoffset
                    @test io.properties[i].def.label == iox.properties[i].def.label
                    @test io.properties[i].def.description == iox.properties[i].def.description
                    @test io.properties[i].def.format == iox.properties[i].def.format
                    @test io.properties[i].def.elementcount == iox.properties[i].def.elementcount
                end
            end
            @test geometry(io) == nothing
            @test geometry(iox) == nothing
            @test typeof(io.compressor) == typeof(iox.compressor)

            @test length(io.secondaries) == length(iox.secondaries)
            for i = 1:length(io.secondaries)
                @test io.secondaries[i] == iox.secondaries[i]
            end

            for i = 1:length(iox.secondaries)
                extentdir = TeaSeis.extentdir(iox.secondaries[i], filename3)
                if io.secondaries[i] == "."
                    @test length(readdir(extentdir)) == 7
                else
                    @test length(readdir(extentdir)) == 0
                end
            end

            for i = 1:length(iox)
                @test fold(iox,ind2sub(iox,i)...) == 0
            end

            if iox == io5
                @test in(stockprop[:CDP_X], iox)
            end
        end

        #
        # clean-up
        #
        for fname in (filename1, filename3, filename4, filename5)
            rm(jsopen(fname))
            @test isdir(fname) == false
        end

        #
        # repeat above tests for sparse layout
        #
        io = jsopen(filename1, "w", axis_lengths=sz, nextents=3, dataformat=T)
        indexes = map(i->sort(randperm(sz[i]))[1:div(sz[i],2)], 2:length(sz))
        sz_sparse = [div(sz[i],2) for i = 1:n]
        sz_sparse[1] = sz[1]

        frmtrcs, hdrs = allocframe(io)
        for idx in CartesianIndices(ntuple(i->sz_sparse[2+i],n-2))
            jtrc = 1
            for itrc = 1:sz[2]
                if jtrc <= sz_sparse[2] && itrc == indexes[1][jtrc]
                    frmtrcs[:,itrc] = trcs[:,itrc,idx.I...]
                    set!(prop(io,stockprop[:TRACE]), hdrs, itrc, itrc)
                    for k = 1:length(idx)
                        set!(prop(io,labls[2+k]), hdrs, itrc, idx.I[k])
                    end
                    set!(prop(io,stockprop[:TRC_TYPE]), hdrs, itrc, tracetype[:live])
                    jtrc += 1
                else
                    set!(prop(io,stockprop[:TRC_TYPE]), hdrs, itrc, tracetype[:dead])
                end
            end
            if fold(io,hdrs) > 0
                leftjustify!(io, frmtrcs, hdrs)
                @test sz_sparse[2] == writeframe(io, frmtrcs, hdrs)
            end
        end

        close(io)

        #
        # TODO -- test sparse write without relying on read methods
        #

        #
        # read test, explicit fold and headers, multiple extents
        #
        io = jsopen(filename1)
        for idx in CartesianIndices(ntuple(i->sz_sparse[2+i], n-2))
            fld = readframe!(io, frmtrcs, hdrs, idx.I...)
            @test fld == sz_sparse[2]
            for jtrc = 1:sz_sparse[2]
                @test get(prop(io,stockprop[:TRC_TYPE]), hdrs, jtrc) == tracetype[:live]
                @test vec(frmtrcs[:,jtrc]) ≈ vec(trcs[:,indexes[1][jtrc],idx.I...])
            end
            regularize!(io, frmtrcs, hdrs)
            for itrc in indexes[1]
                @test get(prop(io,stockprop[:TRC_TYPE]), hdrs, itrc) == tracetype[:live]
                for k = 3:length(sz)
                    @test get(prop(io,labls[k]), hdrs, itrc) == idx.I[k-2]
                end
                @test get(prop(io,stockprop[:TRACE]), hdrs, itrc) == itrc
                @test vec(frmtrcs[:,itrc]) ≈ vec(trcs[:,itrc,idx.I...])
            end
        end

        #
        # header copy test
        #
        hdrs  = readframehdrs(io,ind2sub(io,1)...)
        hdrs2 = readframehdrs(io,ind2sub(io,2)...)
        fill!(hdrs2,0)
        copy!(io,hdrs2,io,hdrs)
        @test hdrs == hdrs2

        #
        # test cp and mv
        #

        # with current secondary
        for second in (nothing, [joinpath(rundir, "newsec")])
            filename1cp = joinpath(rundir, "file-1-cp-$(randstring()).js")
            filename1mv = joinpath(rundir, "file-1-mv-$(randstring()).js")
            cp(jsopen(filename1), filename1cp, secondaries=second)
            iocp = jsopen(filename1cp, "r")
            @test length(io) == length(iocp)
            @test size(io) == size(iocp)
            @test lincs(io) == lincs(iocp)
            @test lstarts(io) == lstarts(iocp)
            @test pstarts(io) == pstarts(iocp)
            @test pincs(io) == pincs(iocp)
            trcsor, hdrsor = allocframe(io)
            trcscp, hdrscp = allocframe(iocp)
            for i = 1:length(io)
                fldor = readframe!(io, trcsor, hdrsor, ind2sub(io, i)...)
                fldcp = readframe!(iocp, trcscp, hdrscp, ind2sub(iocp, i)...)
                @test fldor == fldcp
                @test trcsor ≈ trcscp
                @test hdrsor == hdrscp
            end

            mv(jsopen(filename1cp), filename1mv, secondaries=second)
            @test isdir(filename1cp) == false
            for i = 1:length(iocp.secondaries)
                @test isdir(TeaSeis.extentdir(iocp.secondaries[i], iocp.filename)) == false
            end

            iomv = jsopen(filename1mv, "r")
            @test length(io) == length(iomv)
            @test size(io) == size(iomv)
            @test lincs(io) == lincs(iomv)
            @test lstarts(io) == lstarts(iomv)
            @test pstarts(io) == pstarts(iomv)
            @test pincs(io) == pincs(iomv)
            trcsor, hdrsor = allocframe(io)
            trcsmv, hdrsmv = allocframe(iomv)
            for i = 1:length(io)
                fldor = readframe!(io, trcsor, hdrsor, ind2sub(io, i)...)
                fldmv = readframe!(iomv, trcsmv, hdrsmv, ind2sub(iomv, i)...)
                @test fldor == fldmv
                @test trcsor ≈ trcsmv
                @test hdrsor == hdrsmv
            end

            rm(iomv)
        end
        rm(joinpath(rundir, "newsec"), recursive=true)

        #
        # test making a data-set empty
        #
        @test isempty(io) == false
        empty!(io)
        @test isempty(io) == true
        rm(io)
    end
end

@testset "teaseisio, 6 dimensions" begin
    io = jsopen(joinpath(rundir, "test.js"), "w", axis_lengths=[2,3,4,5,6,7])
    x = rand(Float32,2,3,4,5,6,7)
    for i = 1:length(io)
        writeframe(io, x[:,:,ind2sub(io,i)...], ind2sub(io,i)...)
    end
    close(io)
    io = jsopen(joinpath(rundir, "test.js"))
    @test size(io) == (2,3,4,5,6,7)
    for i = 1:length(io)
        t,h = readframe(io, ind2sub(io,i)...)
        @test t ≈ x[:,:,ind2sub(io,i)...]
        @test get(prop(io,"DIM6"), h, 1) == ind2sub(io,i)[4]
    end
end

@testset "teaseisio, 9 dimensions" begin
    io = jsopen(joinpath(rundir, "test.js"), "w", axis_lengths=[2,3,4,5,6,7,2,1,2])
    x = rand(Float32,2,3,4,5,6,7,2,1,2)
    for i = 1:length(io)
        writeframe(io, x[:,:,ind2sub(io,i)...], ind2sub(io,i)...)
    end
    close(io)
    io = jsopen(joinpath(rundir, "test.js"))
    @test size(io) == (2,3,4,5,6,7,2,1,2)
    for i = 1:length(io)
        t,h = readframe(io, ind2sub(io,i)...)
        @test t ≈ x[:,:,ind2sub(io,i)...]
        @test get(prop(io,"DIM9"), h, 1) == ind2sub(io,i)[7]
    end
end

@testset "teaseisio, data property" begin
    io = jsopen(joinpath(rundir, "test.js"), "w", axis_lengths=[2,3,4], dataproperties=[DataProperty("PROP", Int32, 10)])
    io = jsopen(joinpath(rundir, "test.js"))
    @test hasdataproperty(io,"PROP") == true
    @test hasdataproperty(io, "NOPROP") == false
    @test dataproperty(io,"PROP") == 10
end

@testset "teaseisio, secondaries with primary" begin
    c = pwd()
    ENV["JAVASEIS_DATA_HOME"] = joinpath(c, "primary")
    mkpath(joinpath(ENV["JAVASEIS_DATA_HOME"], "foo"))
    cd(joinpath(ENV["JAVASEIS_DATA_HOME"], "foo"))
    io = jsopen("test.js", "w", axis_lengths=[3,3,3], secondaries=[joinpath(c,"second")])
    trcs = rand(3,3,3)
    write(io, trcs, :, :, :)
    @test isfile(joinpath(c,"second","foo","test.js","TraceFile0"))
end
