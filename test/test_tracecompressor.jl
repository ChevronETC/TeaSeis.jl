using TeaSeis, Test

@testset "Compressor Tests" begin
    # packing a single trace
    nsamples = 1024
    c = TeaSeis.TraceCompressor(nsamples, Int16)
    trc = rand(Float32, nsamples)
    trc_check = zeros(Float32, nsamples)
    buf = TeaSeis.allocframebuf(c, 1)
    TeaSeis.packtrace!(c, buf, trc, 0)
    TeaSeis.unpacktrace!(c, trc_check, buf, 0)
    @test trc ≈ trc_check

    # packing a single trace, all zeros
    trc = zeros(Float32, nsamples)
    trc_check = rand(Float32, nsamples)
    buf = TeaSeis.allocframebuf(c,1)
    TeaSeis.packtrace!(c, buf, trc, 0)
    TeaSeis.unpacktrace!(c, trc_check, buf, 0)
    @test trc ≈ trc_check

    # packing a frame
    ntraces = 13
    frm = rand(Float32, nsamples, ntraces)
    frm_check = zeros(Float32, nsamples, ntraces)
    buf = TeaSeis.allocframebuf(c, ntraces)
    TeaSeis.packframe!(c, buf, frm, ntraces)
    TeaSeis.unpackframe!(c, frm_check, buf, ntraces)
    @test frm ≈ frm_check

    # packing a frame with fld < ntraces
    fill!(frm_check, 0.0)
    buf = TeaSeis.allocframebuf(c, 9)
    TeaSeis.packframe!(c, buf, frm, 9)
    TeaSeis.unpackframe!(c, frm_check, buf, 9)
    @test frm[:,1:9] ≈ frm_check[:,1:9]
    @test frm_check[:,10:13] ≈ zeros(size(frm[:,10:13]))
end
