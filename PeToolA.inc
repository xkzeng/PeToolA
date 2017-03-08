
CODE_SEG_RO equ 0FFFFFFFFH
GetSignSegment PROTO NEAR32 STDCALL __dwSignLength:DWORD, __lpSignBase:LPDWORD, __lpPointerToRawData:LPDWORD, __lpVirtualSize:LPDWORD
GetSignInfo PROTO NEAR32 STDCALL __lpSignBase:LPDWORD, __lpSign:LPDWORD, __lpSoftName:LPDWORD, __lpAuthor:LPDWORD, __lpEmail:LPDWORD
