;include <windows.inc>
PIMAGE_DOS_HEADER         typedef LPVOID
PIMAGE_NT_HEADERS         typedef LPVOID
PIMAGE_FILE_HEADER        typedef LPVOID
PIMAGE_OPTIONAL_HEADER    typedef LPVOID
PIMAGE_DATA_DIRECTORY     typedef LPVOID
PIMAGE_SECTION_HEADER     typedef LPVOID
PIMAGE_EXPORT_DIRECTORY   typedef LPVOID
PIMAGE_IMPORT_DESCRIPTOR  typedef LPVOID
PIMAGE_RESOURCE_DIRECTORY typedef LPVOID
PIMAGE_BASE_RELOCATION    typedef LPVOID
PIMAGE_DEBUG_DIRECTORY    typedef LPVOID
PIMAGE_TLS_DIRECTORY      typedef LPVOID
PIMAGE_THUNK_DATA         typedef LPVOID
PIMAGE_IMPORT_BY_NAME     typedef LPVOID
PIMAGE_RESOURCE_DIRECTORY_ENTRY typedef LPVOID
PIMAGE_RESOURCE_DATA_ENTRY      typedef LPVOID
PIMAGE_RESOURCE_DIR_STRING_U    typedef LPVOID

IMAGE_ORDINAL_FLAG32 equ 80000000H
IMAGE_ORDINAL32      equ 0000FFFFH
  
FILE_PATH_LEN equ 256
SIGN_BUF_LEN  equ 32
SKIP_LENGTH   equ 1
KEY_ENCRPTY   equ 0Ah

SSoftSign STRUCT 1
  bLength   BYTE 0  ;;;[0,255]
  wVersion1 WORD 0  ;;;[0,65535]
  bVersion2 BYTE 0  ;;;[0,255]
  bVersion3 BYTE 0  ;;;[0,255]
  ;;dwSoftName DWORD 0
  ;;dwAuthor   DWORD 0
  ;;dwEmail    DWORD 0
SSoftSign ENDS
PSOFTSIGN typedef LPVOID

SString STRUCT
  bLength BYTE 0
  strBuffer TCHAR SIGN_BUF_LEN dup(0)
SString ENDS
PSTRING typedef LPVOID

SPeFormat STRUCT
  lpDosHdr PIMAGE_DOS_HEADER         0 ;//DOS Header
  lpNtHdr  PIMAGE_NT_HEADERS         0 ;//NT Header
  lpFilHdr PIMAGE_FILE_HEADER        0 ;//File Header
  lpOptHdr PIMAGE_OPTIONAL_HEADER    0 ;//Optional Header
  lpDatDir PIMAGE_DATA_DIRECTORY     0 ;//Data Directory
  lpBlkTbl PIMAGE_SECTION_HEADER     0 ;//Section Table
  lpExpBlk PIMAGE_DATA_DIRECTORY     0 ;//Export Block(VirtualAddress && Size)
  lpExpTbl PIMAGE_EXPORT_DIRECTORY   0 ;//Export Directory(FOA)
  lpImpBlk PIMAGE_DATA_DIRECTORY     0 ;//Import Block(VirtualAddress && Size)
  lpImpTbl PIMAGE_IMPORT_DESCRIPTOR  0 ;//Import Directory(FOA)
  lpResBlk PIMAGE_DATA_DIRECTORY     0 ;//Resource Directory(VirtualAddress && Size)
  lpResTbl PIMAGE_RESOURCE_DIRECTORY 0 ;//Resource Directory(FOA)
  lpRlcBlk PIMAGE_DATA_DIRECTORY     0 ;//Base Relocation Block(VirtualAddress && Size)
  lpRlcTbl PIMAGE_BASE_RELOCATION    0 ;//Base Relocation Table(FOA)
  lpDbgBlk PIMAGE_DATA_DIRECTORY     0 ;//Debug Block(VirtualAddress && Size)
  lpDbgTbl PIMAGE_DEBUG_DIRECTORY    0 ;//Debug Directory(FOA)
  lpTlsBlk PIMAGE_DATA_DIRECTORY     0 ;//TLS Block(VirtualAddress && Size)
  lpTlsTbl PIMAGE_TLS_DIRECTORY      0 ;//TLS Directory(FOA)
  lpIatBlk PIMAGE_DATA_DIRECTORY     0 ;//Import Address Table Block(VirtualAddress && Size)
  lpIatTbl PIMAGE_THUNK_DATA         0 ;//Import Address Table(FOA)
