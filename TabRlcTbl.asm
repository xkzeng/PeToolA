;;TabRlcTbl.asm: Implementation File
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

CNT_LIST_COLS = 5

EXTERN    strCapInf:BYTE, strCapErr:BYTE, strFmtNone:BYTE, strFmtStr:BYTE, strFmt4X:BYTE, strFmt8X:BYTE, strFmt8XL:BYTE
EXTERNDEF g_lpRlcTbl:PIMAGE_BASE_RELOCATION, g_lpRlcBlk:PIMAGE_DATA_DIRECTORY, g_lpOptHdr:PIMAGE_OPTIONAL_HEADER, g_strBase:LPBYTE

.const
   ;;;Column Name Text for ListCtrl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strCol0 db 'TypeOffset', 0  ;;0
   strCol1 db 'CodeOffset', 0  ;;1
   strCol2 db 'CodeRVA', 0     ;;2
   strCol3 db 'CodeVA', 0      ;;3
   strCol4 db 'MachineCode', 0 ;;4
   ;;;Message Text for current tab page;;;;;;;;;;;;;;;;;;;;;;;;;;
   strInvalidBase   db '读取重定位表时,文件基址无效', 0
   strInvalidRlcTbl db '读取的重定位表无效', 0

.data
   _hWnd      HWND NULL ;;当前页面窗口的句柄;
   _hListCtrl HWND NULL ;;当前页面窗口上面的列表控件句柄;
   _stLvHdr SListHead <offset strCol0, 80, LVCFMT_CENTER> ;;0 TypeOffset
            SListHead <offset strCol1, 80, LVCFMT_CENTER> ;;1 CodeOffset
            SListHead <offset strCol2, 60, LVCFMT_CENTER> ;;2 CodeRVA
            SListHead <offset strCol3, 96, LVCFMT_CENTER> ;;3 CodeVA
            SListHead <offset strCol4, 80, LVCFMT_CENTER> ;;4 MachineCode

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
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

