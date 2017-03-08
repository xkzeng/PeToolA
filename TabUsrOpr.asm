;;TabUsrOpr.asm: Implementation File
;;

;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

;;;头文件;;;
include <windows.inc>
include <user32.inc>
include <kernel32.inc>
include <msvcrt.inc>
include <shlwapi.inc>
include Define.inc
include WndRes.inc
include PeFile.inc
include PeToolA.inc

EXTERN strCapInf:BYTE, strCapErr:BYTE
EXTERN strFmt2D:BYTE, strFmt4D:BYTE, strFmt8X:BYTE, strFmt8XL:BYTE
EXTERN strDefSoftName:BYTE, strDefAuthor:BYTE, strDefEmail:BYTE
EXTERN g_lpExpTbl:PIMAGE_EXPORT_DIRECTORY, g_lpExpBlk:PIMAGE_DATA_DIRECTORY
EXTERN g_lpImpTbl:PIMAGE_IMPORT_DESCRIPTOR, g_lpImpBlk:PIMAGE_DATA_DIRECTORY
EXTERN g_lpBlkTbl:PIMAGE_SECTION_HEADER, g_lpFilHdr:PIMAGE_FILE_HEADER
EXTERN g_strBase:LPBYTE, g_hWndMain:HWND, g_aTabPages:SPePage

.const
   strRVA db 'RVA', 0
   strFOA db 'FOA', 0
   strSrcAddrErr  db '源地址必须是8个字符长的十六进制数', 0
   strNoKey       db '没有数据查找依据,或者输入的信息太长,最大信息长度是%d', 0
   strBaseErr     db '查询时探测到文件基址无效', 0
   strImpTblErr   db '查询时探测到导入表无效', 0
   strExpTblErr   db '查询时探测到导出表无效', 0
   strNoImpTbl    db '该PE文件没有导入表', 0
   strNoExpTbl    db '该PE文件没有导出表', 0
   strFmtImpFound db '%s: %s', 0DH, 0AH, '%-4s: %s', 0DH, 0AH, '%-4s: %08X', 0DH, 0AH, '%-4s: %08X', 0DH, 0AH, '%-4s: %08X', 0DH, 0AH, '%-4s: %04X', 0
   strFmtExpFound db '%s: %s', 0DH, 0AH, '%-4s: %04X', 0DH, 0AH, '%-4s: %04X', 0DH, 0AH, '%-4s: %08X', 0
   strFunc        db 'Func', 0
   strDLL         db 'DLL', 0
   strIAT         db 'IAT', 0
   strHint        db 'Hint', 0
   strOrdi        db 'Ordi', 0
   strAddr        db 'Addr', 0
   strNotFound    db '"%s" is not found!!!', 0
   strSignBaseErr db '签名时,探测到文件基址无效', 0
   strSBlkTblErr  db '签名时,节表无效', 0
   strSignTooLong db '签名信息可能太长,找不到合适的地方存放签名信息', 0
   strSignSectErr db '签名时,找到的签名位置是无效的', 0
   strSignOK      db 'Signed OK!!!', 0
   strRdSgBaseErr db '读取签名时,探测到文件基址无效', 0
   strRdSgSectErr db '读取签名时,节表无效', 0
   strNoAddrForSg db '读取签名信息时,找不到存放签名信息的地方', 0
   strSgAddrErr   db '读取签名时,找到的位置是无效的', 0
   strNoSoftSign  db '没有找到签名信息,该PE文件有可能没有签名', 0
   strGetHeapErr  db '获取进程的堆对象句柄失败,不能进行内存分配!!!', 0
   strMemAllocErr db '解析软件签名时,分配内存失败', 0

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

_UpdateCheckBox proc NEAR32 STDCALL PRIVATE
  pushad
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_CHECK_ADDRESS_CONVERT
  invoke SendMessage, eax, BM_GETCHECK, 0, 0
  .if (eax == BST_UNCHECKED)    ;;;DEFAULT
     mov esi, offset strRVA
     mov edi, offset strFOA
  .elseif (eax == BST_CHECKED)
     mov esi, offset strFOA
     mov edi, offset strRVA
  .else                         ;;;DEFAULT
     mov esi, offset strRVA
     mov edi, offset strFOA
  .endif
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_STATIC_SRC
  invoke SendMessage, eax, WM_SETTEXT, 0, esi
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_STATIC_DST
  invoke SendMessage, eax, WM_SETTEXT, 0, edi
  popad
  mov eax, TRUE
  ret
_UpdateCheckBox endp

_EnableSignControl proc NEAR32 STDCALL PRIVATE __bEnable:DWORD
  local @dwEnable:DWORD
  
  .if __bEnable == TRUE
     mov @dwEnable, FALSE
  .else
     mov @dwEnable, TRUE
  .endif
  
  pushad
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER1
  invoke SendMessage, eax, EM_SETREADONLY, @dwEnable, 0
  
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER2
  invoke SendMessage, eax, EM_SETREADONLY, @dwEnable, 0
  
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER3
  invoke SendMessage, eax, EM_SETREADONLY, @dwEnable, 0
  
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_SOFT_NAME
  invoke SendMessage, eax, EM_SETREADONLY, @dwEnable, 0
  
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_AUTHOR
  invoke SendMessage, eax, EM_SETREADONLY, @dwEnable, 0
  
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_EMAIL
  invoke SendMessage, eax, EM_SETREADONLY, @dwEnable, 0
  
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_BTN_SOFT_SIGN
  invoke EnableWindow, eax, __bEnable
  popad
  mov eax, TRUE
  ret
_EnableSignControl endp

