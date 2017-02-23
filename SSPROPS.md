# TeaSeis.jl

## SeisSpace guaranteed properties for a JavaSeis dataset

Symbol    | Description                         | Type    | Count
----------|-------------------------------------|---------|------
:SEQNO    | "Sequence number in ensemble"       | Int32   | 1
:END_ENS  | "End-of-ensemble flag*"             | Int32   | 1
:EOJ      | "End of job flag*"                  | Int32   | 1
:TRACENO  | "Trace number in seismic line*"     | Int32   | 1
:TRC_TYPE | "Trace type (data, aux, etc.)"      | Int32   | 1
:TLIVE_S  | "Start time of live samples"        | Float32 | 1
:TFULL_S  | "Start time of full samples"        | Float32 | 1
:TFULL_E  | "End time of full samples"          | Float32 | 1
:TLIVE_E  | "End time of live samples"          | Float32 | 1
:LEN_SURG | "Length of surgical mute taper"     | Float32 | 1
:TOT_STAT | "Total static for this trace*"      | Float32 | 1
:NA_STAT  | "Portion of static not applied"     | Float32 | 1
:AMP_NORM | "Amplitude normalization factor"    | Float32 | 1
:TR_FOLD  | "Actual trace fold"                 | Float32 | 1
:SKEWSTAT | "Multiplex skew static"             | Float32 | 1
:LINE_NO  | "Line number (hased line name)*"    | Int32   | 1
:LSEG_END | "Line segment end*"                 | Int32   | 1