_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  invoke GetDlgItem, _hWnd, IDC_LIST_BASE_RELOCATION
  mov _hListCtrl, eax
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD, @iRow:UINT, @dwImageBase:DWORD
  local @stRow:LVITEM
  local @strRlcBase:LPBYTE, @strMachineCodes:LPBYTE
  local @awTypeOffsets:LPWORD, @wTypeOffset:WORD, @wCodeOffset:WORD
  local @dwFoa:DWORD, @dwBytesOfRlc:DWORD, @dwNumberOfRlc:DWORD
  local @dwCodeRVA:DWORD, @dwCodeVA:DWORD, @dwMachineCode:DWORD
  local @dwVirtualAddress:DWORD, @dwSizeOfBlock:DWORD
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hListCtrl, LVM_DELETEALLITEMS, 0, 0
  
  .if g_strBase == NULL
     invoke MessageBox, _hWnd, offset strInvalidBase, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  .if ((g_lpRlcTbl == NULL) || (g_lpRlcBlk == NULL) || (g_lpOptHdr == NULL))
     invoke MessageBox, _hWnd, offset strInvalidRlcTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  invoke RtlZeroMemory, addr @stRow, sizeof LVITEM
  mov @stRow.imask, LVIF_TEXT
  mov @stRow.cchTextMax, TEMP_BUFF_SIZE
  
  xor esi, esi
  mov esi, g_lpRlcBlk  ;;; esi ---> origin IMAGE_DATA_DIRECTORY entry, this is not converted by Rva2Foa()
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
  mov esi, g_lpOptHdr  ;;; esi ---> IMAGE_OPTIONAL_HEADER
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_OPTIONAL_HEADER.ImageBase]
  mov @dwImageBase, eax
  
  xor esi, esi
  mov esi, g_lpRlcTbl  ;;; esi ---> IMAGE_BASE_RELOCATION
  mov @strRlcBase, esi
  
  ;;VirtualAddress:
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_BASE_RELOCATION.VirtualAddress]
  mov @dwVirtualAddress, eax
  invoke _Get4Byte, eax, IDC_EDT_RLC_TBL_VIRTUALADDRESS
  
  ;;FOA:
  xor ebx, ebx
  xor eax, eax
  invoke PE_Rva2Foa, @dwVirtualAddress
  mov ebx, eax
  add eax, g_strBase
  mov @strMachineCodes, eax
  invoke _Get4Byte, ebx, IDC_EDT_RLC_TBL_FOA
  
  ;;SizeOfBlock:
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_BASE_RELOCATION.SizeOfBlock]
  mov @dwSizeOfBlock, eax
  invoke _Get4Byte, @dwSizeOfBlock, IDC_EDT_RLC_TBL_SIZEOFBLOCK
  
  ;;;BytesOfReloc:
  xor eax, eax
  mov eax, @dwSizeOfBlock
  sub eax, 8
  mov @dwBytesOfRlc, eax
  invoke _Get4Byte, @dwBytesOfRlc, IDC_EDT_RLC_TBL_BYTESOFRELOC
  
  ;;;NumberOfReloc:
  xor eax, eax
  mov eax, @dwBytesOfRlc
  shr eax, 1
  mov @dwNumberOfRlc, eax
  invoke _Get4Byte, @dwNumberOfRlc, IDC_EDT_RLC_TBL_NUMBEROFRELOC
  
  xor eax, eax
  mov eax, @strRlcBase
  add eax, 8
  mov @awTypeOffsets, eax
  xor edi, edi
  mov edi, eax
  
  xor ecx, ecx
  .while ecx < @dwNumberOfRlc
     push ecx
     
     xor eax, eax
     mov ax, WORD PTR [edi]
     mov @wTypeOffset, ax         ;;ax = @wTypeOffset
     and ax, 0FFFH                ;;@wCodeOffset = @wTypeOffset & 0x0FFF
     mov @wCodeOffset, ax         ;;需要进行重定位的数据在其所属块中的偏移地址; eax = @wCodeOffset
     add eax, @dwVirtualAddress   ;;@dwCodeRVA = @wCodeOffset + lpRlcTbl->VirtualAddress
     mov @dwCodeRVA, eax          ;;需要进行重定位的数据在其所属块中的偏移地址的RVA; eax = @dwCodeRVA
     add eax, @dwImageBase        ;;@dwCodeVA = @dwCodeRVA + lpFmtPe->lpOptHdr->ImageBase
     mov @dwCodeVA, eax           ;;需要进行重定位的数据在其所属块中的偏移地址的VA;
     
     xor ebx, ebx
     mov bx, @wCodeOffset
     add ebx, @strMachineCodes
     xor eax ,eax
     mov eax, DWORD PTR [ebx]     ;;@dwMachineCode = *((LPDWORD)(@strMachineCodes + @wCodeOffset))
     mov @dwMachineCode, eax      ;;直接寻址指令中,需要进行重定位的地址数据(存在于指令码中);
     
     ;;STEP1: insert a row
     mov @stRow.iItem, ecx
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hListCtrl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     
     ;;STEP2: set the text for every column
     ;;;;TypeOffset:
     mov @stRow.iSubItem, 0
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     xor eax, eax
     mov ax, @wTypeOffset
     invoke wsprintf, addr @strMsg, offset strFmt4X, eax
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;CodeOffset:
     mov @stRow.iSubItem, 1
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     xor eax, eax
     mov ax, @wCodeOffset
     invoke wsprintf, addr @strMsg, offset strFmt4X, eax
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;CodeRVA:
     mov @stRow.iSubItem, 2
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, @dwCodeRVA
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;CodeVA:
     mov @stRow.iSubItem, 3
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, @dwCodeVA
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;MachineCode:
     mov @stRow.iSubItem, 4
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, @dwMachineCode
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     pop ecx
     
     ;Next
     inc ecx   ;;;next Index
     add edi, sizeof WORD ;;;next TypeOffset
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
RlcTblProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
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
RlcTblProc endp

END