SPeFormat ENDS

FORMAT_PE typedef SPeFormat

SPeFile STRUCT
  strFileName TCHAR FILE_PATH_LEN dup(0)
  hFile    HANDLE 0
  hMapFile HANDLE 0
  lpvBase  LPVOID 0
  strBase  LPBYTE 0
  stFmtPe  FORMAT_PE <0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>
  
  ;;功能: 打开一个PE文件;
  ;;参数: strFileName: PE文件的路径名;
  ;;dwDesiredAccess: 需要使用的访问模式,可选值有GENERIC_READ/GENERIC_WRITE,默认为GENERIC_READ;
  ;;DWORD dwShareMode: 需要使用的共享模式,可选值有FILE_SHARE_READ/FILE_SHARE_WRITE,默认为FILE_SHARE_READ;
  ;;结果: 如果文件打开成功,则返回TRUE;否则,返回FALSE;
  ;;BOOL Open(LPCTSTR strFileName, DWORD dwDesiredAccess/* = GENERIC_READ*/, DWORD dwShareMode/* = FILE_SHARE_READ*/);
  Open    DWORD 0
  
  ;;功能: 创建文件的内存映射对象;
  ;;参数: dwMapProtect: 调用CreateFileMapping()时使用的映射保护模式,可选值有PAGE_READONLY/PAGE_READWRITE/PAGE_WRITECOPY,默认为PAGE_READONLY;
  ;;lpObjectName: 映射对象名字符串,默认为NULL;
  ;;结果: 如果创建成功,则返回TRUE;否则,返回FALSE;
  ;;BOOL MapFile(DWORD dwMapProtect, LPCSTR lpObjectName/* = NULL*/);
  MapFile DWORD 0
  
  ;;功能: 把文件内容以视图的方式映射到文件映射对象中;
  ;;参数: dwDesiredViewAccess: 调用MapViewOfFile()时需要使用的映射视图访问模式,可选值有FILE_MAP_READ/FILE_MAP_WRITE/FILE_MAP_ALL_ACCESS,默认为FILE_MAP_READ;
  ;;dwNumberOfBytesToMap: 映射的字节数,默认为0,表示全部内容都映射到内存中;
  ;;结果: 如果映射成功,则返回TRUE;否则,返回FALSE;
  ;;BOOL MapFileView(DWORD dwDesiredViewAccess, SIZE_T dwNumberOfBytesToMap/* = 0*/);
  MapFileView DWORD 0
  
  ;;功能: 把文件内容映射视图从内存映射对象中撤销;
  ;;参数: void
  ;;结果: 如果映射视图撤销成功,则返回TRUE;否则,返回FALSE;
  ;;BOOL UnMapFileView(VOID);
  UnMapFileView DWORD 0
  
  ;;功能: 打开一个PE文件;
  ;;参数: strFileName: PE文件的路径名;
  ;;lpResult: 存放文件打开过程中的错误码;
  ;;dwDesiredAccess: 需要使用的访问模式,可选值有GENERIC_READ/GENERIC_WRITE,默认为GENERIC_READ;
  ;;dwShareMode: 需要使用的共享模式,可选值有FILE_SHARE_READ/FILE_SHARE_WRITE,默认为FILE_SHARE_READ;
  ;;dwMapProtect: 调用CreateFileMapping()时使用的映射保护模式,可选值有PAGE_READONLY/PAGE_READWRITE/PAGE_WRITECOPY,默认为PAGE_READONLY;
  ;;dwDesiredViewAccess: 调用MapViewOfFile()时需要使用的映射视图访问模式,可选值有FILE_MAP_READ/FILE_MAP_WRITE/FILE_MAP_ALL_ACCESS,默认为FILE_MAP_READ;
  ;;结果: 如果文件打开成功,则返回TRUE,lpResult指向的内存的值为0;否则,返回FALSE,lpResult指向的内存的值为错误码;
  ;;BOOL OpenEx(LPCTSTR strFileName, LPDWORD lpResult, DWORD dwDesiredAccess/* = GENERIC_READ*/, DWORD dwShareMode/* = FILE_SHARE_READ*/, DWORD dwMapProtect/* = PAGE_READONLY*/, DWORD dwDesiredViewAccess/* = FILE_MAP_READ*/);
  ;;VOID Close(VOID);
  OpenEx DWORD 0
  Close  DWORD 0
  
  ;;DWORD (*Rva2Foa)(DWORD dwRva);
  Rva2Foa DWORD 0
  ;;DWORD (*Foa2Rva)(DWORD dwFoa);
  Foa2Rva DWORD 0
  ;;LPSTR (*GetMachineString)(WORD machine);
  GetMachineString DWORD 0
  ;;LPSTR (*GetSubsystemString)(WORD subsystem, WORD magic);
  GetSubsystemString DWORD 0
  ;;DWORD (*GetSectionProperty)(LPSTR strBuf, WORD wBufSize, DWORD dwCharacteristic);
  GetSectionProperty DWORD 0
  ;;DWORD (*Encrpty)(LPBYTE lpStart, WORD wLength, CONST BYTE bKey);
  Encrpty DWORD 0
  ;;DWORD (*Decrpty)(LPBYTE lpStart, WORD wLength, CONST BYTE bKey);
  Decrpty DWORD 0
  
  ;;return: OK-TRUE,FAILED-FALSE
  ;;TRUE  -> (struct SPeFormat*)(*lpdwResult),lpdwResult是一个指向struct SPeFormat结构的指针;
  ;;FALSE -> (*lpResult) is reason for failed;
  ;;BOOL Parse(LPDWORD lpdwResult);
  Parse DWORD 0
