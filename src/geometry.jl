type Geometry
    minILine::Int32
    maxILine::Int32
    minXLine::Int32
    maxXLine::Int32
    xILine1End::Float32
    yILine1End::Float32
    xILine1Start::Float32
    yILine1Start::Float32
    xXLine1End::Float32
    yXLine1End::Float32
end
Geometry() = Geometry(0,0,0,0,0.,0.,0.,0.,0.,0.)

function copy(geom::Geometry)
    geom = Geometry(geom.minILine,
                    geom.maxILine,
                    geom.minXLine,
                    geom.maxXLine,
                    geom.xILine1End,
                    geom.yILine1End,
                    geom.xILine1Start,
                    geom.yILine1Start,
                    geom.xXLine1End,
                    geom.yXLine1End)
end

function copy!(dst::Geometry, src::Geometry)
    dst.minILine     = src.minILine
    dst.maxILine     = src.maxILine
    dst.minXLine     = src.minXLine
    dst.maxXLine     = src.maxXLine
    dst.xILine1End   = src.xILine1End
    dst.yILine1End   = src.yILine1End
    dst.xILine1Start = src.xILine1Start
    dst.yILine1Start = src.yILine1Start
    dst.xXLine1End   = src.xXline1End
    dst.yXLine1End   = src.yXLine1End
end