_UseDefaultSign proc NEAR32 STDCALL PRIVATE
  local @stSysTime:SYSTEMTIME
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  
  pushad
  ;;SoftName:
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_SOFT_NAME
  invoke SendMessage, eax, WM_SETTEXT, 0, offset strDefSoftName
  
  ;;Author:
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_AUTHOR
  invoke SendMessage, eax, WM_SETTEXT, 0, offset strDefAuthor
  
  ;;Get System Time
  invoke RtlZeroMemory, addr @stSysTime, sizeof SYSTEMTIME
  invoke GetSystemTime, addr @stSysTime
  
  ;;Version1:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, @stSysTime.wYear
  invoke wsprintf, addr @strMsg, offset strFmt4D, eax
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER1
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Version2:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, @stSysTime.wMonth
  invoke wsprintf, addr @strMsg, offset strFmt2D, eax
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER2
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Version3:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, @stSysTime.wDay
  invoke wsprintf, addr @strMsg, offset strFmt2D, eax
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER3
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Email:
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_EMAIL
  invoke SendMessage, eax, WM_SETTEXT, 0, offset strDefEmail
  popad
  mov eax, TRUE
  ret
_UseDefaultSign endp

GetSignSegment proc NEAR32 STDCALL PUBLIC __dwSignLength:DWORD, __lpSignBase:LPDWORD, __lpPointerToRawData:LPDWORD, __lpVirtualSize:LPDWORD
  local @dwRet:DWORD, @dwCharacteristics:DWORD
  local @dwNumberOfSections:DWORD
  mov @dwRet, 0
  
  pushad
  
  .if (g_strBase == NULL)
     mov @dwRet, 1
     jmp RET_GetSignSegment
  .endif
  
  .if ((g_lpBlkTbl == NULL) || (g_lpFilHdr == NULL))
     mov @dwRet, 2
     jmp RET_GetSignSegment
  .endif
  
  ;;Number of Sections
  xor esi, esi
  mov esi, g_lpFilHdr    ; esi ---> IMAGE_FILE_HEADER
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_FILE_HEADER.NumberOfSections]
  mov @dwNumberOfSections, eax  ;Number of Sections
  
  ;;Base of Section Table
  xor esi, esi
  mov esi, g_lpBlkTbl    ;esi ---> IMAGE_SECTION_HEADER; Base Address of Section Table
  
  xor ecx, ecx           ;ecx = 0
  .while ecx < @dwNumberOfSections
     ;;Characteristics
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.Characteristics]
     mov @dwCharacteristics, eax
     
     ;;SizeOfRawData
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.SizeOfRawData]
     
     ;;lpSection->SizeOfRawData - lpSection->Misc.VirtualSize
     sub eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.Misc.VirtualSize]
     
     ;;该节具有可读(R)、可执行(E)、包含代码(C)的属性,则该节就是代码段(.text;CODE);如果该节后面的剩余空间长度大于签名信息总长度,则该节适合存放签名信息;
     .if ((@dwCharacteristics & IMAGE_SCN_MEM_READ) && (@dwCharacteristics & IMAGE_SCN_MEM_EXECUTE) && (@dwCharacteristics & IMAGE_SCN_CNT_CODE))
        .if __dwSignLength == CODE_SEG_RO
           .break
        .endif
        .if (eax > __dwSignLength)
           .break
        .endif
     .endif
     
     ;Next
     inc ecx ;next index
     add esi, sizeof IMAGE_SECTION_HEADER ;next Section
  .endw
  
  .if (ecx == @dwNumberOfSections)
     mov @dwRet, 3
     jmp RET_GetSignSegment
  .endif
  
  .if (esi == NULL)
     mov @dwRet, 4
     jmp RET_GetSignSegment
  .endif
  
  ;;;;找到符合条件的代码段之后,计算签名信息在该段中的位置,并设置需要返回的信息;
  ;;esi ---> IMAGE_SECTION_HEADER
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.PointerToRawData]
  xor edx, edx
  mov edx, DWORD PTR [esi + IMAGE_SECTION_HEADER.Misc.VirtualSize]
  
  xor ebx, ebx
  mov ebx, g_strBase
  add ebx, eax         ;;PointerToRawData
  add ebx, edx         ;;VirtualSize
  add ebx, SKIP_LENGTH ;;strFileBase + lpSection->PointerToRawData + lpSection->Misc.VirtualSize + SKIP_LENGTH
  mov esi, ebx         ;;此时,ebx/esi ---> SSoftSign
  
  ;;;;
  ;;Base of Sign
  xor edi, edi
  mov edi, __lpSignBase
  .if edi
     mov DWORD PTR [edi], ebx      ;;ret SignBase
  .endif
  
  ;;PointerToRawData
  xor edi, edi
  mov edi, __lpPointerToRawData
  .if edi
     mov DWORD PTR [edi], eax      ;;ret PointerToRawData
  .endif
  
  ;;VirtualSize
  xor edi, edi
  mov edi, __lpVirtualSize
  .if edi
     mov DWORD PTR [edi], edx      ;;ret VirtualSize
  .endif
  
  mov @dwRet, 0 ;;Success
  
  RET_GetSignSegment:
  popad
  mov eax, @dwRet
  ret
GetSignSegment endp

