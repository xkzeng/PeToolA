;;TabImpTbl.asm: Implementation File
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

STIF_DEFAULT     equ 0
STIF_SUPPORT_HEX equ 1

CNT_IMP_TBL_COLS = 7
CNT_IMP_DTL_COLS = 5
ROW_SELECTED_LAST= 0FFFFFFFFH

EXTERN    strCapInf:BYTE, strCapErr:BYTE, strFmtNone:BYTE, strFmtStr:BYTE, strFmt4X:BYTE, strFmt8X:BYTE
EXTERNDEF g_lpImpTbl:PIMAGE_IMPORT_DESCRIPTOR, g_lpImpBlk:PIMAGE_DATA_DIRECTORY, g_strBase:LPBYTE

.const
   ;;;Column Name Text for Import Table ListCtrl;;;;;;;;;;;;;;;;;
   strTblCol0 db 'OriginalFirstThunk', 0 ;;0
   strTblCol1 db 'TimeDateStamp', 0      ;;1
   strTblCol2 db 'ForwarderChain', 0     ;;2
   strTblCol3 db 'NameRVA', 0            ;;3
   strTblCol4 db 'NameFOA', 0            ;;4
   strTblCol5 db 'Name', 0               ;;5
   strTblCol6 db 'FirstThunk', 0         ;;6
   ;;;Column Name Text for Import Table Detail ListCtrl;;;;;;;;;;
   strDtlCol0 db 'RVA', 0                ;;0
   strDtlCol1 db 'FOA', 0                ;;1
   strDtlCol2 db 'IAT', 0                ;;2
   strDtlCol3 db 'Hint', 0               ;;3
   strDtlCol4 db 'Function', 0           ;;4
   ;;;Message Text for current tab page;;;;;;;;;;;;;;;;;;;;;;;;;;
   strInvalidBaseTbl db '读取ImportTable时,文件基址无效', 0
   strInvalidImpTbl  db '读取的ImportTable无效', 0
   strInvalidBaseDtl db '读取ImportTable详情时,文件基址无效', 0
   strInvalidImpDtl  db '读取的ImportTable详情无效', 0
   strByOrdinal      db 'by ordinal', 0

