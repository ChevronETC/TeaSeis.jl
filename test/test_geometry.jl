using TeaSeis, Test

@testset "Geometry" begin
    g = Geometry(
        u1=2,un=3,v1=4,vn=5,w1=6,wn=7,
        ox=1.0,oy=2.0,oz=3.0,
        ux=10.0,uy=20.0,uz=30.0,
        vx=40.0,vy=50.0,vz=60.0,
        wx=70.0,wy=80.0,wz=90.0)
    io = jsopen("test.js", "w", axis_lengths=[1,2,3], geometry = g, dataproperties=[DataProperty("FOO", Int, 1)])
    g_test = geometry(io)
    @test g.u1 == g_test.u1
    @test g.un == g_test.un
    @test g.v1 == g_test.v1
    @test g.vn == g_test.vn
    @test g.w1 == g_test.w1
    @test g.wn == g_test.wn
    @test g.ox ≈ g_test.ox
    @test g.oy ≈ g_test.oy
    @test g.oz ≈ g_test.oz
    @test g.ux ≈ g_test.ux
    @test g.uy ≈ g_test.uy
    @test g.uz ≈ g_test.uz
    @test g.vx ≈ g_test.vx
    @test g.vy ≈ g_test.vy
    @test g.vz ≈ g_test.vz
    @test g.wx ≈ g_test.wx
    @test g.wy ≈ g_test.wy
    @test g.wz ≈ g_test.wz

    g = Geometry()
    @test g.u1 == 1
    @test g.un == 2
    @test g.v1 == 1
    @test g.vn == 2
    @test g.w1 == 1
    @test g.wn == 2
    @test g.ux ≈ 1.0
    @test g.uy ≈ 0.0
    @test g.uz ≈ 0.0
    @test g.vx ≈ 0.0
    @test g.vy ≈ 1.0
    @test g.vz ≈ 0.0
    @test g.wx ≈ 0.0
    @test g.wy ≈ 0.0
    @test g.wz ≈ 1.0
    io = jsopen("test.js", "w", axis_lengths=[1,2,3], geometry = g)
    g_test = geometry(io)
    @test g.u1 == g_test.u1
    @test g.un == g_test.un
    @test g.v1 == g_test.v1
    @test g.vn == g_test.vn
    @test g.w1 == g_test.w1
    @test g.wn == g_test.wn
    @test g.ox ≈ g_test.ox
    @test g.oy ≈ g_test.oy
    @test g.oz ≈ g_test.oz
    @test g.ux ≈ g_test.ux
    @test g.uy ≈ g_test.uy
    @test g.uz ≈ g_test.uz
    @test g.vx ≈ g_test.vx
    @test g.vy ≈ g_test.vy
    @test g.vz ≈ g_test.vz
    @test g.wx ≈ g_test.wx
    @test g.wy ≈ g_test.wy
    @test g.wz ≈ g_test.wz

    @test typeof(@show(g)) == Geometry

    io = jsopen("test.js", "w", axis_lengths=[1,2,3])
    @test geometry(io) == nothing
end