GetSignInfo proc NEAR32 STDCALL PUBLIC __lpSignBase:LPDWORD, __lpSign:LPDWORD, __lpSoftName:LPDWORD, __lpAuthor:LPDWORD, __lpEmail:LPDWORD
  local @dwRet:DWORD, @dwSignLength:DWORD
  mov @dwRet, TRUE
  pushad
  
  ;;;;;Soft Sign<<<<<<<<<<
  xor esi, esi
  mov esi, __lpSignBase ;;Base of soft sign; esi ---> SSoftSign
  
  xor edi, edi
  mov edi, __lpSign
  
  ;;Sign Length
  xor eax, eax
  mov al, BYTE PTR [esi + SSoftSign.bLength]
  mov BYTE PTR [edi + SSoftSign.bLength], al
  mov @dwSignLength, eax
  
  ;;Version1:
  xor eax, eax
  mov ax, WORD PTR [esi + SSoftSign.wVersion1]
  mov WORD PTR [edi + SSoftSign.wVersion1], ax
  
  ;;Version2:
  xor eax, eax
  mov al, BYTE PTR [esi + SSoftSign.bVersion2]
  mov BYTE PTR [edi + SSoftSign.bVersion2], al
  
  ;;Version3:
  xor eax, eax
  mov al, BYTE PTR [esi + SSoftSign.bVersion3]
  mov BYTE PTR [edi + SSoftSign.bVersion3], al
  
  ;;;;;Soft Name<<<<<<<<<<
  add esi, sizeof SSoftSign ;;esi -> SoftName:SString
  
  xor edi, edi
  mov edi, __lpSoftName
  
  ;;Length
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov BYTE PTR [edi + SString.bLength], al
  
  ;;strBuf
  add esi, SString.strBuffer
  add edi, SString.strBuffer
  invoke CopyMemory, edi, esi, eax ;;eax = copy length, returned by CopyMemory()
  
  ;;;;;Author<<<<<<<<<<
  add esi, eax ;;esi -> SoftName:SString
  
  xor edi, edi
  mov edi, __lpAuthor
  
  ;;Length
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov BYTE PTR [edi + SString.bLength], al
  
  ;;strBuf
  add esi, SString.strBuffer
  add edi, SString.strBuffer
  invoke CopyMemory, edi, esi, eax ;;eax = copy length, returned by CopyMemory()
  
  ;;;;;Email<<<<<<<<<<
  add esi, eax ;;esi -> Email:SString
  
  xor edi, edi
  mov edi, __lpEmail
  
  ;;Length
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov BYTE PTR [edi + SString.bLength], al
  
  ;;strBuf
  add esi, SString.strBuffer
  add edi, SString.strBuffer
  invoke CopyMemory, edi, esi, eax ;;eax = copy length, returned by CopyMemory()
  
  popad
  mov eax, TRUE
  ret
GetSignInfo endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD, @dwSignLength:DWORD, @dwSignBase:DWORD
  local @dwStrLen:DWORD ;;, @dwPointerToRawData:DWORD, @dwVirtualSize:DWORD
  local	@stSign:SSoftSign
  local	@stSoftName:SString
  local	@stAuthor:SString
  local	@stEmail:SString
  local @strBackUp:LPBYTE, @hHeap:HANDLE
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  mov @dwSignBase, 0
  ;mov @dwPointerToRawData, 0
  ;mov @dwVirtualSize, 0
  
  ;;查找可执行的代码段,并返回代码段的起始地址(FOA:PointerToRawData);
  xor eax, eax
  invoke GetSignSegment, CODE_SEG_RO, addr @dwSignBase, NULL, NULL ;;addr @dwPointerToRawData, addr @dwVirtualSize
  .if (eax == 1)
     invoke MessageBox, _hWnd, offset strRdSgBaseErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  
  .if (eax == 2)
     invoke MessageBox, _hWnd, offset strRdSgSectErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  
  .if (eax == 3)
     invoke MessageBox, _hWnd, offset strNoAddrForSg, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  
  .if (eax == 4)
     invoke MessageBox, _hWnd, offset strSgAddrErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  
  ;;Enable the sign control
  invoke _EnableSignControl, TRUE
  
  xor esi, esi
  mov esi, @dwSignBase ;;;esi ---> SSoftSign: base of Soft Sign
  
  ;;Total length of SoftSign
  xor eax, eax
  mov al, BYTE PTR [esi + SSoftSign.bLength]
  .if eax == 0
     invoke MessageBox, _hWnd, offset strNoSoftSign, offset strCapErr, MSG_BTN_STYLE_WRN
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  mov @dwSignLength, eax
  
  ;;Get Process Heap
  mov @hHeap, NULL
  xor eax, eax
  invoke GetProcessHeap
  .if eax == NULL
     invoke MessageBox, _hWnd, offset strGetHeapErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  mov @hHeap, eax
  
  ;;Alloc Memory
  mov @strBackUp, 0
  xor eax, eax
  invoke HeapAlloc, @hHeap, HEAP_ZERO_MEMORY, @dwSignLength
  .if eax == NULL
     invoke MessageBox, _hWnd, offset strMemAllocErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_Fill
  .endif
  mov @strBackUp, eax
  
  ;;Backup all bytes of SoftSign
  invoke CopyMemory, @strBackUp, @dwSignBase, @dwSignLength ;;@dwSignLength return by eax;
  
  ;;Decrpty SoftSign
  xor ecx, ecx
  mov ecx, eax
  sub ecx, sizeof SSoftSign.bLength ;;length to decrpty
  
  xor esi, esi
  mov esi, @strBackUp
  add esi, sizeof SSoftSign.bLength ;;base address to decrpty
  invoke PE_Decrpty, esi, ecx, KEY_ENCRPTY
  
  invoke RtlZeroMemory, addr @stSign, sizeof SSoftSign
  invoke RtlZeroMemory, addr @stSoftName, sizeof SString
  invoke RtlZeroMemory, addr @stAuthor, sizeof SString
  invoke RtlZeroMemory, addr @stEmail, sizeof SString
  
  xor esi, esi
  mov esi, @strBackUp
  
  ;;;;Version:
  invoke CopyMemory, addr @stSign, esi, sizeof SSoftSign
  
  ;;Version1
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, @stSign.wVersion1
  invoke wsprintf, addr @strMsg, offset strFmt4D, eax
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER1
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Version2
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov al, @stSign.bVersion2
  invoke wsprintf, addr @strMsg, offset strFmt2D, eax
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER2
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Version3:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov al, @stSign.bVersion3
  invoke wsprintf, addr @strMsg, offset strFmt2D, eax
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER3
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;SoftName:
  add esi, sizeof SSoftSign ;;;esi ---> SoftName:SString
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov @dwStrLen, eax
  add eax, sizeof SString.bLength
  invoke CopyMemory, addr @stSoftName, esi, eax
  xor ebx, ebx
  lea ebx, @stSoftName
  add ebx, SString.strBuffer ;;pointer to SoftName-String
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_SOFT_NAME
  mov edx, eax
  invoke SendMessage, edx, WM_SETTEXT, 0, ebx
  
  ;;Author:
  add esi, sizeof SString.bLength
  add esi, @dwStrLen   ;;;esi -->Author:SString
  
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov @dwStrLen, eax
  add eax, sizeof SString.bLength
  invoke CopyMemory, addr @stAuthor, esi, eax
  xor ebx, ebx
  lea ebx, @stAuthor
  add ebx, SString.strBuffer ;;pointer to Author-String
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_AUTHOR
  mov edx, eax
  invoke SendMessage, edx, WM_SETTEXT, 0, ebx
  
  ;;Email:
  add esi, sizeof SString.bLength
  add esi, @dwStrLen   ;;;esi -->Email:SString
  
  xor eax, eax
  mov al, BYTE PTR [esi + SString.bLength]
  mov @dwStrLen, eax
  add eax, sizeof SString.bLength
  invoke CopyMemory, addr @stEmail, esi, eax
  xor ebx, ebx
  lea ebx, @stEmail
  add ebx, SString.strBuffer ;;pointer to Author-String
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_EMAIL
  mov edx, eax
  invoke SendMessage, edx, WM_SETTEXT, 0, ebx
  
  ;;free the buffer
  invoke HeapAlloc, @hHeap, 0, @strBackUp
  
  ;;Disable the sign control
  invoke _EnableSignControl, FALSE
  mov @dwRet, TRUE
  
  EXIT_Fill:
  .if @dwRet == FALSE
     invoke _UseDefaultSign
  .endif
  popad
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

