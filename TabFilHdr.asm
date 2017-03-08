;;TabFilHdr.asm: Implementation File
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
include Define.inc
include WndRes.inc
include PeFile.inc

EXTERN strCapInf:BYTE, strCapErr:BYTE
EXTERN strFmt8XL:BYTE, strFmtDateTime:BYTE
EXTERN g_lpNtHdr:PIMAGE_NT_HEADERS, g_lpFilHdr:PIMAGE_FILE_HEADER

.const
   strInvalidFilHdr db '获取的FileHeader无效', 0
   strFmtSignature  db ' %08X -> %c%c%c%c', 0
   strFmtMachine    db ' %04X -> %s', 0
   strFmtTimeStamp  db ' %08X ->%s', 0
   strFmtOptHdrSize db ' %04X -> %d', 0
   strFmtCharacter  db ' %04X -> %s', 0

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

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD, @dwDateTimeStamp:DWORD
  local @tmp[4]:DWORD
  local @strTime[32]:CHAR
  local @strMsg[TEMP_BUFF_SIZE+2]:TCHAR
  mov @dwRet, TRUE
  
  .if ((g_lpNtHdr == NULL) || (g_lpFilHdr == NULL))
     invoke MessageBox, _hWnd, offset strInvalidFilHdr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  pushad
  ;;Signature
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke RtlZeroMemory, addr @tmp, sizeof @tmp
  xor edi, edi
  lea edi, @tmp
  xor esi, esi
  mov esi, g_lpNtHdr ;esi ---> IMAGE_NT_HEADERS
  xor eax, eax
  mov al, BYTE PTR [esi + IMAGE_NT_HEADERS.Signature + 0]
  ;mov DWORD PTR [edi + 0], eax
  mov @tmp[0], eax
  
  xor eax, eax
  mov al, BYTE PTR [esi + IMAGE_NT_HEADERS.Signature + 1]
  ;mov DWORD PTR [edi + 4], eax
  mov @tmp[4], eax
  
  xor eax, eax
  mov al, BYTE PTR [esi + IMAGE_NT_HEADERS.Signature + 2]
  ;mov DWORD PTR [edi + 8], eax
  mov @tmp[8], eax
  
  xor eax, eax
  mov al, BYTE PTR [esi + IMAGE_NT_HEADERS.Signature + 2]
  ;mov DWORD PTR [edi + 12], eax
  mov @tmp[12], eax
  
  xor eax, eax
  mov eax, [esi + IMAGE_NT_HEADERS.Signature]
  invoke wsprintf, addr @strMsg, offset strFmtSignature, eax, @tmp[0], @tmp[4], @tmp[8], @tmp[12]
  ;lea ebx, @tmp
  ;invoke wsprintf, addr @strMsg, offset strFmtSignature, eax, DWORD PTR[ebx + 0], DWORD PTR[ebx + 4], DWORD PTR[ebx + 8], DWORD PTR[ebx + 12]
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_SIGNATURE
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Machine
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor esi, esi
  mov esi, g_lpFilHdr ;esi ---> IMAGE_FILE_HEADER
  xor ebx, ebx
  mov bx, [esi + IMAGE_FILE_HEADER.Machine]
  xor eax, eax
  invoke PE_GetMachineString, ebx
  invoke wsprintf, addr @strMsg, offset strFmtMachine, ebx, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_MACHINE
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;NumberOfSections
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, [esi + IMAGE_FILE_HEADER.NumberOfSections]
  invoke wsprintf, addr @strMsg, offset strFmt8XL, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_NUMBEROFSECTION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;TimeDateStamp
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke RtlZeroMemory, addr @strTime, sizeof @strTime
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_FILE_HEADER.TimeDateStamp]
  mov @dwDateTimeStamp, eax
  invoke crt_localtime, addr @dwDateTimeStamp  ;;;eax = struct tm*
  invoke crt_strftime, addr @strTime, sizeof @strTime, offset strFmtDateTime, eax
  invoke wsprintf, addr @strMsg, offset strFmtTimeStamp, @dwDateTimeStamp, addr @strTime
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_TIMEDATESTAMP
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;PointerToSymbolTable
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke wsprintf, addr @strMsg, offset strFmt8XL, DWORD PTR [esi + IMAGE_FILE_HEADER.PointerToSymbolTable]
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_POINTERTOSYMBOLTABLE
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;NumberOfSymbols
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke wsprintf, addr @strMsg, offset strFmt8XL, DWORD PTR [esi + IMAGE_FILE_HEADER.NumberOfSymbols]
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_NUMBEROFSYMBOLS
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;SizeOfOptionalHeader
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, [esi + IMAGE_FILE_HEADER.SizeOfOptionalHeader]
  invoke wsprintf, addr @strMsg, offset strFmtOptHdrSize, eax, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_SIZEOFOPTIONALHEADER
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Characteristics
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, [esi + IMAGE_FILE_HEADER.Characteristics]
  invoke PE_GetFileType, ebx
  invoke wsprintf, addr @strMsg, offset strFmtCharacter, ebx, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_FIL_CHARACTERISTICS
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
FilHdrProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
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
FilHdrProc endp

END