.data
   _hWnd      HWND NULL ;;当前页面窗口的句柄;
   _hLvImpTbl HWND NULL ;;当前页面窗口上面的Import Table列表控件句柄;
   _hLvImpDtl HWND NULL ;;当前页面窗口上面的Import Table详情列表控件句柄;
   _iRowSelectedLast UINT ROW_SELECTED_LAST
   _bImpTblIsEmpty BOOL FALSE
   _stLvHdrImpTbl SListHead <offset strTblCol0, 120, LVCFMT_CENTER> ;;0 OriginalFirstThunk
                  SListHead <offset strTblCol1, 90,  LVCFMT_CENTER> ;;1 TimeDateStamp
                  SListHead <offset strTblCol2, 96,  LVCFMT_CENTER> ;;2 ForwarderChain
                  SListHead <offset strTblCol3, 60,  LVCFMT_CENTER> ;;3 NameRVA
                  SListHead <offset strTblCol4, 60,  LVCFMT_CENTER> ;;4 NameFOA
                  SListHead <offset strTblCol5, 90,  LVCFMT_LEFT>   ;;5 Name
                  SListHead <offset strTblCol6, 75,  LVCFMT_CENTER> ;;6 FirstThunk
   _stLvHdrImpDtl SListHead <offset strDtlCol0, 60,  LVCFMT_CENTER> ;;0 RVA
                  SListHead <offset strDtlCol1, 60,  LVCFMT_CENTER> ;;1 FOA
                  SListHead <offset strDtlCol2, 60,  LVCFMT_CENTER> ;;2 IAT
                  SListHead <offset strDtlCol3, 60,  LVCFMT_CENTER> ;;3 Hint
                  SListHead <offset strDtlCol4, 463, LVCFMT_LEFT>   ;;4 Function

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  invoke GetDlgItem, _hWnd, IDC_LIST_IMPORT_TABLE
  mov _hLvImpTbl, eax
  invoke GetDlgItem, _hWnd, IDC_LIST_IMPORT_DETAIL
  mov _hLvImpDtl, eax
  mov _iRowSelectedLast, ROW_SELECTED_LAST
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD
  local @stRow:LVITEM, @iRow:UINT
  local @strName:LPCSTR, @dwName:DWORD, @dwFoa:DWORD
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hLvImpTbl, LVM_DELETEALLITEMS, 0, 0
  invoke SendMessage, _hLvImpDtl, LVM_DELETEALLITEMS, 0, 0
  
  .if g_strBase == NULL
     invoke MessageBox, _hWnd, offset strInvalidBaseTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  .if ((g_lpImpTbl == NULL) || (g_lpImpBlk == NULL))
     invoke MessageBox, _hWnd, offset strInvalidImpTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  invoke RtlZeroMemory, addr @stRow, sizeof LVITEM
  mov @stRow.imask, LVIF_TEXT
  mov @stRow.cchTextMax, TEMP_BUFF_SIZE
  
  xor esi, esi
  mov esi, g_lpImpBlk  ;;; esi ---> origin IMAGE_DATA_DIRECTORY entry, this is not converted by Rva2Foa()
  .if DWORD PTR [esi + IMAGE_DATA_DIRECTORY.isize] == 0
     ;;insert a row;
     mov @stRow.iItem, 0
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hLvImpTbl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     ;;fill the first column;
     mov @stRow.iSubItem, 0
     mov @stRow.pszText, offset strFmtNone
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     mov _bImpTblIsEmpty, TRUE
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  xor esi, esi
  mov esi, g_lpImpTbl  ;;; esi ---> IMAGE_IMPORT_DESCRIPTOR
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.Name1] ;;;first IID's name
  mov @dwName, eax
  
  xor ecx, ecx
  .repeat
     push ecx
     
     ;;STEP1: insert a row
     mov @stRow.iItem, ecx
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hLvImpTbl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     
     ;;STEP2: set the text for every column
     ;;;;OriginalFirstThunk:
     mov @stRow.iSubItem, 0
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.OriginalFirstThunk]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;TimeDateStamp:
     mov @stRow.iSubItem, 1
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.TimeDateStamp]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;ForwarderChain:
     mov @stRow.iSubItem, 2
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.ForwarderChain]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;NameRVA:
     mov @stRow.iSubItem, 3
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, @dwName
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;NameFOA:
     mov @stRow.iSubItem, 4
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     xor eax, eax
     invoke PE_Rva2Foa, @dwName
     mov @dwFoa, eax
     invoke wsprintf, addr @strMsg, offset strFmt8X, eax
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;DllName String:
     mov @stRow.iSubItem, 5
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     mov eax, @dwFoa
     add eax, g_strBase
     invoke wsprintf, addr @strMsg, offset strFmtStr, eax
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     ;;;;FirstThunk:
     mov @stRow.iSubItem, 6
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.FirstThunk]
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpTbl, LVM_SETITEM, @iRow, addr @stRow
     
     pop ecx
     
     ;Next
     inc ecx                                                  ;;;next Index
     add esi, sizeof IMAGE_IMPORT_DESCRIPTOR                  ;;;next IID
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_IMPORT_DESCRIPTOR.Name1] ;;;next IID's name
     mov @dwName, eax
  .until (@dwName == NULL)
  
  mov _bImpTblIsEmpty, FALSE
  mov @dwRet, TRUE
  
  ERR_Fill:
  popad
  mov eax, @dwRet
  ret
_Fill endp