SPeFile ENDS

PE_Open PROTO NEAR32 STDCALL __strFileName:LPCTSTR, __dwDesiredAccess:DWORD, __dwShareMode:DWORD
PE_MapFile PROTO NEAR32 STDCALL __dwMapProtect:DWORD
PE_MapFileView PROTO NEAR32 STDCALL __dwDesiredViewAccess:DWORD, __dwNumberOfBytesToMap:DWORD
PE_UnMapFileView PROTO NEAR32 STDCALL
PE_OpenEx PROTO NEAR32 STDCALL __strFileName:LPCTSTR, __lpResult:LPDWORD, __dwDesiredAccess:DWORD, __dwShareMode:DWORD, __dwMapProtect:DWORD, __dwDesiredViewAccess:DWORD
PE_Close PROTO NEAR32 STDCALL
PE_GetMachineString PROTO NEAR32 STDCALL __machine:DWORD
PE_GetSubsystemString PROTO NEAR32 STDCALL __subsystem:DWORD, __magic:DWORD
PE_GetSectionProperty PROTO NEAR32 STDCALL __strBuf:LPSTR, __dwBufSize:DWORD, __dwCharacteristic:DWORD
PE_GetFileType PROTO NEAR32 STDCALL __dwCharacteristics:DWORD
PE_Encrpty PROTO NEAR32 STDCALL __lpStart:LPBYTE, __dwLength:DWORD, __dwKey:DWORD
PE_Decrpty PROTO NEAR32 STDCALL __lpStart:LPBYTE, __dwLength:DWORD, __dwKey:DWORD
PE_Rva2Foa PROTO NEAR32 STDCALL __dwRva:DWORD
PE_Foa2Rva PROTO NEAR32 STDCALL __dwFoa:DWORD
PE_Parse PROTO NEAR32 STDCALL __lpdwResult:LPDWORD
AcquirePeFile PROTO NEAR32 STDCALL
ReleasePeFile PROTO NEAR32 STDCALL