_OnCheckAddressConvert proc NEAR32 STDCALL PRIVATE
  pushad
 	invoke _UpdateCheckBox
 	popad
 	mov eax, TRUE
 	ret
_OnCheckAddressConvert endp

_OnBtnAddressConvert proc NEAR32 STDCALL PRIVATE
  local @dwRet:DWORD, @dwAddr:DWORD
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  mov @dwAddr, 0
  
  pushad
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_ADDR_SRC
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @strMsg, addr @strMsg
  .if eax != 8
     invoke MessageBox, _hWnd, offset strSrcAddrErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnAddressConvert
  .endif
  
  invoke crt_sscanf, addr @strMsg, offset strFmt8X, addr @dwAddr
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_CHECK_ADDRESS_CONVERT
  invoke SendMessage, eax, BM_GETCHECK, 0, 0
  .if (eax == BST_UNCHECKED)     ;;RVA to FOA
     xor eax, eax
     invoke PE_Rva2Foa, @dwAddr
     mov @dwAddr, eax
  .elseif (eax == BST_CHECKED)  ;;FOA to RVA
     xor eax, eax
     invoke PE_Foa2Rva, @dwAddr
     mov @dwAddr, eax
  .else
     mov @dwAddr, 0
  .endif
  
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke crt__snprintf, addr @strMsg, sizeof @strMsg, offset strFmt8XL, @dwAddr
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_ADDR_DST
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  EXIT_OnBtnAddressConvert:
  popad
  mov eax, @dwRet
  ret
_OnBtnAddressConvert endp

