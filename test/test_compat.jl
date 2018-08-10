using TeaSeis, LightXML, Test

@testset "Compat Test" for (pmlbls, jslbls, pdefs) in (
    (("DPTH_IND", "CHAN", "XLINE_NO", "ILINE_NO", "OFB_NO"),
     ["DEPTH", "CHANNEL", "CROSSLINE", "INLINE", "OFFSET_BIN"],
     [TracePropertyDef("DEPTH","",Int32,1), TracePropertyDef("CHANNEL","",Int32,1), TracePropertyDef("CROSSLINE","",Int32,1), TracePropertyDef("INLINE","",Int32,1), TracePropertyDef("OFFSET_BIN","",Int32,1)]),

    (("DPTH_IND", "CHAN", "XLINE_NO", "ILINE_NO", "OFB_NO"),
     ["DEPTH", "CHANNEL", "CROSSLINE", "INLINE", "OFFSET_BIN"],
     [TracePropertyDef("DPTH_IND","",Int32,1), TracePropertyDef("CHAN","",Int32,1), TracePropertyDef("XLINE_NO","",Int32,1), TracePropertyDef("ILINE_NO","",Int32,1), TracePropertyDef("OFB_NO","",Int32,1)]),

    (("TIME_IND", "REC_SLOC", "R_LINE", "S_LINE", "CDP"),
     ["TIME", "RECEIVER", "RECEIVER_LINE", "SAIL_LINE", "CMP"],
     [TracePropertyDef("TIME","",Int32,1), TracePropertyDef("RECEIVER","",Int32,1), TracePropertyDef("RECEIVER_LINE","",Int32,1), TracePropertyDef("SAIL_LINE","",Int32,1), TracePropertyDef("CMP","",Int32,1)]),

    (("TIME_IND", "REC_SLOC", "R_LINE", "S_LINE", "CDP"),
     ["TIME", "RECEIVER", "RECEIVER_LINE", "SAIL_LINE", "CMP"],
     [TracePropertyDef("TIME_IND","",Int32,1), TracePropertyDef("REC_SLOC","",Int32,1), TracePropertyDef("R_LINE","",Int32,1), TracePropertyDef("S_LINE","",Int32,1), TracePropertyDef("CDP","",Int32,1)])

)

    io = jsopen("test.js", "w", axis_lengths=[10,11,12,13,14], axis_propdefs=pdefs)
    @test labels(io) == pmlbls
    close(io)
    io = jsopen("test.js")
    @test labels(io) == pmlbls

    xml = parse_file(joinpath(io.filename, "FileProperties.xml"))
    lbls = split(content(TeaSeis.get_file_property_element(xml, "AxisLabels")))
    @test lbls == jslbls
    rm(io)
end
