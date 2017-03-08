;;TabDosHdr.asm: Implementation file
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
EXTERN strFmtStrL:BYTE, strFmt4XL:BYTE, strFmt8XL:BYTE
EXTERNDEF g_lpDosHdr:PIMAGE_DOS_HEADER

.const
  strInvalidDosHdr db '读取的DosHeader无效', 0
  strFmtMagic      db ' %04X -> %c%c', 0
  strFmtRes        db ' %04X %04X %04X %04X', 0
  strFmtRes2       db ' %04X %04X %04X %04X %04X %04X %04X %04X %04X %04X', 0

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
  local @dwRet:DWORD
  local @w[10]:DWORD
  local @strMsg[TEMP_BUFF_SIZE+20]:CHAR
  mov @dwRet, TRUE
  
  .if g_lpDosHdr == NULL
      invoke MessageBox, _hWnd, offset strInvalidDosHdr, offset strCapErr, MSG_BTN_STYLE_ERR
      mov @dwRet, FALSE
      jmp ERR__Fill
  .endif
  
  pushad
  xor esi, esi
  mov esi, g_lpDosHdr
  
  ;;e_magic
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_DOS_HEADER.e_magic]
  mov edi, eax
  xor ebx, ebx
  mov bl, al
  xor edx, edx
  mov dl, ah
  invoke wsprintf, addr @strMsg, offset strFmtMagic, edi, ebx, edx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_MAGIC
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_cblp
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_cblp]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_CBLP
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_cp
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_cp]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_CP
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_crlc
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_crlc]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_CRLC
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_cparhdr
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_cparhdr]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_CPARHDR
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_minalloc
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_minalloc]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_MINALLOC
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_maxalloc
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_maxalloc]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_MAXALLOC
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_ss
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_ss]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_SS
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_sp
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_sp]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_SP
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_csum
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_csum]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_CSUM
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_ip
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_ip]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_IP
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_cs
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_cs]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_CS
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_lfarlc
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_lfarlc]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_LFARLC
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_ovno
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_ovno]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_OVNO
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_res
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_DOS_HEADER.e_res + 0] ;e_res[0]
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_res + 2] ;e_res[1]
  xor ecx, ecx
  mov cx, WORD PTR [esi + IMAGE_DOS_HEADER.e_res + 4] ;e_res[2]
  xor edx, edx
  mov dx, WORD PTR [esi + IMAGE_DOS_HEADER.e_res + 6] ;e_res[3]
  invoke wsprintf, addr @strMsg, offset strFmtRes, eax, ebx, ecx, edx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_RES
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_oemid
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_oemid]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_OEMID
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_oeminfo
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_DOS_HEADER.e_oeminfo]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_OEMINFO
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_res2
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke RtlZeroMemory, addr @w, sizeof @w
  xor edi, edi
  lea edi, @w
  xor ebx, ebx
  xor ecx, ecx
  mov ecx, 10
  RES2_LOOP:
    xor eax, eax
    mov ax, WORD PTR [esi + IMAGE_DOS_HEADER.e_res2 + ebx]
    ;mov [edi + ebx], eax
    mov @w[ebx], eax
    inc ebx
    LOOPZ RES2_LOOP
  invoke wsprintf, addr @strMsg, offset strFmtRes2, @w[0], @w[4], @w[8], @w[12], @w[16], @w[20], @w[24], @w[28], @w[32], @w[36]
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_RES2
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;e_lfanew
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov ebx, [esi + IMAGE_DOS_HEADER.e_lfanew]
  invoke wsprintf, addr @strMsg, offset strFmt8XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_DOS_LFANEW
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  popad
  mov @dwRet, TRUE
  
  ERR__Fill:
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
DosHdrProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
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
DosHdrProc endp

END