const tracetype = Dict{Symbol,Int}(:live=>1, :dead=>2, :aux=>3)

const stockdomain = Dict{Symbol,String}(
:ALACRITY       =>"alacrity",
:AMPLITUDE      =>"amplitude",
:COHERENCE      =>"coherence",
:DELTA          =>"delta",
:DENSITY        =>"density",
:DEPTH          =>"depth",
:DIP            =>"dip",
:ENVELOPE       =>"envelope",
:EPSILON        =>"epsilon",
:ETA            =>"eta",
:FLEX_BINNED    =>"flex_binned",
:FOLD           =>"fold",
:FREQUENCY      =>"frequency",
:IMPEDANCE      =>"impedence",
:INCIDENCE_ANGLE=>"incidence_angle",
:MODEL_TRANSFORM=>"model_transform",
:ROTATION_ANGLE =>"rotation_angle",
:SEMBLANCE      =>"semblence",
:SLOTH          =>"sloth",
:SLOWNESS       =>"slowness",
:SPACE          =>"space",
:TIME           =>"time",
:UNKNOWN        =>"unknown",
:VELOCITY       =>"velocity",
:VS             =>"vs",
:VSVP           =>"vsvp",
:WAVENUMBER     =>"wavenumber"
)

const stockunit = Dict{Symbol,String}(
:DEGREES     =>"degrees",
:FEET        =>"feet",
:FT          =>"ft",
:HERTZ       =>"hertz",
:HZ          =>"hz",
:M           =>"m",
:METERS      =>"meters",
:MICROSEC    =>"microseconds",
:MILLISECONDS=>"milliseconds",
:MS          =>"ms",
:MSEC        =>"msec",
:SECONDS     =>"seconds",
:S           =>"seconds",
:NULL        =>"null",
:UNKNOWN     =>"unknown"
)

const stockdatatype = Dict{Symbol,String}(
:CMP       =>"CMP",
:CUSTOM    =>"CUSTOM",
:OFFSET_BIN=>"OFFSET_BIN",
:RECEIVER  =>"RECEIVER",
:SOURCE    =>"SOURCE",
:STACK     =>"STACK",
:UNKNOWN   =>"UNKNOWN"
)

