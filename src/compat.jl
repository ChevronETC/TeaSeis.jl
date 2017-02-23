# Necessary evil for compatability, mapping between JavaSeis
# axis labels and property labels.
const global dictJStoPM = Dict{String,String}(
"TIME"          =>"TIME_IND",
"DEPTH"         =>"DPTH_IND",
"CHANNEL"       =>"CHAN",
"CROSSLINE"     =>"XLINE_NO",
"INLINE"        =>"ILINE_NO",
"OFFSET"        =>"OFB_NO",
"OFFSET_BIN"    =>"OFB_NO",
"RECEIVER"      =>"REC_SLOC",
"RECEIVER_LINE" =>"R_LINE",
"SAIL_LINE"     =>"S_LINE",
"CMP"           =>"CDP")

const global dictPMtoJS = Dict{String,String}(
"TIME_IND" =>"TIME",
"DPTH_IND" =>"DEPTH",
"CHAN"     =>"CHANNEL",
"XLINE_NO" =>"CROSSLINE",
"ILINE_NO" =>"INLINE",
"OFB_NO"   =>"OFFSET_BIN",
"REC_SLOC" =>"RECEIVER",
"R_LINE"   =>"RECEIVER_LINE",
"S_LINE"   =>"SAIL_LINE",
"CDP"      =>"CMP")
