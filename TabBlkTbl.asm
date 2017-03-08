;;TabBlkTbl.asm: Implementation File
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

CNT_LIST_COLS = 7

EXTERN    strCapInf:BYTE, strCapErr:BYTE, strFmtStr:BYTE, strFmt8X:BYTE
EXTERNDEF g_lpBlkTbl:PIMAGE_SECTION_HEADER, g_lpFilHdr:PIMAGE_FILE_HEADER

.const
   ;;;Column Name Text for ListCtrl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strCol0 db 'Name', 0             ;;0
   strCol1 db 'VirtualAddress', 0   ;;1
   strCol2 db 'VirtualSize', 0      ;;2
   strCol3 db 'PointerToRawData', 0 ;;3
   strCol4 db 'SizeOfRawData', 0    ;;4
   strCol5 db 'Characteristics', 0  ;;5
   strCol6 db 'Description', 0      ;;6
   ;;;Message Text for current tab page;;;;;;;;;;;;;;;;;;;;;;;;;;
   strInvalidBlkTbl db '读取的SectionTable无效', 0

.data
   _hWnd      HWND NULL ;;当前页面窗口的句柄;
   _hListCtrl HWND NULL ;;当前页面窗口上面的列表控件句柄;
   _stLvHdr SListHead <offset strCol0, 60,  LVCFMT_CENTER> ;;0 Name
            SListHead <offset strCol1, 96,  LVCFMT_CENTER> ;;1 VirtualAddress
            SListHead <offset strCol2, 80,  LVCFMT_CENTER> ;;2 VirtualSize
            SListHead <offset strCol3, 110, LVCFMT_CENTER> ;;3 PointerToRawData
            SListHead <offset strCol4, 96,  LVCFMT_CENTER> ;;4 SizeOfRawData
            SListHead <offset strCol5, 102, LVCFMT_CENTER> ;;5 Characteristics
            SListHead <offset strCol6, 78,  LVCFMT_LEFT>   ;;6 Description

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  invoke GetDlgItem, _hWnd, IDC_LIST_SECTION_TABLE
  mov _hListCtrl, eax
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD, @iRow:UINT, @dwSize:DWORD, @dwNumberOfSections:DWORD
  local @stRow:LVITEM
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hListCtrl, LVM_DELETEALLITEMS, 0, 0
  
  .if ((g_lpBlkTbl == NULL) || (g_lpFilHdr == NULL))
     invoke MessageBox, _hWnd, offset strInvalidBlkTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  invoke RtlZeroMemory, addr @stRow, sizeof LVITEM
  mov @stRow.imask, LVIF_TEXT
  mov @stRow.cchTextMax, TEMP_BUFF_SIZE
  
  xor esi, esi
  mov esi, g_lpFilHdr    ; esi ---> IMAGE_FILE_HEADER
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_FILE_HEADER.NumberOfSections]
  mov @dwNumberOfSections, eax  ;Number of Sections
  
  xor esi, esi
  mov esi, g_lpBlkTbl    ;esi ---> IMAGE_SECTION_HEADER; Base Address of Section Table
  mov @dwSize, sizeof IMAGE_SECTION_HEADER
  xor ecx, ecx           ;ecx = 0
  .while ecx < @dwNumberOfSections
     push ecx
     ;;STEP1: insert a row
     mov @stRow.iItem, ecx
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hListCtrl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     
     ;;STEP2: set the text for every column
     ;;;;Name:
     mov @stRow.iSubItem, 0
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     mov ebx, esi
     add ebx, IMAGE_SECTION_HEADER.Name1
     invoke wsprintf, addr @strMsg, offset strFmtStr, ebx
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;VirtualAddress:
     mov @stRow.iSubItem, 1
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, [esi + IMAGE_SECTION_HEADER.VirtualAddress]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;VirtualSize:
     mov @stRow.iSubItem, 2
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, [esi + IMAGE_SECTION_HEADER.Misc.VirtualSize]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;PointerToRawData:
     mov @stRow.iSubItem, 3
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, [esi + IMAGE_SECTION_HEADER.PointerToRawData]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;SizeOfRawData:
     mov @stRow.iSubItem, 4
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, [esi + IMAGE_SECTION_HEADER.SizeOfRawData]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;Characteristics:
     mov @stRow.iSubItem, 5
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, [esi + IMAGE_SECTION_HEADER.Characteristics]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;Description
     mov @stRow.iSubItem, 6
     invoke PE_GetSectionProperty, addr @strMsg, sizeof @strMsg, [esi + IMAGE_SECTION_HEADER.Characteristics]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hListCtrl, LVM_SETITEM, @iRow, addr @stRow
     pop ecx
     
     ;Next
     inc ecx          ;next index
     add esi, @dwSize ;next Section
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
BlkTblProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
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
BlkTblProc endp

END