_FillDetail proc NEAR32 STDCALL PRIVATE __lpLv:DWORD ;LPNMLISTVIEW
  local @dwRet:DWORD
  local @stRow:LVITEM, @stRowSel:LVITEM, @iRow:UINT, @iRowSel:DWORD
  local @dwaINT:LPDWORD, @dwaIAT:LPDWORD
  local @dwThkINT:DWORD, @dwThkIAT:DWORD
  local @i:WORD, @wOrdinal:WORD
  local @strName:LPCSTR, @dwName:DWORD, @dwRva:DWORD, @dwFoa:DWORD
  local @strMsg[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hLvImpDtl, LVM_DELETEALLITEMS, 0, 0
  
  .if g_strBase == NULL
     invoke MessageBox, _hWnd, offset strInvalidBaseDtl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_FillDetail
  .endif
  
  .if ((g_lpImpTbl == NULL) || (g_lpImpBlk == NULL))
     invoke MessageBox, _hWnd, offset strInvalidImpDtl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_FillDetail
  .endif
  
  ;;;get the index of row selected
  xor ebx, ebx
  mov ebx, __lpLv
  mov eax, DWORD PTR [ebx + NM_LISTVIEW.iItem]
  mov @iRowSel, eax
  
  ;;读取导入表视图第0列OriginalFirstThunk的值,并定位Original First Thunk Table,用于填充Import Name Table(INT)列表视图;
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  invoke RtlZeroMemory, addr @stRowSel, sizeof LVITEM
  mov @stRowSel.iSubItem, 0
  lea eax, @strMsg
  mov @stRowSel.pszText, eax
  mov @stRowSel.cchTextMax, sizeof @strMsg
  invoke SendMessage, _hLvImpTbl, LVM_GETITEMTEXT, @iRowSel, addr @stRowSel
  mov @dwRva, 0
  ;invoke StrToIntEx, addr @strMsg, STIF_SUPPORT_HEX, addr @dwRva
  invoke crt_sscanf, addr @strMsg, offset strFmt8X, addr @dwRva
  xor eax, eax
  invoke PE_Rva2Foa, @dwRva ;;;RVA To FOA(eax)
  add eax, g_strBase
  mov @dwaINT, eax          ;;;Base of INT
  
  ;;读取导入表视图第6列FirstThunk的值,并定位First Thunk Table,用于填充Import Address Table(IAT)列表视图;
  invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
  mov @stRowSel.iSubItem, 6
  invoke SendMessage, _hLvImpTbl, LVM_GETITEMTEXT, @iRowSel, addr @stRowSel
  mov @dwRva, 0
  ;invoke StrToIntEx, addr @strMsg, STIF_SUPPORT_HEX, addr @dwRva
  invoke crt_sscanf, addr @strMsg, offset strFmt8X, addr @dwRva
  xor eax, eax
  invoke PE_Rva2Foa, @dwRva ;;;RVA To FOA(eax)
  add eax, g_strBase
  mov @dwaIAT, eax          ;;;Base of IAT
  
  ;;Iterate the Import Name Table(INT) and Import Address Table(IAT),then,Fill the Import Name Table List View and Import Address Table List View;
  invoke RtlZeroMemory, addr @stRow, sizeof LVITEM
  mov @stRow.imask, LVIF_TEXT
  mov @stRow.cchTextMax, TEMP_BUFF_SIZE
  
  xor esi, esi
  mov esi, @dwaINT ;;;esi ---> Base of INT
  xor edi, edi
  mov edi, @dwaIAT ;;;edi ---> Base of IAT
  
  mov eax, DWORD PTR [esi] ;;;the first IMAGE_THUNK_DATA for INT
  mov @dwThkINT, eax
  mov eax, DWORD PTR [edi] ;;;the first IMAGE_THUNK_DATA for IAT
  mov @dwThkIAT, eax
  
  xor ecx, ecx
  .repeat
     push ecx
     push esi
     push edi
     
     ;;STEP1: insert a row
     mov @stRow.iItem, ecx
     mov @stRow.iSubItem, 0
     invoke SendMessage, _hLvImpDtl, LVM_INSERTITEM, 0, addr @stRow
     mov @iRow, eax
     
     ;;STEP2: set the text for every column
     ;;;;RVA:
     mov @stRow.iSubItem, 0
     invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
     invoke wsprintf, addr @strMsg, offset strFmt8X, @dwThkINT
     lea eax, @strMsg
     mov @stRow.pszText, eax
     invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
     
     .if (@dwThkINT & IMAGE_ORDINAL_FLAG32) ;;Import By Ordinal
        xor eax, eax
        mov eax, @dwThkINT  ;and IMAGE_ORDINAL32
        and eax, IMAGE_ORDINAL32
        mov @wOrdinal, ax
        
        ;;;;FOA:
        mov @stRow.iSubItem, 1
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        invoke wsprintf, addr @strMsg, offset strFmt8X, 0
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
        
        ;;;;IAT:
        mov @stRow.iSubItem, 2
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        invoke wsprintf, addr @strMsg, offset strFmt8X, @dwThkIAT
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
        
        ;;;;Hint:
        mov @stRow.iSubItem, 3
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        xor eax, eax
        mov ax, @wOrdinal
        invoke wsprintf, addr @strMsg, offset strFmt4X, eax
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
        
        ;;;;Function:
        mov @stRow.iSubItem, 4
        mov @stRow.pszText, offset strByOrdinal
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
     .else                                  ;;Import By Name
        ;;;;FOA:
        mov @stRow.iSubItem, 1
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        xor eax, eax
        invoke PE_Rva2Foa, @dwThkINT
        mov @dwFoa, eax
        invoke wsprintf, addr @strMsg, offset strFmt8X, eax
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
        
        ;;;;IAT:
        mov @stRow.iSubItem, 2
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        invoke wsprintf, addr @strMsg, offset strFmt8X, @dwThkIAT
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
        
        ;;;;Hint:
        mov @stRow.iSubItem, 3
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        xor ebx, ebx
        mov ebx, @dwFoa
        add ebx, g_strBase
        mov @strName, ebx
        xor eax, eax
        mov ax, WORD PTR [ebx + IMAGE_IMPORT_BY_NAME.Hint]
        invoke wsprintf, addr @strMsg, offset strFmt4X, eax
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
        
        ;;;;Function:
        mov @stRow.iSubItem, 4
        invoke RtlZeroMemory, addr @strMsg, sizeof @strMsg
        add @strName, sizeof WORD
        invoke wsprintf, addr @strMsg, offset strFmtStr, @strName
        lea eax, @strMsg
        mov @stRow.pszText, eax
        invoke SendMessage, _hLvImpDtl, LVM_SETITEM, @iRow, addr @stRow
     .endif
     
     pop edi
     pop esi
     pop ecx
     
     ;Next
     inc ecx                  ;;;next Index
     add esi, sizeof DWORD    ;;;next IMAGE_THUNK_DATA for INT
     add edi, sizeof DWORD    ;;;next IMAGE_THUNK_DATA for IAT
     mov eax, DWORD PTR [esi] ;;;read next IMAGE_THUNK_DATA for INT
     mov @dwThkINT, eax
     mov eax, DWORD PTR [edi] ;;;read next IMAGE_THUNK_DATA for IAT
     mov @dwThkIAT, eax
  .until ((@dwThkINT == NULL) || (@dwThkIAT == NULL))
  
  mov @dwRet, TRUE
  
  ERR_FillDetail:
  popad
  mov eax, @dwRet
  ret
_FillDetail endp

_OnItemchangedListImportTable proc NEAR32 STDCALL PRIVATE __lpNMHDR:LPNMHDR
  .if __lpNMHDR == NULL
     mov eax, FALSE
     ret
  .endif
  
  .if _bImpTblIsEmpty == TRUE
     mov eax, FALSE
     ret
  .endif
  
	pushad
	xor esi, esi
	mov esi, __lpNMHDR
  
	mov eax, DWORD PTR [esi + NMLISTVIEW.uChanged]
  .if (eax & LVIF_STATE) ;;状态发生改变;
     mov eax, DWORD PTR [esi + NMLISTVIEW.uNewState]
     .if ((eax & LVIS_FOCUSED) && (eax & LVIS_SELECTED))
        xor eax, eax
        mov eax, DWORD PTR [esi + NMLISTVIEW.iItem]
        .if (eax != -1); && (eax != _iRowSelectedLast))
           invoke _FillDetail, __lpNMHDR
           mov eax, DWORD PTR [esi + NMLISTVIEW.iItem]
           mov _iRowSelectedLast, eax
        .endif
     .endif
  .endif
  popad
  mov eax, TRUE
  ret
