;;TabExpTbl.asm: Implementation File
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

CNT_LIST_COLS = 4

EXTERN strCapInf:BYTE, strCapErr:BYTE, strFmtNone:BYTE, strFmtStr:BYTE, strFmtStrL:BYTE
EXTERN strFmt4X:BYTE, strFmt4XL:BYTE, strFmt8X:BYTE, strFmt8XL:BYTE, strFmtDateTime:BYTE
EXTERNDEF g_lpExpTbl:PIMAGE_EXPORT_DIRECTORY, g_lpExpBlk:PIMAGE_DATA_DIRECTORY, g_strBase:LPBYTE

.const
   ;;;Column Name Text for ListCtrl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strCol0 db 'Ordinal', 0  ;;0
   strCol1 db 'Hint', 0     ;;1
   strCol2 db 'Function', 0 ;;2
   strCol3 db 'Address', 0  ;;3
   ;;;Message Text for current tab page;;;;;;;;;;;;;;;;;;;;;;;;;;
   strInvalidBase   db '读取ExportTable时,文件基址无效', 0
   strInvalidExpTbl db '读取的ExportTable无效', 0

.data
   _hWnd      HWND NULL ;;当前页面窗口的句柄;
   _hListCtrl HWND NULL ;;当前页面窗口上面的列表控件句柄;
   _stLvHdr SListHead <offset strCol0, 60, LVCFMT_CENTER> ;;0 Ordinal
            SListHead <offset strCol1, 60, LVCFMT_CENTER> ;;1 Hint
            SListHead <offset strCol2, 96, LVCFMT_LEFT>   ;;2 Function
            SListHead <offset strCol3, 60, LVCFMT_CENTER> ;;3 Address