_OnBtnSearchImport proc NEAR32 STDCALL PRIVATE
  local @dwRet:DWORD, @bFound:DWORD, @dwFoa:DWORD, @dwKeyLen:LONG
  local @dwName:DWORD, @strDllName:LPCSTR, @strFname:DWORD, @dwHint:DWORD
  local @dwaINT:LPDWORD, @dwaIAT:LPDWORD, @dwIID:DWORD
  local @dwThkINT:DWORD, @dwThkIAT:DWORD
  local @strKey[TEMP_BUFF_SIZE]:TCHAR
  local @strMsg[TEMP_BUFF_SIZE+128]:TCHAR
  mov @dwRet, TRUE
  mov @bFound, FALSE
  
  pushad
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_IMP_KEY
  invoke SendMessage, eax, WM_GETTEXTLENGTH, 0, 0
  .if ((eax <= 0) || (eax > (sizeof @strKey - 1)))
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strNoKey, (sizeof @strKey - 1)
     invoke MessageBox, _hWnd, addr @strMsg, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchImport
  .endif
  
  invoke RtlZeroMemory, addr @strKey, sizeof @strKey
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_IMP_KEY
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @strKey, addr @strKey
  mov @dwKeyLen, eax ;;length of the key
  
  .if (g_strBase == NULL)
     invoke MessageBox, _hWnd, offset strBaseErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchImport
  .endif
  
  .if ((g_lpImpTbl == NULL) || (g_lpImpBlk == NULL))
     invoke MessageBox, _hWnd, offset strImpTblErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchImport
  .endif
  
  xor esi, esi
  mov esi, g_lpImpBlk  ;;; esi ---> origin IMAGE_DATA_DIRECTORY entry, this is not converted by Rva2Foa()
  .if DWORD PTR [esi + IMAGE_DATA_DIRECTORY.isize] == 0
     invoke MessageBox, _hWnd, offset strNoImpTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchImport
  .endif
  
  xor esi, esi
  mov esi, g_lpImpTbl  ;;; esi ---> IMAGE_IMPORT_DESCRIPTOR
  mov @dwIID, esi
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.Name1] ;;;first IID's name
  mov @dwName, eax
  
  ;;begin to search
  mov @bFound, FALSE
  .repeat
     ;;get dll name
     xor eax, eax
     invoke PE_Rva2Foa, @dwName
     add eax, g_strBase
     mov @strDllName, eax ;;strDllName = (LPCSTR)(strFileBase + dwFoa);
     
     ;;start address of the Original First Thunk table,named Import Name Table(INT);
     xor eax, eax
     mov esi, @dwIID
     invoke PE_Rva2Foa, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.OriginalFirstThunk]
     add eax, g_strBase
     mov @dwaINT, eax  ;;dwaINT = (LPDWORD)(strFileBase + dwFoa);
     
     ;;start address of the First Thunk table,named Import Address Table(IAT);
     xor eax, eax
     mov esi, @dwIID
     invoke PE_Rva2Foa, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.FirstThunk]
     add eax, g_strBase
     mov @dwaIAT, eax  ;;dwaIAT = (LPDWORD)(strFileBase + dwFoa);
     
     ;;Iterate the Import Name Table(INT) and Import Address Table(IAT);
     xor eax, eax
     mov esi, @dwaINT
     mov eax, DWORD PTR [esi]
     mov @dwThkINT, eax
     
     xor eax, eax
     mov edi, @dwaIAT
     mov eax, DWORD PTR [edi]
     mov @dwThkIAT, eax
     .repeat
        ;;Import By Ordinal,no operation
        .if (@dwThkINT & IMAGE_ORDINAL_FLAG32)
           jmp NEXT_LOOP
        .endif
        
        ;;Import By Name
        xor eax, eax
        xor eax, eax
        invoke PE_Rva2Foa, @dwThkINT
        mov @dwFoa, eax
        add eax, g_strBase  ;;eax ---> IMAGE_IMPORT_BY_NAME
        ;;;;Hint
        xor ebx, ebx
        mov bx, WORD PTR [eax + IMAGE_IMPORT_BY_NAME.Hint]
        mov @dwHint, ebx
        add eax, IMAGE_IMPORT_BY_NAME.Name1
        mov @strFname, eax
        xor eax, eax
        invoke StrCmpNI, @strFname, addr @strKey, @dwKeyLen  ;;compare, same string
        mov ebx, eax
        xor eax, eax
        invoke StrStrI, @strFname, addr @strKey              ;;substring
        .if ((ebx == 0) || (eax != NULL))
           mov @bFound, TRUE  ;;Found the function
           invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
           invoke wsprintf, addr @strMsg, offset strFmtImpFound, offset strFunc, @strFname, offset strDLL, @strDllName,
                                          offset strRVA, @dwThkINT, offset strFOA, @dwFoa, offset strIAT, @dwThkIAT,
                                          offset strHint, @dwHint
           xor eax, eax
           invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_IMP_RESULT
           mov ebx, eax
           invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
           .break
        .endif
        
        ;Next
        NEXT_LOOP:
        ;add esi, sizeof DWORD    ;;;next IMAGE_THUNK_DATA for INT
        add @dwaINT, sizeof DWORD
        ;add edi, sizeof DWORD    ;;;next IMAGE_THUNK_DATA for IAT
        add @dwaIAT, sizeof DWORD
        mov esi, @dwaINT
        mov eax, DWORD PTR [esi] ;;;read next IMAGE_THUNK_DATA for INT
        mov @dwThkINT, eax
        mov edi, @dwaIAT
        mov eax, DWORD PTR [edi] ;;;read next IMAGE_THUNK_DATA for IAT
        mov @dwThkIAT, eax
     .until ((@dwThkINT == NULL) || (@dwThkIAT == NULL))
     
     .if (@bFound == TRUE)
        .break
     .endif
     
     ;Next
     add @dwIID, sizeof IMAGE_IMPORT_DESCRIPTOR               ;;;next IID
     xor eax, eax
     mov esi, @dwIID
     mov eax, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.Name1] ;;;next IID's name
     mov @dwName, eax
  .until (@dwName == NULL)
  
  .if (@bFound == FALSE)
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strNotFound, addr @strKey
     xor eax, eax
     invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_IMP_RESULT
     mov ebx, eax
     invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchImport
  .endif
  
  mov @dwRet, TRUE
  
  EXIT_OnBtnSearchImport:
  popad
  mov eax, @dwRet
  ret
_OnBtnSearchImport endp