_OnItemchangedListImportTable endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Message Handlers
_OnFillForm proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  pushad
  mov _iRowSelectedLast, ROW_SELECTED_LAST
  invoke _Fill, NULL
  popad
  mov eax, TRUE
  ret
_OnFillForm endp

_OnNotify proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  .if __lParam == 0
     ret
  .endif
  
  pushad
  xor esi, esi
  mov esi, __lParam
  
  .if DWORD PTR [esi + NMHDR.code] == LVN_ITEMCHANGED
     invoke _OnItemchangedListImportTable, __lParam
  .endif
  
  popad
  mov eax, TRUE
  ret
_OnNotify endp

;;实现应用程序对话框过程;
ImpTblProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     invoke InitListView, _hLvImpTbl, offset _stLvHdrImpTbl, CNT_IMP_TBL_COLS
     invoke InitListView, _hLvImpDtl, offset _stLvHdrImpDtl, CNT_IMP_DTL_COLS
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_FILLFORM
     invoke _OnFillForm, __wParam, __lParam
     mov @dwResult, TRUE
  .elseif __uMsg == WM_NOTIFY
     .if (__wParam == IDC_LIST_IMPORT_TABLE)
        invoke _OnNotify, __wParam, __lParam
     .endif
     mov @dwResult, TRUE
  .else
     mov @dwResult, FALSE
  .endif
  popad
  mov eax, @dwResult
  ret
ImpTblProc endp

END