.code
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  invoke GetDlgItem, _hWnd, IDC_LIST_EXPORT_TABLE
  mov _hListCtrl, eax
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD, @iRow:UINT, @dwDateTimeStamp:DWORD
  local @stRow:LVITEM
  local @adwRvaAddrs:LPDWORD
  local @adwRvaNames:LPDWORD
  local @awOrdinals:LPWORD
  local @i:WORD, @wOrdinal:WORD
  local @strName:LPCSTR, @dwAddr:DWORD
  local @dwNumberOfNames:DWORD, @dwBase:DWORD
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hListCtrl, LVM_DELETEALLITEMS, 0, 0
  
  .if g_strBase == NULL
     invoke MessageBox, _hWnd, offset strInvalidBase, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  .if ((g_lpExpTbl == NULL) || (g_lpExpBlk == NULL))
     invoke MessageBox, _hWnd, offset strInvalidExpTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  invoke RtlZeroMemory, addr @stRow, sizeof LVITEM
  mov @stRow.imask, LVIF_TEXT
  mov @stRow.cchTextMax, TEMP_BUFF_SIZE
  
  xor esi, esi
  mov esi, g_lpExpBlk  ;;; esi ---> origin IMAGE_DATA_DIRECTORY entry, this is not converted by Rva2Foa()
  .if DWORD PTR [esi + IMAGE_DATA_DIRECTORY.isize] == 0
     ;;insert a row;
     mov @stRow.iItem, 0
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hListCtrl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     ;;fill the first column;
     mov @stRow.iSubItem, 0
     mov @stRow.pszText, offset strFmtNone
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  xor esi, esi
  mov esi, g_lpExpTbl  ;;; esi ---> IMAGE_EXPORT_DIRECTORY
  
  ;;Characteristics:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.Characteristics], IDC_EDT_EXP_TBL_CHARACTERISTICS
  
  ;;TimeDateStamp:
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.TimeDateStamp]
  mov @dwDateTimeStamp, eax
  invoke _Get4Byte, eax, IDC_EDT_EXP_TBL_TIMEDATESTAMP
  
  ;;MajorVersion:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_EXPORT_DIRECTORY.MajorVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_EXP_TBL_MAJORVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MinorVersion:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor ebx, ebx
  mov bx, WORD PTR [esi + IMAGE_EXPORT_DIRECTORY.MinorVersion]
  invoke wsprintf, addr @strMsg, offset strFmt4XL, ebx
  invoke GetDlgItem, _hWnd, IDC_EDT_EXP_TBL_MINORVERSION
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;Name:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.nName], IDC_EDT_EXP_TBL_NAME
  
  ;;Base:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.nBase], IDC_EDT_EXP_TBL_BASE
  mov eax, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.nBase]
  mov @dwBase, eax
  
  ;;NumberOfFunctions:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.NumberOfFunctions], IDC_EDT_EXP_TBL_NUMBEROFFUNCTIONS
  
  ;;NumberOfNames:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.NumberOfNames], IDC_EDT_EXP_TBL_NUMBEROFNAMES
  
  ;;AddressOfFunctions:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.AddressOfFunctions], IDC_EDT_EXP_TBL_ADDRESSOFFUNCTIONS
  
  ;;AddressOfNames:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.AddressOfNames], IDC_EDT_EXP_TBL_ADDRESSOFNAMES
  
  ;;AddressOfNameOrdinals:
  invoke _Get4Byte, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals], IDC_EDT_EXP_TBL_ADDRESSOFNAMEORDINALS
  
  ;;DllName:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  xor eax, eax
  invoke PE_Rva2Foa, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.nName]
  add eax, g_strBase
  invoke wsprintf, addr @strMsg, offset strFmtStrL, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_EXP_TBL_DLLNAME
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
  ;;MkTime:
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke crt_localtime, addr @dwDateTimeStamp  ;;;eax = struct tm*
  invoke crt_strftime, addr @strMsg, sizeof @strMsg, offset strFmtDateTime, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_EXP_TBL_MKTIME
  mov ebx, eax
  invoke SendMessage, ebx, WM_SETTEXT, 0, addr @strMsg
  
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
  
  mov @wOrdinal, 0
  mov @dwAddr, 0
  mov @strName, 0
  mov @dwNumberOfNames, 0
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_EXPORT_DIRECTORY.NumberOfNames]
  mov @dwNumberOfNames, eax
  
  xor esi, esi
  mov esi, @adwRvaNames ;;;函数名称表基址;
  xor edi, edi
  mov edi, @awOrdinals  ;;;函数序数表基址;
  
  ;;导出函数列表视图
  xor ecx, ecx
  .while ecx < @dwNumberOfNames
     push ecx
     ;;Name:
     xor eax, eax
     invoke PE_Rva2Foa, DWORD PTR[esi]  ;;;get FOA
     add eax, g_strBase                 ;;;FOA + g_strBase
     mov @strName, eax                  ;;;Name of function
     
     ;;Ordinal:
     xor eax, eax
     mov ax, WORD PTR[edi]              ;;;get Ordinal
     mov @wOrdinal, ax                  ;;;被乘数
     
     ;;Address:
     xor ebx, ebx
     mov ebx, sizeof DWORD              ;;;乘数
     mul ebx                            ;;;edx:eax = eax * ebx = @wOrdinal * sizeof(DWORD)
     add eax, @adwRvaAddrs              ;;;eax = eax + @adwRvaAddrs
     mov ebx, DWORD PTR [eax]           ;;;取出对应位置处的函数地址;
     mov @dwAddr, ebx
     
     ;;STEP1: insert a row
     mov @stRow.iItem, ecx
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hListCtrl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     
     ;;STEP2: set the text for every column
     ;;;;Oridinal:
     mov @stRow.iSubItem, 0
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     xor eax, eax
     mov ax, @wOrdinal
     add eax, @dwBase
     invoke wsprintf, addr @strMsg, offset strFmt4X, eax
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;Hint:
     mov @stRow.iSubItem, 1
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     xor eax, eax
     mov ax, @wOrdinal
     invoke wsprintf, addr @strMsg, offset strFmt4X, eax
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;Function:
     mov @stRow.iSubItem, 2
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmtStr, @strName
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;Address:
     mov @stRow.iSubItem, 3
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, @dwAddr
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     pop ecx
     
     ;Next
     inc ecx               ;;;next Index
     add esi, sizeof DWORD ;;;next Function Name
     add edi, sizeof WORD  ;;;next Ordinal
     ;add esi, sizeof IMAGE_EXPORT_DIRECTORY
  .endw
  
  mov @dwRet, TRUE
  
  ERR_Fill:
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

;;实现应用程序对话框过程;
ExpTblProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     invoke InitListView, _hListCtrl, offset _stLvHdr, CNT_LIST_COLS
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
ExpTblProc endp

END