_OnBtnSearchExport proc NEAR32 STDCALL PRIVATE
  local @dwRet:DWORD, @bFound:DWORD
  local @dwFoa:DWORD, @dwAddr:DWORD
  local @dwKeyLen:LONG, @dwOrdinal:DWORD
  local @adwRvaAddrs:LPDWORD
  local @adwRvaNames:LPDWORD
  local @awOrdinals:LPWORD
  local @dwNumberOfNames:DWORD, @dwBase:DWORD
  local @strFuncName:LPCSTR
  local @strKey[TEMP_BUFF_SIZE]:TCHAR
  local @strMsg[TEMP_BUFF_SIZE+128]:TCHAR
  mov @dwRet, TRUE
  mov @bFound, FALSE
  
  pushad
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_EXP_KEY
  invoke SendMessage, eax, WM_GETTEXTLENGTH, 0, 0
  .if ((eax <= 0) || (eax > (sizeof @strKey - 1)))
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strNoKey, (sizeof @strKey - 1)
     invoke MessageBox, _hWnd, addr @strMsg, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchExport
  .endif
  
  invoke RtlZeroMemory, addr @strKey, sizeof @strKey
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_EXP_KEY
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @strKey, addr @strKey
  mov @dwKeyLen, eax ;;length of the key
  
  .if (g_strBase == NULL)
     invoke MessageBox, _hWnd, offset strBaseErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchExport
  .endif
  
  .if ((g_lpExpTbl == NULL) || (g_lpExpBlk == NULL))
     invoke MessageBox, _hWnd, offset strExpTblErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchExport
  .endif
  
  xor esi, esi
  mov esi, g_lpExpBlk  ;;; esi ---> origin IMAGE_DATA_DIRECTORY entry, this is not converted by Rva2Foa()
  .if DWORD PTR [esi + IMAGE_DATA_DIRECTORY.isize] == 0
     invoke MessageBox, _hWnd, offset strNoExpTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchExport
  .endif
  
  xor esi, esi
  mov esi, g_lpExpTbl  ;;; esi ---> IMAGE_EXPORT_DIRECTORY
  
  ;;Base
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.nBase]
  mov @dwBase, eax
  
  ;;函数地址表
  xor eax, eax
  invoke PE_Rva2Foa, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.AddressOfFunctions]
  add eax, g_strBase
  mov @adwRvaAddrs, eax  ;;;RVA Array,so,@adwRvaAddrs[i] is a RVA;
  
  ;;函数名称表
  xor eax, eax
  invoke PE_Rva2Foa, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.AddressOfNames]
  add eax, g_strBase
  mov @adwRvaNames, eax  ;;;RVA Array,so,@adwRvaNames[i] is a RVA;
  
  ;;函数序数表
  xor eax, eax
  invoke PE_Rva2Foa, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals]
  add eax, g_strBase
  mov @awOrdinals, eax
  
  ;;loop count
  mov @dwNumberOfNames, 0
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.NumberOfNames]
  mov @dwNumberOfNames, eax
  
  ;;loop base
  xor esi, esi
  mov esi, @adwRvaNames ;;;函数名称表基址;
  xor edi, edi
  mov edi, @awOrdinals  ;;;函数序数表基址;
  
  ;;begin to search
  mov @bFound, FALSE
  xor ecx, ecx
  .while ecx < @dwNumberOfNames
     push ecx
     ;;Name:
     xor eax, eax
     invoke PE_Rva2Foa, DWORD PTR [esi]
     add eax, g_strBase 
     mov @strFuncName, eax ;;strFuncName = (LPCSTR)strFileBase + dwFoa;
     
     xor eax, eax
     invoke StrCmpNI, @strFuncName, addr @strKey, @dwKeyLen  ;;compare(EQ), same string
     mov ebx, eax
     xor eax, eax
     invoke StrStrI, @strFuncName, addr @strKey              ;;substring
     .if ((ebx == 0) || (eax != NULL))
        mov @bFound, TRUE  ;;Found the function
        ;;Ordinal:
        xor eax, eax
        mov ax, WORD PTR[edi]  ;;;get Ordinal
        mov @dwOrdinal, eax    ;;;dwOrdinal = awOrdinals[i];被乘数
        
        ;;Address:
        xor ebx, ebx
        mov ebx, sizeof DWORD              ;;;乘数
        mul ebx                            ;;;edx:eax = eax * ebx = @wOrdinal * sizeof(DWORD)
        add eax, @adwRvaAddrs              ;;;eax = eax + @adwRvaAddrs
        mov ebx, DWORD PTR [eax]           ;;;取出对应位置处的函数地址;
        mov @dwAddr, ebx
        
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        xor eax, eax
        mov eax, @dwOrdinal
        add eax, @dwBase ;;dwOrdinal + lpIED->Base
        invoke wsprintf, addr @strMsg, offset strFmtExpFound, offset strFunc, @strFuncName, offset strOrdi, eax,
                                       offset strHint, @dwOrdinal, offset strAddr, @dwAddr
        xor eax, eax
        invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_EXP_RESULT
        mov ebx, eax
        invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
        pop ecx
        .break
     .endif
     pop ecx
     
     ;Next
     inc ecx               ;;;next Index
     add esi, sizeof DWORD ;;;next NameRva
     add edi, sizeof WORD  ;;;next Ordinal
  .endw
  
  .if (@bFound == FALSE)
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strNotFound, addr @strKey
     xor eax, eax
     invoke GetDlgItem, _hWnd, IDC_EDT_SRCH_EXP_RESULT
     mov ebx, eax
     invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
     mov @dwRet, FALSE
     jmp EXIT_OnBtnSearchExport
  .endif
  
  mov @dwRet, TRUE
  
  EXIT_OnBtnSearchExport:
  popad
  mov eax, @dwRet
  ret
_OnBtnSearchExport endp