const stockprop = Dict{Symbol,TracePropertyDef}(
:AMP_NORM =>TracePropertyDef("AMP_NORM", "Amplitude normalization factor",    Float32, 1),
:AOFFSET  =>TracePropertyDef("AOFFSET",  "Absolute value of offset",          Float32, 1),
:CDP      =>TracePropertyDef("CDP",      "CDP bin number",                    Int32,   1),
:CDP_ELEV =>TracePropertyDef("CDP_ELEV", "Elevation of CDP",                  Float32, 1),
:CDP_NFLD =>TracePropertyDef("CDP_NFLD", "Number of traces in CDP bin",       Int32,   1),
:CDP_SLOC =>TracePropertyDef("CDP_SLOC", "External CDP number",               Int32,   1),
:CDP_X    =>TracePropertyDef("CDP_X",    "X coordinate of CDP (float)",       Float32, 1),
:CDP_XD   =>TracePropertyDef("CDP_XD",   "X coordinate of CDP (double)",      Float64, 1),
:CDP_Y    =>TracePropertyDef("CDP_Y",    "Y coordinate of CDP (float)",       Float32, 1),
:CDP_YD   =>TracePropertyDef("CDP_YD",   "Y coordinate of CDP (double)",      Float64, 1),
:CHAN     =>TracePropertyDef("CHAN",     "Recording channel number",          Int32,   1),
:CMP_X    =>TracePropertyDef("CMP_X",    "Average of shot and receiver x",    Float32, 1),
:CMP_Y    =>TracePropertyDef("CMP_Y",    "Average of shot and receiver y",    Float32, 1),
:CR_STAT  =>TracePropertyDef("CR_STAT",  "Corr. autostatics receiver static", Float32, 1),
:CS_STAT  =>TracePropertyDef("CS_STAT",  "Corr. autostatics source static",   Float32, 1),
:DEPTH    =>TracePropertyDef("DEPTH",    "Source depth",                      Float32, 1),
:DISKITER =>TracePropertyDef("DISKITER", "Disk data iteration*",              Int32,   1),
:DMOOFF   =>TracePropertyDef("DMOOFF",   "Offset bin for DMO",                Int32,   1),
:DS_SEQNO =>TracePropertyDef("DS_SEQNO", "Input dataset sequence number*",    Int32,   1),
:END_ENS  =>TracePropertyDef("END_ENS",  "End-of-ensemble flag*",             Int32,   1),
:END_VOL  =>TracePropertyDef("END_VOL",  "End-of-volume flag*",               Int32,   1),
:EOJ      =>TracePropertyDef("EOJ",      "End of job flag*",                  Int32,   1),
:FB_PICK  =>TracePropertyDef("FB_PICK",  "First break pick",                  Float32, 1),
:FFID     =>TracePropertyDef("FFID",     "Field file ID number",              Int32,   1),
:FILE_NO  =>TracePropertyDef("FILE_NO",  "Sequential file number",            Int32,   1),
:FK_WAVEL =>TracePropertyDef("FK_WAVEL", "Wavelength of F-K domain trace",    Float32, 1),
:FK_WAVEN =>TracePropertyDef("FK_WAVEN", "Wavenumber of F-K domain trace",    Float32, 1),
:FNL_STAT =>TracePropertyDef("FNL_STAT", "Static to move to final datum",     Float32, 1),
:FRAME    =>TracePropertyDef("FRAME",    "Frame index in framework",          Int32,   1),
:FT_FREQ  =>TracePropertyDef("FT_FREQ",  "Frequency of F-T domain trace",     Float32, 1),
:GEO_COMP =>TracePropertyDef("GEO_COMP", "Geophone component (x,y,z)",        Int32,   1),
:HYPRCUBE =>TracePropertyDef("HYPRCUBE", "Hypercube index in framework",      Int32,   1),
:IF_FLAG  =>TracePropertyDef("IF_FLAG",  "ProMax IF_FLAG",                    Int32,   1),
:ILINE_NO =>TracePropertyDef("ILINE_NO", "3D iline number",                   Int32,   1),
:LEN_SURG =>TracePropertyDef("LEN_SURG", "Length of surgical mute taper",     Float32, 1),
:LINE_NO  =>TracePropertyDef("LINE_NO",  "Line number (hased line name)*",    Int32,   1),
:LSEG_END =>TracePropertyDef("LSEG_END", "Line segment end*",                 Int32,   1),
:LSEG_SEQ =>TracePropertyDef("LSEG_SEQ", "Line segment sequence number*",     Int32,   1),
:NA_STAT  =>TracePropertyDef("NA_STAT",  "Portion of static not applied",     Float32, 1),
:NCHANS   =>TracePropertyDef("NCHANS",   "Number of channels of source",      Int32,   1),
:NDATUM   =>TracePropertyDef("NDATUM",   "Floating NMO Datum",                Float32, 1),
:NMO_STAT =>TracePropertyDef("NMO_STAT", "NMO datum static",                  Float32, 1),
:NMO_APLD =>TracePropertyDef("NOM_APLD", "NMO applied to traces",             Int32,   1),
:OFB_CNTR =>TracePropertyDef("OFB_CNTR", "Offset bin center",                 Float32, 1),
:OFB_NO   =>TracePropertyDef("OFB_NO",   "Offset bin number",                 Int32,   1),
:OFFSET   =>TracePropertyDef("OFFSET",   "Signed source-receiver offset",     Float32, 1),
:PAD_TRC  =>TracePropertyDef("PAD_TRC",  "Artifically padded trace",          Int32,   1),
:PR_STAT  =>TracePropertyDef("PR_STAT",  "Power autostatics receiver static", Float32, 1),
:PS_STAT  =>TracePropertyDef("PS_STAT",  "Power autostatics source static",   Float32, 1),
:R_LINE   =>TracePropertyDef("R_LINE",   "Receiver line number",              Int32,   1),
:REC_ELEV =>TracePropertyDef("REC_ELEV", "Receiver elevation",                Float32, 1),
:REC_H2OD =>TracePropertyDef("REC_H2OD", "Water depth at receiver",           Float32, 1),
:REC_NFLD =>TracePropertyDef("REC_NFLD", "Receiver fold",                     Int32,   1),
:REC_SLOC =>TracePropertyDef("REC_SLOC", "Receiver index number (internal)*", Int32,   1),
:REC_STAT =>TracePropertyDef("REC_STAT", "Total static for receiver",         Float32, 1),
:REC_X    =>TracePropertyDef("REC_X",    "Receiver X coordinate (float)",     Float32, 1),
:REC_XD   =>TracePropertyDef("REC_XD",   "Receiver X coordinate (double)",    Float64, 1),
:REC_Y    =>TracePropertyDef("REC_Y",    "Receiver Y coordinate (float)",     Float32, 1),
:REC_YD   =>TracePropertyDef("REC_YD",   "Receiver Y coordinate (double)",    Float64, 1),
:REPEAT   =>TracePropertyDef("REPEAT",   "Repeated data copy number",         Int32,   1),
:S_LINE   =>TracePropertyDef("S_LINE",   "Swath or sail line number",         Int32,   1),
:SAMPLE   =>TracePropertyDef("SAMPLE",   "Sample index in framework",         Int32,   1),
:SEQNO    =>TracePropertyDef("SEQNO",    "Sequence number in ensemble",       Int32,   1),
:SEQ_DISK =>TracePropertyDef("SEQ_DISK", "Trace sequence number from disk",   Int32,   1),
:SG_CDP   =>TracePropertyDef("SG_CDP",   "Super gather CDP number",           Int32,   1),
:SIN      =>TracePropertyDef("SIN",      "Source index number*",              Int32,   1),
:SLC_TIME =>TracePropertyDef("SLC_TIME", "Time slice input",                  Float32, 1),
:SMH_CDP  =>TracePropertyDef("SMH_CDP",  "Number of CDP's in supergather",    Int32,   1),
:SOU_COMP =>TracePropertyDef("SOU_COMP", "Source component (x,y,z)",          Int32,   1),
:SOU_ELEV =>TracePropertyDef("SOU_ELEV", "Source elevation",                  Float32, 1),
:SOU_H2OD =>TracePropertyDef("SOU_H2OD", "Water depth at source",             Float32, 1),
:SOU_SLOC =>TracePropertyDef("SOU_SLOC", "External source location number",   Int32,   1),
:SOU_STAT =>TracePropertyDef("SOU_STAT", "Total static for source",           Float32, 1),
:SOU_X    =>TracePropertyDef("SOU_X",    "Source X coordinate (float)",       Float32, 1),
:SOU_XD   =>TracePropertyDef("SOU_XD",   "Source X coordinate (double)",      Float64, 1),
:SOU_Y    =>TracePropertyDef("SOU_Y",    "Source Y coordinate (float)",       Float32, 1),
:SOU_YD   =>TracePropertyDef("SOU_YD",   "Source Y coordinate (double)",      Float64, 1),
:SOURCE   =>TracePropertyDef("SOURCE",   "Live source number (user-defined)", Int32,   1),
:SKEWSTAT =>TracePropertyDef("SKEWSTAT", "Multiplex skew static",             Float32, 1),
:SR_AZIM  =>TracePropertyDef("SR_AZIM",  "Source to receiver azimuth",        Float32, 1),
:SRF_SLOC =>TracePropertyDef("SRF_SLOC", "External receiver location number", Int32,   1),
:TFULL_E  =>TracePropertyDef("TFULL_E",  "End time of full samples",          Float32, 1),
:TFULL_S  =>TracePropertyDef("TFULL_S",  "Start time of full samples",        Float32, 1),
:TIME_IND =>TracePropertyDef("TIME_IND", "Time sample index",                 Int32,   1),
:TLIVE_E  =>TracePropertyDef("TLIVE_E",  "End time of live samples",          Float32, 1),
:TLIVE_S  =>TracePropertyDef("TLIVE_S",  "Start time of live samples",        Float32, 1),
:TOT_STAT =>TracePropertyDef("TOT_STAT", "Total static for this trace",       Float32, 1),
:TRACE    =>TracePropertyDef("TRACE",    "Trace index in framework",          Int32,   1),
:TRC_TYPE =>TracePropertyDef("TRC_TYPE", "Trace type (data, aux, etc.)",      Int32,   1),
:TR_FOLD  =>TracePropertyDef("TR_FOLD",  "Actual trace fold",                 Float32, 1),
:TRACENO  =>TracePropertyDef("TRACENO",  "Trace number in seismic line*",     Int32,   1),
:TRIMSTAT =>TracePropertyDef("TRIMSTAT", "Trim static",                       Float32, 1),
:UPHOLE   =>TracePropertyDef("UPHOLE",   "Source uphole time",                Float32, 1),
:VOLUME   =>TracePropertyDef("VOLUME",   "Volume index in framework",         Int32,   1),
:WB_TIME  =>TracePropertyDef("WB_TIME",  "Water bottom time",                 Float32, 1),
:XLINE_NO =>TracePropertyDef("XLINE_NO", "3D crossline number",               Int32,   1)
)
