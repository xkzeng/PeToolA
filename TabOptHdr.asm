;;TabOptHdr.asm: Implementation File
;;

;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

;;;头文件;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>
include Define.inc
include WndRes.inc
include PeFile.inc

EXTERN strCapInf:BYTE, strCapErr:BYTE
EXTERN strFmtStrL:BYTE, strFmt2XL:BYTE, strFmt4XL:BYTE, strFmt8XL:BYTE
EXTERN g_lpOptHdr:PIMAGE_OPTIONAL_HEADER

.const
   strInvalidOptHdr db '获取的OptionalHeader无效', 0
   strFmtSubSystem  db ' %04X -> %s', 0
   strDataDirectory db 'NEXT', 0

.data
   _hWnd HWND NULL ;;当前页面窗口的句柄;

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

_Get1Byte proc NEAR32 STDCALL PRIVATE __dwAddr:DWORD, __dwEdtID:DWORD
  local @strMsg[6]:CHAR
  pushad
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bl, BYTE PTR [__dwAddr]
  invoke wsprintf, addr @strMsg, offset strFmt2XL, ebx
  invoke GetDlgItem, _hWnd, __dwEdtID
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  popad
  mov eax, 0
  ret
_Get1Byte endp

_Get2Byte proc NEAR32 STDCALL PRIVATE __dwAddr:DWORD, __dwEdtID:DWORD
  local @strMsg[8]:CHAR
  pushad
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [__dwAddr]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, __dwEdtID
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  popad
  mov eax, 0
  ret
_Get2Byte endp

_Get4Byte proc NEAR32 STDCALL PRIVATE __dwData:DWORD, __dwEdtID:DWORD
  local @strMsg[12]:CHAR
  pushad
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke wsprintf, addr @strMsg, offset strFmt8XL, __dwData
  invoke GetDlgItem, _hWnd, __dwEdtID
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  popad
  mov eax, 0
  ret