_OnBtnSoftSign proc NEAR32 STDCALL PRIVATE
  local @dwRet:DWORD, @dwCharacteristics:DWORD
  local @strSignBase:LPBYTE, @dwNumberOfSections:DWORD
  local @dwPointerToRawData:DWORD, @dwVirtualSize:DWORD
  local	@stSign:SSoftSign
  local	@stSoftName:SString
  local	@stAuthor:SString
  local	@stEmail:SString
  local @dwSignLength:DWORD
  local @strBuf[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  
  .if (g_strBase == NULL)
     invoke MessageBox, _hWnd, offset strSignBaseErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_OnBtnSoftSign
  .endif
  
  .if ((g_lpBlkTbl == NULL) || (g_lpFilHdr == NULL))
     invoke MessageBox, _hWnd, offset strSBlkTblErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_OnBtnSoftSign
  .endif
  
  invoke RtlZeroMemory, addr @stSign, sizeof SSoftSign
  invoke RtlZeroMemory, addr @stSoftName, sizeof SString
  invoke RtlZeroMemory, addr @stAuthor, sizeof SString
  invoke RtlZeroMemory, addr @stEmail, sizeof SString
  
  ;;Version1:
  invoke RtlZeroMemory, addr @strBuf, sizeof @strBuf
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER1
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @strBuf, addr @strBuf
  xor eax, eax
  invoke StrToInt, addr @strBuf
  mov @stSign.wVersion1, ax
  
  ;;Version2:
  invoke RtlZeroMemory, addr @strBuf, sizeof @strBuf
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER2
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @strBuf, addr @strBuf
  xor eax, eax
  invoke StrToInt, addr @strBuf
  mov @stSign.bVersion2, al
  
  ;;Version3:
  invoke RtlZeroMemory, addr @strBuf, sizeof @strBuf
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_VER3
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @strBuf, addr @strBuf
  xor eax, eax
  invoke StrToInt, addr @strBuf
  mov @stSign.bVersion3, al
  
  ;;SoftName:
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_SOFT_NAME
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @stSoftName.strBuffer, addr @stSoftName.strBuffer
  mov @stSoftName.bLength, al
  
  ;;Author:
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_AUTHOR
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @stAuthor.strBuffer, addr @stAuthor.strBuffer
  mov @stAuthor.bLength, al
  
  ;;Email:
  xor eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_SIGN_EMAIL
  xor ebx, ebx
  mov ebx, eax
  invoke SendMessage, ebx, WM_GETTEXT, sizeof @stEmail.strBuffer, addr @stEmail.strBuffer
  mov @stEmail.bLength, al
  
  ;;计算签名的总长度@dwSignLength:
  xor eax, eax
  mov al, sizeof SSoftSign           ;;签名结构体本身的长度
  add al, sizeof @stSoftName.bLength
  add al, @stSoftName.bLength        ;;SoftName结构的总长度
  add al, sizeof @stAuthor.bLength
  add al, @stAuthor.bLength          ;;Author结构的总长度
  add al, sizeof @stEmail.bLength
  add al, @stEmail.bLength           ;;EMail结构的总长度
  add al, SKIP_LENGTH                ;;距离代码段尾部SKIP_LENGTH个字节的位置处开始存放签名信息;
  mov @dwSignLength, eax
  
  ;;根据签名的总长度,查找可执行的代码段,并返回代码段的起始地址(FOA:PointerToRawData);
  ;;Number of Sections
  xor esi, esi
  mov esi, g_lpFilHdr    ; esi ---> IMAGE_FILE_HEADER
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_FILE_HEADER.NumberOfSections]
  mov @dwNumberOfSections, eax  ;Number of Sections
  
  ;;Base of Section Table
  xor esi, esi
  mov esi, g_lpBlkTbl    ;esi ---> IMAGE_SECTION_HEADER; Base Address of Section Table
  
  xor ecx, ecx           ;ecx = 0
  .while ecx < @dwNumberOfSections
     ;;Characteristics
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.Characteristics]
     mov @dwCharacteristics, eax
     
     ;;SizeOfRawData
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.SizeOfRawData]
     
     ;;lpSection->SizeOfRawData - lpSection->Misc.VirtualSize
     sub eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.Misc.VirtualSize]
     
     ;;该节具有可读(R)、可执行(E)、包含代码(C)的属性,则该节就是代码段(.text;CODE);如果该节后面的剩余空间长度大于签名信息总长度,则该节适合存放签名信息;
     .if ((@dwCharacteristics & IMAGE_SCN_MEM_READ) && (@dwCharacteristics & IMAGE_SCN_MEM_EXECUTE) && (@dwCharacteristics & IMAGE_SCN_CNT_CODE) && (eax > @dwSignLength))
        .break
     .endif
     
     ;Next
     inc ecx ;next index
     add esi, sizeof IMAGE_SECTION_HEADER ;next Section
  .endw
  
  .if (ecx == @dwNumberOfSections)
     invoke MessageBox, _hWnd, offset strSignTooLong, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_OnBtnSoftSign
  .endif
  
  .if (esi == NULL)
     invoke MessageBox, _hWnd, offset strSignSectErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_OnBtnSoftSign
  .endif
  
  ;;Enable the sign control
  invoke _EnableSignControl, TRUE
  
  ;;找到符合条件的代码段之后,取得该段在磁盘文件中的起始地址;
  ;;esi ---> IMAGE_SECTION_HEADER
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.PointerToRawData]
  mov @dwPointerToRawData, eax
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_SECTION_HEADER.Misc.VirtualSize]
  mov @dwVirtualSize, eax
  
  xor ebx, ebx
  mov ebx, g_strBase
  add ebx, @dwPointerToRawData
  add ebx, @dwVirtualSize
  add ebx, SKIP_LENGTH
  mov @strSignBase, ebx ;;strFileBase + lpSection->PointerToRawData + lpSection->Misc.VirtualSize + SKIP_LENGTH
  mov esi, ebx          ;;此时,ebx/esi ---> SSoftSign
  
  ;;写入签名信息;
  ;;Version;
  ;lpSign = (struct SSoftSign*)pos  ;;ebx/pos ---> SSoftSign
  xor eax, eax
  mov eax, @dwSignLength
  sub eax, SKIP_LENGTH
  mov BYTE PTR [ebx + SSoftSign.bLength], al   ;;lpSign->wLength = (WORD)(dwSignLength - SKIP_LENGTH);
  
  xor ax, ax
  mov ax, @stSign.wVersion1
  mov WORD PTR [ebx + SSoftSign.wVersion1], ax ;;lpSign->wVersion1 = stSign.wVersion1
  
  xor ax, ax
  mov al, @stSign.bVersion2
  mov BYTE PTR [ebx + SSoftSign.bVersion2], al ;;lpSign->wVersion2 = stSign.wVersion2
  
  xor ax, ax
  mov al, @stSign.bVersion3
  mov BYTE PTR [ebx + SSoftSign.bVersion3], al ;;lpSign->wVersion3 = stSign.wVersion3
  
  ;;skip SSoftSign, goto SoftName
  add ebx, sizeof SSoftSign  ;;pos += sizeof(struct SSoftSign),此时,pos/ebx ---> SoftName:SString
  
  ;;;;;;SoftName: pos/ebx ---> SoftName:SString
  ;lpStr = (struct SString*)pos;
  xor eax, eax
  mov al, @stSoftName.bLength
  mov BYTE PTR [ebx + SString.bLength], al  ;;lpStr->dwLength = stSoftName.bLength
  mov edx, ebx
  add edx, SString.strBuffer
  lea edi, @stSoftName
  add edi, SString.strBuffer
  xor eax, eax
  mov al, @stSoftName.bLength
  invoke CopyMemory, edx, edi, eax
  ;invoke crt_memcpy, edx, edi, @stSoftName.bLength
  
  ;;xor edx, edx
  ;;mov edx, ebx ;;edx = pos
  ;;sub edx, g_strBase
  ;;sub edx, @dwPointerToRawData
  ;;mov DWORD PTR [esi + SSoftSign.dwSoftName], edx
  
  ;;skip SoftName, goto Author
  add ebx, sizeof @stSoftName.bLength
  xor eax, eax
  mov al, @stSoftName.bLength
  add ebx, eax  ;;此时,pos/ebx ---> Author:SString
  
  ;;;;;;Author:
  xor eax, eax
  mov al, @stAuthor.bLength
  mov BYTE PTR [ebx + SString.bLength], al  ;;lpStr->dwLength = stAuthor.dwLength
  mov edx, ebx
  add edx, SString.strBuffer
  lea edi, @stAuthor
  add edi, SString.strBuffer
  xor eax, eax
  mov al, @stAuthor.bLength
  invoke CopyMemory, edx, edi, eax
  ;invoke crt_memcpy, edx, edi, @stAuthor.dwLength
  
  ;;xor edx, edx
  ;;mov edx, ebx ;;edx = pos
  ;;sub edx, g_strBase
  ;;sub edx, @dwPointerToRawData
  ;;mov DWORD PTR [esi + SSoftSign.dwAuthor], edx
  
  ;;skip Author, goto Email
  add ebx, sizeof @stAuthor.bLength
  xor eax, eax
  mov al, @stAuthor.bLength
  add ebx, eax  ;;此时,pos/ebx ---> Email:SString
  
  ;;;;;;Email:
  xor eax, eax
  mov al, @stEmail.bLength
  mov BYTE PTR [ebx + SString.bLength], al  ;;lpStr->dwLength = stEmail.dwLength
  mov edx, ebx
  add edx, SString.strBuffer
  lea edi, @stEmail
  add edi, SString.strBuffer
  xor eax, eax
  mov al, @stEmail.bLength
  invoke CopyMemory, edx, edi, eax
  ;invoke crt_memcpy, edx, edi, @stEmail.dwLength
  
  ;;xor edx, edx
  ;;mov edx, ebx ;;edx = pos
  ;;sub edx, g_strBase
  ;;sub edx, @dwPointerToRawData
  ;;mov DWORD PTR [esi + SSoftSign.dwEmail], edx
  
  ;;skip Email, goto END
  add ebx, sizeof @stEmail.bLength
  xor eax, eax
  mov al, @stEmail.bLength
  add ebx, eax  ;;此时,pos/ebx ---> End
  
  ;;Encrpty Sign
  xor ebx, ebx
  mov ebx, @strSignBase
  add ebx, sizeof SSoftSign.bLength
  xor ecx, ecx
  mov cl, BYTE PTR [esi + SSoftSign.bLength]
  sub ecx, sizeof SSoftSign.bLength
  invoke PE_Encrpty, ebx, ecx, KEY_ENCRPTY
  
  ;;Disable the sign control
  invoke _EnableSignControl, FALSE
  
  ;;通知第1个页面更新版权信息;
  xor esi, esi
  mov esi, offset g_aTabPages
  xor eax, eax
  mov eax, HWND PTR [esi + SPePage.hTabWnd]
  .if eax
     invoke PostMessage, eax, UDM_CR_UPDATE, 0, 0
  .endif
  
  invoke MessageBox, _hWnd, offset strSignOK, offset strCapInf, MSG_BTN_STYLE_INF
  mov @dwRet, TRUE
  
  RET_OnBtnSoftSign:
  popad
  mov eax, @dwRet
  ret
