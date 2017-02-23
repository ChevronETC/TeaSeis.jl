# TeaSeis.jl

## Stock properties

Symbol     | Description                         | Type    | Count
-----------|-------------------------------------|---------|------
:AMP_NORM  | "Amplitude normalization factor"    | Float32 | 1
:AOFFSET   | "Absolute value of offset"          | Float32 | 1
:CDP       | "CDP bin number"                    | Int32   | 1
:CDP_ELEV  | "Elevation of CDP"                  | Float32 | 1
:CDP_NFLD  | "Number of traces in CDP bin"       | Int32   | 1
:CDP_SLOC  | "External CDP number"               | Int32   | 1
:CDP_X     | "X coordinate of CDP (float)"       | Float32 | 1
:CDP_XD    | "X coordinate of CDP (double)"      | Float64 | 1
:CDP_Y     | "Y coordinate of CDP (float)"       | Float32 | 1
:CDP_YD    | "Y coordinate of CDP (double)"      | Float64 | 1
:CHAN      | "Recording channel number"          | Int32   | 1
:CMP_X     | "Average of shot and receiver x"    | Float32 | 1
:CMP_Y     | "Average of shot and receiver y"    | Float32 | 1
:CR_STAT   | "Corr. autostatics receiver static" | Float32 | 1
:CS_STAT   | "Corr. autostatics source static"   | Float32 | 1
:DEPTH     | "Source depth"                      | Float32 | 1
:DISKITER  | "Disk data iteration*"              | Int32   | 1
:DMOOFF    | "Offset bin for DMO"                | Int32   | 1
:DS_SEQNO  | "Input dataset sequence number*"    | Int32   | 1
:END_ENS   | "End-of-ensemble flag*"             | Int32   | 1
:END_VOL   | "End-of-volume flag*"               | Int32   | 1
:EOJ       | "End of job flag*"                  | Int32   | 1
:FB_PICK   | "First break pick"                  | Float32 | 1
:FFID      | "Field file ID number"              | Int32   | 1
:FILE_NO   | "Sequential file number"            | Int32   | 1
:FK_WAVEL  | "Wavelength of F-K domain trace"    | Float32 | 1
:FK_WAVEN  | "Wavenumber of F-K domain trace"    | Float32 | 1
:FNL_STAT  | "Static to move to final datum"     | Float32 | 1
:FRAME     | "Frame index in framework"          | Int32   | 1
:FT_FREQ   | "Frequency of F-T domain trace"     | Float32 | 1
:GEO_COMP  | "Geophone component (x,y,z)"        | Int32   | 1
:HYPERCUBE | "Hypercube index in framework"      | Int32   | 1
:IF_FLAG   | "ProMax IF_FLAG"                    | Int32   | 1
:ILINE_NO  | "3D iline number"                   | Int32   | 1
:LEN_SURG  | "Length of surgical mute taper"     | Float32 | 1
:LINE_NO   | "Line number (hased line name)*"    | Int32   | 1
:LSEG_END  | "Line segment end*"                 | Int32   | 1
:LSEG_SEQ  | "Line segment sequence number*"     | Int32   | 1
:NA_STAT   | "Portion of static not applied"     | Float32 | 1
:NCHANS    | "Number of channels of source"      | Int32   | 1
:NDATUM    | "Floating NMO Datum"                | Float32 | 1
:NMO_APLD  | "NMO applied to traces"             | Int32   | 1
:NMO_STAT  | "NMO datum static"                  | Float32 | 1
:OFB_CNTR  | "Offset bin center"                 | Float32 | 1
:OFB_NO    | "Offset bin number"                 | Int32   | 1
:OFFSET    | "Signed source-receiver offset"     | Float32 | 1
:PAD_TRC   | "Artifically padded trace"          | Int32   | 1
:PR_STAT   | "Power autostatics receiver static" | Float32 | 1
:PS_STAT   | "Power autostatics source static"   | Float32 | 1
:R_LINE    | "Receiver line number"              | Int32   | 1
:REC_ELEV  | "Receiver elevation"                | Float32 | 1
:REC_H2OD  | "Water depth at receiver"           | Float32 | 1
:REC_NFLD  | "Receiver fold"                     | Int32   | 1
:REC_SLOC  | "Receiver index number (internal)*" | Int32   | 1
:REC_STAT  | "Total static for receiver"         | Float32 | 1
:REC_X     | "Receiver X coordinate (float)"     | Float32 | 1
:REC_XD    | "Receiver X coordinate (double)"    | Float64 | 1
:REC_Y     | "Receiver Y coordinate (float)"     | Float32 | 1
:REC_YD    | "Receiver Y coordinate (double)"    | Float64 | 1
:REPEAT    | "Repeated data copy number"         | Int32   | 1
:S_LINE    | "Swath or sail line number"         | Int32   | 1
:SAMPLE    | "Sample index in framework"         | Int32   | 1
:SEQ_DISK  | "Trace sequence number from disk"   | Int32   | 1
:SEQNO     | "Sequence number in ensemble"       | Int32   | 1
:SG_CDP    | "Super gather CDP number"           | Int32   | 1
:SIN       | "Source index number*"              | Int32   | 1
:SKEWSTAT  | "Multiplex skew static"             | Float32 | 1
:SLC_TIME  | "Time slice input"                  | Float32 | 1
:SMH_CDP   | "Number of CDP's in supergather"    | Int32   | 1
:SOU_COMP  | "Source component (x,y,z)"          | Int32   | 1
:SOU_ELEV  | "Source elevation"                  | Float32 | 1
:SOU_H2OD  | "Water depth at source"             | Float32 | 1
:SOU_SLOC  | "External source location number"   | Int32   | 1
:SOU_STAT  | "Total static for source"           | Float32 | 1
:SOU_X     | "Source X coordinate (float)"       | Float32 | 1
:SOU_XD    | "Source X coordinate (double)"      | Float64 | 1
:SOU_Y     | "Source Y coordinate (float)"       | Float32 | 1
:SOU_YD    | "Source Y coordinate (double)"      | Float64 | 1
:SOURCE    | "Live source number (user-defined)" | Int32   | 1
:SR_AZIM   | "Source to receiver azimuth"        | Float32 | 1
:SRF_SLOC  | "External receiver location number" | Int32   | 1
:TFULL_E   | "End time of full samples"          | Float32 | 1
:TFULL_S   | "Start time of full samples"        | Float32 | 1
:TIME_IND  | "Time sample index"                 | Int32   | 1
:TLIVE_E   | "End time of live samples"          | Float32 | 1
:TLIVE_S   | "Start time of live samples"        | Float32 | 1
:TOT_STAT  | "Total static for this trace"       | Float32 | 1
:TR_FOLD   | "Actual trace fold"                 | Float32 | 1
:TRACE     | "Trace index in framework"          | Int32   | 1
:TRACENO   | "Trace number in seismic line*"     | Int32   | 1
:TRC_TYPE  | "Trace type (data, aux, etc.)"      | Int32   | 1
:TRIMSTAT  | "Trim static"                       | Float32 | 1
:UPHOLE    | "Source uphole time"                | Float32 | 1
:VOLUME    | "Volume index in framework"         | Int32   | 1
:WB_TIME   | "Water bottom time"                 | Float32 | 1
:XLINE_NO  | "3D crossline number"               | Int32   | 1

## Stock units
`:DEGREES`, `:FEET`, `:FT`, `:HERTZ`, `:HZ`, `:M`, `:METERS`, `:MICROSEC`, `:MILLISECONDS`, `:MS,`, `:MSEC`, `:SECONDS`, `:S`, `:NULL`, `:UNKNOWN`

## Stock domains
`:ALACRITY`, `:AMPLITUDE`, `:COHERENCE`, `:DELTA`, `:DENSITY`, `:DEPTH`, `:DIP`, `:ENVELOPE`, `:EPSILON`, `:ETA`, `:FLEX_BINNED`, `:FOLD`, `:FREQUENCY`, `:IMPEDANCE`, `:INCIDENCE_ANGLE`, `:MODEL_TRANSFORM`, `:ROTATION_ANGLE`, `:SEMBLANCE`, `:SLOTH`, `:SLOWNESS`, `:SPACE`, `:TIME`, `:UNKNOWN`, `:VELOCITY`, `:VS`, `:VSVP`, `:WAVENUMBER`

## Stock data types
`:CMP`, `:CUSTOM`, `:OFFSET_BIN`, `:RECEIVER`, `:SOURCE`, `:STACK`, `:UNKNOWN`
