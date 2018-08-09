struct Geometry
    u1::Int
    un::Int
    v1::Int
    vn::Int
    w1::Int
    wn::Int
    ox::Float64
    oy::Float64
    oz::Float64
    ux::Float64
    uy::Float64
    uz::Float64
    vx::Float64
    vy::Float64
    vz::Float64
    wx::Float64
    wy::Float64
    wz::Float64
end

"""
    g = Geometry(;ox=0.0,oy=0.0,oz=0.0,ux=1.0,uy=0.0,uz=0.0,vx=0.0,vy=1.0,vz=0.0,wx=0.0,wy=0.0,wz=1.0,u1=0,un=0,v1=0,vn=0,w1=0,wn=0)

where `g::Geometry`.  The named arguments are:

* `ox=0.0,oy=0.0,oz=0.0` origin of axes
* `ux=1.0,uy=0.0,uz=0.0` end of u-vector (e.g. end of first in-line, in the cross-line direction
* `vx=0.0,vy=1.0,vz=0.0` end of v-vector (e.g. end of first cross-line, in the in-line direction
* `wx=0.0,wy=0.0,wz=1.0` end of depth axis
* `u1=1` minimum index along the u-vector (e.g. maximum cross-line index)
* `un=2` maximum index along the u-vector (e.g. maximum cross-line index)
* `v1=1` minimum index along the v-vector (e.g. minimum in-line index)
* `vn=2` maximum index along the v-vector (e.g. maximum in-line index)
* `w1=1` minimum depth index
* `wn=2` maximum depth index
"""
function Geometry(;
        ox=0.0,oy=0.0,oz=0.0,
        ux=1.0,uy=0.0,uz=0.0,
        vx=0.0,vy=1.0,vz=0.0,
        wx=0.0,wy=0.0,wz=1.0,
        u1=1,un=2,
        v1=1,vn=2,
        w1=1,wn=2)
    Geometry(u1,un,v1,vn,w1,wn,ox,oy,oz,ux,uy,uz,vx,vy,vz,wx,wy,wz)
end

function show(io::IO, g::Geometry)
    write(io, "origin: ($(g.ox),$(g.oy),$(g.oz))\n")
    write(io, "u: ($(g.ux),$(g.uy),$(g.uz))\n")
    write(io, "v: ($(g.vx),$(g.vy),$(g.vz))\n")
    write(io, "w: ($(g.wx),$(g.wy),$(g.wz))\n")
    write(io, "u1,un: ($(g.u1),$(g.un))\n")
    write(io, "v1,vn: ($(g.v1),$(g.vn))\n")
    write(io, "w1,wn: ($(g.w1),$(g.wn))")
end