_OnBtnSoftSign endp

_OnCommand proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, TRUE
  
  pushad
  xor eax, eax
  mov eax, __wParam
  and eax, 0000FFFFH
  .if ax == IDC_CHECK_ADDRESS_CONVERT
     invoke _OnCheckAddressConvert
  .elseif ax == IDC_BTN_ADDRESS_CONVERT
     invoke _OnBtnAddressConvert
  .elseif ax == IDC_BTN_SEARCH_IMPORT
     invoke _OnBtnSearchImport
  .elseif ax == IDC_BTN_SEARCH_EXPORT
     invoke _OnBtnSearchExport
  .elseif ax == IDC_BTN_SOFT_SIGN
     invoke _OnBtnSoftSign
  .else
     mov eax, FALSE
  .endif
  popad
  
  mov eax, @dwResult
  ret
_OnCommand endp

;;Window Procedure
UsrOprProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     invoke GetDlgItem, _hWnd, IDC_CHECK_ADDRESS_CONVERT
     invoke SendMessage, eax, BM_SETCHECK, BST_UNCHECKED, 0
     invoke _UpdateCheckBox
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_FILLFORM
     invoke _OnFillForm, __wParam, __lParam
     mov @dwResult, TRUE
  .elseif __uMsg == WM_COMMAND
     invoke _OnCommand, __wParam, __lParam
     mov @dwResult, TRUE
  .else
     mov @dwResult, FALSE
  .endif
  popad
  mov eax, @dwResult
  ret
UsrOprProc endp

END