_Get4Byte endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD
  local @tmp[4]:DWORD
  local @strTime[32]:CHAR
  local @strMsg[TEMP_BUFF_SIZE]:CHAR
  mov @dwRet, TRUE
  
  .if g_lpOptHdr == NULL
      invoke MessageBox, _hWnd, offset strInvalidOptHdr, offset strCapErr, MSG_BTN_STYLE_ERR
      mov @dwRet, FALSE
      jmp ERR_Fill
  .endif
  
  pushad
  xor esi, esi
  mov esi, g_lpOptHdr ; esi ---> IMAGE_OPTIONAL_HEADER
  
  ;;Magic
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.Magic]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MAGIC
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  ;invoke _Get2Byte, esi + IMAGE_OPTIONAL_HEADER.Magic, IDC_EDT_OPT_MAGIC
  
  ;;MajorLinkerVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bl, BYTE PTR [esi + IMAGE_OPTIONAL_HEADER.MajorLinkerVersion]
  invoke wsprintf, addr @strMsg, offset strFmt2XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MAJORLINKERVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MinorLinkerVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bl, BYTE PTR [esi + IMAGE_OPTIONAL_HEADER.MinorLinkerVersion]
  invoke wsprintf, addr @strMsg, offset strFmt2XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MINORLINKERVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;SizeOfCode
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfCode]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFCODE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfCode], IDC_EDT_OPT_SIZEOFCODE
  
  ;;SizeOfInitializedData
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfInitializedData]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFINITIALIZEDDATA
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfInitializedData], IDC_EDT_OPT_SIZEOFINITIALIZEDDATA
  
  ;;SizeOfUninitializedData
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfUninitializedData]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFUNINITIALIZEDDATA
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfUninitializedData], IDC_EDT_OPT_SIZEOFUNINITIALIZEDDATA
  
  ;;AddressOfEntryPoint
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.AddressOfEntryPoint]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_ADDRESSOFENTRYPOINT
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.AddressOfEntryPoint], IDC_EDT_OPT_ADDRESSOFENTRYPOINT
  
  ;;BaseOfCode
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.BaseOfCode]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_BASEOFCODE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.BaseOfCode], IDC_EDT_OPT_BASEOFCODE
  
  ;;BaseOfData
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.BaseOfData]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_BASEOFDATA
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.BaseOfData], IDC_EDT_OPT_BASEOFDATA
  
  ;;ImageBase
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.ImageBase]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_IMAGEBASE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.ImageBase], IDC_EDT_OPT_IMAGEBASE
  
  ;;SectionAlignment
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SectionAlignment]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SECTIONALIGNMENT
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SectionAlignment], IDC_EDT_OPT_SECTIONALIGNMENT
  
  ;;FileAlignment
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.FileAlignment]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_FILEALIGNMENT
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.FileAlignment], IDC_EDT_OPT_FILEALIGNMENT
  
  ;;MajorOperatingSystemVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.MajorOperatingSystemVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MAJOROPERATINGSYSTEMVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MinorOperatingSystemVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.MinorOperatingSystemVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MINOROPERATINGSYSTEMVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MajorImageVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.MajorImageVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MAJORIMAGEVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MinorImageVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.MinorImageVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MINORIMAGEVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MajorSubsystemVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.MajorSubsystemVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MAJORSUBSYSTEMVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MinorSubsystemVersion
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.MinorSubsystemVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_MINORSUBSYSTEMVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Win32VersionValue
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.Win32VersionValue]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_WIN32VERSIONVALUE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.Win32VersionValue], IDC_EDT_OPT_WIN32VERSIONVALUE
  
  ;;SizeOfImage
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfImage]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFIMAGE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfImage], IDC_EDT_OPT_SIZEOFIMAGE
  
  ;;SizeOfHeaders
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfHeaders]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFHEADERS
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfHeaders], IDC_EDT_OPT_SIZEOFHEADERS
  
  ;;CheckSum
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.CheckSum]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_CHECKSUM
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.CheckSum], IDC_EDT_OPT_CHECKSUM
  
  ;;Subsystem
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.Subsystem] ;Subsystem
  xor edx, edx
  mov dx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.Magic]     ;Magic
  invoke PE_GetSubsystemString, ebx, edx
  invoke wsprintf, addr @strMsg, offset strFmtSubSystem, ebx, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SUBSYSTEM
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;DllCharacteristics
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_OPTIONAL_HEADER.DllCharacteristics]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_DLLCHARACTERISTICS
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;SizeOfStackReserve
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfStackReserve]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFSTACKRESERVE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfStackReserve], IDC_EDT_OPT_SIZEOFSTACKRESERVE
  
  ;;SizeOfStackCommit
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfStackCommit]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFSTACKCOMMIT
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfStackCommit], IDC_EDT_OPT_SIZEOFSTACKCOMMIT
  
  ;;SizeOfHeapReserve
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfHeapReserve]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFHEAPRESERVE
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfHeapReserve], IDC_EDT_OPT_SIZEOFHEAPRESERVE
  
  ;;SizeOfHeapCommit
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.SizeOfHeapCommit]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_SIZEOFHEAPCOMMIT
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.SizeOfHeapCommit], IDC_EDT_OPT_SIZEOFHEAPCOMMIT
  
  ;;LoaderFlags
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.LoaderFlags]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_LOADERFLAGS
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.LoaderFlags], IDC_EDT_OPT_LOADERFLAGS
  
  ;;NumberOfRvaAndSizes
  ;invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  ;xor ebx, ebx
  ;mov ebx, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.NumberOfRvaAndSizes]
  ;invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  ;invoke GetDlgItem, _hWnd, IDC_EDT_OPT_NUMBEROFRVAANDSIZES
  ;mov ebx, eax
  ;invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  invoke _Get4Byte, [esi + IMAGE_OPTIONAL_HEADER.NumberOfRvaAndSizes], IDC_EDT_OPT_NUMBEROFRVAANDSIZES
  
  ;;DataDirectory
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke wsprintf, addr @strMsg, offset strFmtStrL, offset strDataDirectory
  invoke GetDlgItem, _hWnd, IDC_EDT_OPT_DATA_DIR
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  popad
  mov @dwRet, TRUE
  
  ERR_Fill:
  mov eax, @dwRet
  ret
_Fill endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Message Handlers
_OnFillForm proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  pushad
  invoke _Fill, NULL
  popad
  mov eax, TRUE
  ret
_OnFillForm endp

;;实现应用程序对话框过程;
OptHdrProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_FILLFORM
     invoke _OnFillForm, __wParam, __lParam
     mov @dwResult, TRUE
  .else
     mov @dwResult, FALSE
  .endif
  popad
  mov eax, @dwResult
  ret
OptHdrProc endp

END
