;;TabResTbl.asm: Implementation File
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

EXTERN strCapInf:BYTE, strCapErr:BYTE, strFmtNone:BYTE, strFmtStr:BYTE, strFmtStrL:BYTE
EXTERN strFmt4X:BYTE, strFmt4XL:BYTE, strFmt8X:BYTE, strFmt8XL:BYTE, strFmt1D:BYTE
EXTERNDEF g_lpResTbl:PIMAGE_RESOURCE_DIRECTORY, g_lpResBlk:PIMAGE_DATA_DIRECTORY, g_strBase:LPBYTE

BYTES_OF_PER_LINE equ 60
EXTRA_BYTES       equ 128
NODE_PARAM_VALUE  equ 0FFFFFFF0H
NODE_PARAM_EMPTY  equ 000000000H
TREE_NODE_MASK    equ (TVIF_HANDLE or TVIF_TEXT or TVIF_STATE or TVIF_PARAM or TVIF_CHILDREN)

.const
   ;;;Resource Type Name;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strResCURSOR  db 'Cursor', 0
   strResBITMAP  db 'BitMap', 0
   strResICON    db 'Icon', 0
   strResMENU    db 'Menu', 0
   strResDIALOG  db 'Dialog', 0
   strResSTRING  db 'String', 0
   strResFONTDIR db 'FontDir', 0
   strResFONT    db 'Font', 0
   strResACCE    db 'Accelerator', 0
   strResRCDATA  db 'RCdata', 0
   strResMSGTBL  db 'MessageTable', 0
   strResGRPCSR  db 'GroupCursor', 0
   strResGRPICO  db 'GroupIcon', 0
   strResVERS    db 'Version', 0
   strResDLGINC  db 'DlgInclude', 0
   strResPLGPLY  db 'PlugPlay', 0
   strResVXD     db 'VxD', 0
   strResANICSR  db 'AniCursor', 0
   strResANIICO  db 'AniIcon', 0
   strResHTML    db 'Html', 0
   strResUDF     db 'UserDefined', 0
   strFOA        db 'FOA', 0
   strSepLine    db '----------------------------------------------------------', 0DH, 0AH, 0
   ;;;Column Name Text for TreeCtrl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   strFmtNodeText   db '%s%s', 0
   strFmtCurLvlStr  db '%s%d', 0
   strFmtLeftNode   db 'Left%s', 0
   strRootText      db 'Root', 0
   strSubText       db 'Sub', 0
   strTextEmpty     db 0
   strFmtResData    db '%X - %X', 0
   strFmtStrFOA     db '%-10s', 0
   strFmtNewLine    db '%02X', 0DH, 0AH, 0
   strFmtNoNewLine  db '%02X ', 0
   strFmtAddress    db '%08X: ', 0
   ;;;Message Text for current tab page;;;;;;;;;;;;;;;;;;;;;;;;;;
   strInvalidBase   db '读取资源表时,文件基址无效', 0
   strInvalidResTbl db '读取的资源表无效', 0
   strResDataErr    db '读取资源数据时,数据参数无效', 0
   strResBaseErr    db '读取资源数据时,文件基址无效', 0
   strFmtTest       db '商: %d, 余: %d', 0
   strGetHeapErr    db '读取资源数据时,获取进程堆栈句柄失败', 0
   strAllocMemErr   db '读取资源数据时,分配内存失败', 0

.data
   _hWnd        HWND NULL   ;;当前页面窗口的句柄;
   _hTreeCtrl   HWND NULL   ;;当前页面窗口上面的树型控件句柄;
   _hEdtResData HWND NULL   ;;当前页面窗口上面用于显示资源数据的编辑框句柄;
   _strResTbl   LPBYTE NULL ;;资源表的基址;

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Common Function
;;资源类型ID定义在头文件WinUser.h中;
_Type2Name proc NEAR32 STDCALL PRIVATE __dwTypeId:DWORD
  local @strType:LPCTSTR
  mov @strType, 0
  pushad
  .if __dwTypeId == RT_CURSOR           ;;Hardware-dependent cursor resource
     mov @strType, offset strResCURSOR
  .elseif __dwTypeId == RT_BITMAP       ;;Bitmap resource
     mov @strType, offset strResBITMAP
  .elseif __dwTypeId == RT_ICON         ;;Hardware-dependent icon resource
     mov @strType, offset strResICON
  .elseif __dwTypeId == RT_MENU         ;;Menu resource
     mov @strType, offset strResMENU
  .elseif __dwTypeId == RT_DIALOG       ;;Dialog box
     mov @strType, offset strResDIALOG
  .elseif __dwTypeId == RT_STRING       ;;String-table entry
     mov @strType, offset strResSTRING
  .elseif __dwTypeId == RT_FONTDIR      ;;Font directory resource
     mov @strType, offset strResFONTDIR
  .elseif __dwTypeId == RT_FONT         ;;Font resource
     mov @strType, offset strResFONT
  .elseif __dwTypeId == RT_ACCELERATOR  ;;Accelerator table
     mov @strType, offset strResACCE
  .elseif __dwTypeId == RT_RCDATA       ;;Application-defined resource (raw data)
     mov @strType, offset strResRCDATA
  .elseif __dwTypeId == RT_MESSAGETABLE ;;Message-table entry
     mov @strType, offset strResMSGTBL
  .elseif __dwTypeId == RT_GROUP_CURSOR ;;Hardware-independent cursor resource
     mov @strType, offset strResGRPCSR
  .elseif __dwTypeId == RT_GROUP_ICON   ;;Hardware-independent icon resource
     mov @strType, offset strResGRPICO
  .elseif __dwTypeId == RT_VERSION      ;;Version resource
     mov @strType, offset strResVERS
  .elseif __dwTypeId == RT_DLGINCLUDE
     mov @strType, offset strResDLGINC
  .elseif __dwTypeId == RT_PLUGPLAY     ;;Plug and Play resource
     mov @strType, offset strResPLGPLY
  .elseif __dwTypeId == RT_VXD          ;;VxD
     mov @strType, offset strResVXD
  .elseif __dwTypeId == RT_ANICURSOR    ;;Animated cursor
     mov @strType, offset strResANICSR
  .elseif __dwTypeId == RT_ANIICON      ;;Animated icon
     mov @strType, offset strResANIICO
  .elseif __dwTypeId == RT_HTML         ;;HTML
     mov @strType, offset strResHTML
  .else
     mov @strType, offset strResUDF     ;;User Defined
  .endif
  popad
  mov eax, @strType
  ret
_Type2Name endp

_InitTabWnd proc NEAR32 STDCALL PRIVATE __hWnd:HWND
  pushad
  mov eax, __hWnd
  mov _hWnd, eax
  invoke GetDlgItem, _hWnd, IDC_TREE_RESOURCE_TABLE
  mov _hTreeCtrl, eax
  invoke GetDlgItem, _hWnd, IDC_EDT_RES_TBL_DATA
  mov _hEdtResData, eax
  mov _strResTbl, NULL
  popad
  mov eax, TRUE
  ret
_InitTabWnd endp

_CreateTreeView proc NEAR32 STDCALL PRIVATE __hParent:HTREEITEM, __dwDepth:DWORD, __strLvlStr:LPSTR, __dwCount:DWORD
  local @i:DWORD
  local @tvi:TV_INSERTSTRUCT
  local @hNode:HTREEITEM
  local @strCurLvlStr[TEMP_BUFF_SIZE]:TCHAR
  local @strNodeText[TEMP_BUFF_SIZE]:TCHAR
  mov @hNode, 0
  
  pushad
  invoke RtlZeroMemory, addr @tvi, sizeof TV_INSERTSTRUCT
  mov @tvi.item.imask, TREE_NODE_MASK
  mov @tvi.item.cchTextMax, sizeof @strNodeText 
  
  mov @i, 0
  xor ecx, ecx
  inc ecx
  .while ecx <= __dwCount
     push ecx
     mov @i, ecx
     invoke RtlZeroMemory, addr @strCurLvlStr, sizeof @strCurLvlStr
     invoke wsprintf, addr @strCurLvlStr, offset strFmtCurLvlStr, __strLvlStr, @i
     invoke RtlZeroMemory, addr @strNodeText, sizeof @strNodeText
     .if __dwDepth >= 3  ;;总共__dwDepth层,即,树的高度是__dwDepth层;如果已经达到最大深度__dwDepth,则第__dwDepth层是叶子节点;
        invoke wsprintf, addr @strNodeText, offset strFmtLeftNode, addr @strCurLvlStr
        mov @tvi.item.cChildren, FALSE  ;;Leaf Node
        lea eax, @strNodeText
        mov @tvi.item.pszText, eax
        xor eax, eax
        mov eax, __hParent
        mov @tvi.hParent, eax
        mov @tvi.hInsertAfter, TVI_LAST
        mov @tvi.item.lParam, NODE_PARAM_EMPTY
        invoke SendMessage, _hTreeCtrl, TVM_INSERTITEM, 0, addr @tvi
        mov @hNode, eax
     .else
        .if __dwDepth == 1
           mov ebx, offset strRootText
        .else
           mov ebx, offset strSubText
        .endif
        invoke wsprintf, addr @strNodeText, offset strFmtNodeText, ebx, addr @strCurLvlStr
        mov @tvi.item.cChildren, TRUE  ;;No Leaf Node
        lea eax, @strNodeText
        mov @tvi.item.pszText, eax
        xor eax, eax
        mov eax, __hParent
        mov @tvi.hParent, eax
        mov @tvi.hInsertAfter, TVI_LAST
        mov @tvi.item.lParam, NODE_PARAM_VALUE
        invoke SendMessage, _hTreeCtrl, TVM_INSERTITEM, 0, addr @tvi
        mov @hNode, eax
        xor ebx, ebx
        mov ebx, __dwDepth
        inc ebx
        invoke _CreateTreeView, @hNode, ebx, addr @strCurLvlStr, __dwCount
     .endif
     pop ecx
     ;Next
     inc ecx
  .endw
  popad
  mov eax, TRUE
  ret
_CreateTreeView endp

_InitTreeView proc NEAR32 STDCALL PRIVATE
  pushad
  ;;set Style
  invoke GetWindowLong, _hTreeCtrl, GWL_STYLE
  OR eax, TVS_HASBUTTONS;
  OR eax, TVS_HASLINES;
  OR eax, TVS_LINESATROOT;
  invoke SetWindowLong, _hTreeCtrl, GWL_STYLE, eax
  
  invoke _CreateTreeView, TVI_ROOT, 1, offset strTextEmpty, 4
  popad
  mov eax, TRUE
  ret
_InitTreeView endp

_ParseResourceDirectory proc NEAR32 STDCALL PRIVATE __lpResDir:PIMAGE_RESOURCE_DIRECTORY, __hParent:HTREEITEM, __dwDepth:DWORD
  local @dwRet:DWORD
  local @lpResSubDir:PIMAGE_RESOURCE_DIRECTORY
  local @apResDirEntry:PIMAGE_RESOURCE_DIRECTORY_ENTRY
  local @lpResDirEntry:PIMAGE_RESOURCE_DIRECTORY_ENTRY
  local @lpResName:PIMAGE_RESOURCE_DIR_STRING_U
  local @lpResDataEntry:PIMAGE_RESOURCE_DATA_ENTRY
  local @tvi:TV_INSERTSTRUCT
  local @hCurNode:HTREEITEM, @hLeaf:HTREEITEM
  local @wLoop:WORD, @dwNumberOfDirEntries:DWORD
  local @strResType:LPCTSTR
  local @strNodeText[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke RtlZeroMemory, addr @tvi, sizeof TV_INSERTSTRUCT
  mov @tvi.item.imask, TREE_NODE_MASK
  mov @tvi.item.cchTextMax, sizeof @strNodeText
  
  xor esi, esi
  mov esi, __lpResDir ;;;esi ---> IMAGE_RESOURCE_DIRECTORY
  
  ;;the number of IMAGE_RESOURCE_DIRECTORY_ENTRY
  xor eax, eax
  mov ax, WORD PTR [esi + IMAGE_RESOURCE_DIRECTORY.NumberOfNamedEntries]
  add ax, WORD PTR [esi + IMAGE_RESOURCE_DIRECTORY.NumberOfIdEntries]
  mov @dwNumberOfDirEntries, eax ;;;@dwNumberOfDirEntries = __lpResDir->NumberOfNamedEntries + __lpResDir->NumberOfIdEntries;
  
  xor eax, eax
  mov eax, __lpResDir
  add eax, sizeof IMAGE_RESOURCE_DIRECTORY
  mov @apResDirEntry, eax ;;;@apResDirEntry = (PIMAGE_RESOURCE_DIRECTORY_ENTRY)((LPBYTE)__lpResDir + sizeof(IMAGE_RESOURCE_DIRECTORY));
  
  xor esi, esi
  mov esi, @apResDirEntry ;;;esi ---> IMAGE_RESOURCE_DIRECTORY_ENTRY
  
  .while ecx < @dwNumberOfDirEntries
     push ecx
     
     ;;Name
     invoke RtlZeroMemory, addr @strNodeText, sizeof @strNodeText
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_RESOURCE_DIRECTORY_ENTRY.Name1]
     .if (eax & 80000000H) ;;bit[31] = 1, Name is a String point to IMAGE_RESOURCE_DIR_STRING_U;
        ;;if(lpResDirEntry->NameIsString)        ;;this way is OK,too: lpResDirEntry->NameIsString <==> (lpResDirEntry->Name & 0x80000000)
        and eax, NOT 80000000H ;;;eax = eax AND (~0x80000000)
        ;add edi, (eax AND (NOT 80000000H)) ;;lpResName = (PIMAGE_RESOURCE_DIR_STRING_U)(_strResTbl+ (lpResDirEntry->Name & (~0x80000000)));
        xor edi, edi
        mov edi, _strResTbl
        add edi, eax
        add edi, IMAGE_RESOURCE_DIR_STRING_U.NameString
        ;;lpResName = (PIMAGE_RESOURCE_DIR_STRING_U)(_strResTbl + lpResDirEntry->NameOffset); ;;this way is OK,too: lpResDirEntry->NameOffset <==> (lpResDirEntry->Name & (~0x80000000))
        invoke wsprintf, addr @strNodeText, offset strFmtStr, edi
     .else ;;bit[31] = 0, Name is Id;
        and eax, 0000FFFFH ;;lpResDirEntry->Id
        .if __dwDepth == 0
           xor ebx, ebx
           mov ebx, eax
           invoke _Type2Name, ebx
           invoke wsprintf, addr @strNodeText, offset strFmtStr, eax
        .else
           invoke wsprintf, addr @strNodeText, offset strFmt1D, eax
        .endif
     .endif
     
     ;;create a sub node
     mov @tvi.item.cChildren, TRUE  ;;No Leaf Node
     xor eax, eax
     lea eax, @strNodeText
     mov @tvi.item.pszText, eax
     xor eax, eax
     mov eax, __hParent
     mov @tvi.hParent, eax
     mov @tvi.hInsertAfter, TVI_LAST
     mov @tvi.item.lParam, NODE_PARAM_VALUE
     invoke SendMessage, _hTreeCtrl, TVM_INSERTITEM, 0, addr @tvi
     mov @hCurNode, eax
     
     ;;OffsetToData
     xor eax, eax
     mov eax, DWORD PTR [esi + IMAGE_RESOURCE_DIRECTORY_ENTRY.OffsetToData]
     .if (eax & 80000000H)  ;;bit[31] = 1, bit[30:0] is a pointer that point to the address of the next level directory(IMAGE_RESOURCE_DIRECTORY);
     ;;if(lpResDirEntry->DataIsDirectory)             ;;this way is OK,too: lpResDirEntry->DataIsDirectory <==> (lpResDirEntry->OffsetToData & 0x80000000)
        and eax, NOT 80000000H ;;;eax = eax AND (~0x80000000); lpResDirEntry->OffsetToData & (~0x80000000)
        xor edi, edi
        mov edi, _strResTbl
        add edi, eax ;;lpResSubDir = (PIMAGE_RESOURCE_DIRECTORY)(_strResTbl+ (lpResDirEntry->OffsetToData & (~0x80000000)));
        xor ebx, ebx
        mov ebx, __dwDepth
        inc ebx
        invoke _ParseResourceDirectory, edi, @hCurNode, ebx;;递归调用,解析下一层目录;
     .else  ;;bit[31] = 0, bit[30:0] is a pointer that point to IMAGE_RESOURCE_DATA_ENTRY
        and eax, NOT 80000000H ;;;eax = eax AND (~0x80000000); lpResDirEntry->OffsetToData & (~0x80000000); eax = bit[30:0]
        xor edi, edi
        mov edi, _strResTbl
        add edi, eax ;;lpResDataEntry = (PIMAGE_RESOURCE_DATA_ENTRY)(_strResTbl+ lpResDirEntry->OffsetToData); edi ---> IMAGE_RESOURCE_DATA_ENTRY
        
        invoke RtlZeroMemory, addr @strNodeText, sizeof @strNodeText
        xor ebx, ebx
        mov ebx, DWORD PTR [edi + IMAGE_RESOURCE_DATA_ENTRY.OffsetToData]
        xor eax, eax
        mov eax, DWORD PTR [edi + IMAGE_RESOURCE_DATA_ENTRY.Size1]
        invoke wsprintf, addr @strNodeText, offset strFmtResData, ebx, eax
        
        ;;Leaf Node
        mov @tvi.item.cChildren, FALSE  ;;Leaf Node
        lea eax, @strNodeText
        mov @tvi.item.pszText, eax
        xor eax, eax
        mov eax, @hCurNode
        mov @tvi.hParent, eax
        mov @tvi.hInsertAfter, TVI_LAST
        mov @tvi.item.lParam, edi ;;资源数据块的起始地址可以保存在当前叶子节点hLeaf中或当前叶子节点hLeaf的父节点hCurNode里面;此实现是保存在当前叶子节点hLeaf中;
        invoke SendMessage, _hTreeCtrl, TVM_INSERTITEM, 0, addr @tvi
        mov @hLeaf, eax
        ;;;.break  ;;exit the current function
     .endif
     
     pop ecx
     
     ;Next
     inc ecx  ;;;next Index
     add esi, sizeof IMAGE_RESOURCE_DIRECTORY_ENTRY ;;;next IMAGE_RESOURCE_DIRECTORY_ENTRY
  .endw
  
  popad
  mov eax, TRUE
  ret
_ParseResourceDirectory endp

_Fill proc NEAR32 STDCALL PRIVATE __lpParam:LPVOID
  local @dwRet:DWORD
  local @lpResRootDir:PIMAGE_RESOURCE_DIRECTORY
  local @tvi:TV_INSERTSTRUCT
  local @strNodeText[TEMP_BUFF_SIZE]:TCHAR
  mov @dwRet, TRUE
  
  pushad
  invoke SendMessage, _hTreeCtrl, TVM_DELETEITEM, 0, TVI_ROOT
  
  .if g_strBase == NULL
     invoke MessageBox, _hWnd, offset strInvalidBase, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  .if ((g_lpResTbl == NULL) || (g_lpResBlk == NULL))
     invoke MessageBox, _hWnd, offset strInvalidResTbl, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  xor esi, esi
  mov esi, g_lpResBlk  ;;; esi ---> origin IMAGE_DATA_DIRECTORY entry, this is not converted by Rva2Foa()
  .if DWORD PTR [esi + IMAGE_DATA_DIRECTORY.isize] == 0
     ;;insert a node item;
     invoke RtlZeroMemory, addr @strNodeText, sizeof @strNodeText
     invoke wsprintf, addr @strNodeText, offset strFmtStr, offset strFmtNone
     invoke RtlZeroMemory, addr @tvi, sizeof TV_INSERTSTRUCT
     mov @tvi.item.imask, TREE_NODE_MASK
     mov @tvi.hParent, TVI_ROOT
     mov @tvi.hInsertAfter, TVI_LAST
     mov @tvi.item.cchTextMax, sizeof @strNodeText
     xor eax, eax
     lea eax, @strNodeText
     mov @tvi.item.pszText, eax
     mov @tvi.item.lParam, NODE_PARAM_EMPTY
     invoke SendMessage, _hTreeCtrl, TVM_INSERTITEM, 0, addr @tvi
     mov @dwRet, FALSE
     jmp ERR_Fill
  .endif
  
  xor eax, eax
  mov eax, g_lpResTbl
  mov @lpResRootDir, eax ;;lpResRootDir = g_lpResTbl;
  mov _strResTbl, eax    ;;_strResTbl = (LPBYTE)lpResRootDir;
  
  invoke _ParseResourceDirectory, @lpResRootDir, TVI_ROOT, 0
  
  mov @dwRet, TRUE
  
  ERR_Fill:
  popad
  mov eax, @dwRet
  ret
_Fill endp

_ReadResourceData proc NEAR32 STDCALL PRIVATE __lpResDataEntry:PIMAGE_RESOURCE_DATA_ENTRY
  local @dwRet:DWORD, @dwNumberOfLines:DWORD, @dwTotalBytes:DWORD
  local @strResDataBase:LPBYTE, @dwFoa:DWORD, @i:DWORD, @j:DWORD
  local @iLen:DWORD, @k:DWORD, @strData:LPTSTR, @dwResSize:DWORD
  local @hHeap:HANDLE, @dwLen:DWORD
  local @strMsg[TEMP_BUFF_SIZE]:CHAR
  mov @dwRet, TRUE
;  LPBYTE pos = NULL, posHead = NULL, posTail = NULL;
  
  pushad
  
  .if (__lpResDataEntry == NULL)
     invoke MessageBox, _hWnd, offset strResDataErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_ReadResourceData
  .endif
  
  .if g_strBase == NULL
     invoke MessageBox, _hWnd, offset strResBaseErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_ReadResourceData
  .endif
  
  xor esi, esi
  mov esi, __lpResDataEntry
  
  ;;Resource Size
  xor edx, edx
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_RESOURCE_DATA_ENTRY.Size1] ;;;被除数EDX:EAX
  mov @dwResSize, eax
  xor ebx, ebx  ;;;除数
  mov ebx, 16
  div ebx       ;;;EDX:EAX/16
  .if edx       ;;;EDX中存放的是余数;
     inc eax    ;;;EAX中存放的是商,即:行数;如果余数不为0,则行数累加1;
  .endif
  mov @dwNumberOfLines, eax
  
  ;;总字节数;
  xor eax, eax
  mov eax, BYTES_OF_PER_LINE ;;;被乘数;表示每行的字节数;
  mul @dwNumberOfLines       ;;;乘数;表示行数  ;;;EAX*dwNumberOfLines的乘积表示总字节数,存放在EAX中;
  add eax, EXTRA_BYTES       ;;;加上额外的字节数;结果就是所有数据的总字节数;
  mov @dwTotalBytes, eax     ;;;需要开辟的内存空间的大小;
  
  ;;Get Process Heap
  mov @hHeap, NULL
  xor eax, eax
  invoke GetProcessHeap
  .if eax == NULL
     invoke MessageBox, _hWnd, offset strGetHeapErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_ReadResourceData
  .endif
  mov @hHeap, eax
  
  ;;Alloc Memory
  mov @strData, 0
  xor eax, eax
  invoke HeapAlloc, @hHeap, HEAP_ZERO_MEMORY, @dwTotalBytes
  .if eax == NULL
     invoke MessageBox, _hWnd, offset strAllocMemErr, offset strCapErr, MSG_BTN_STYLE_ERR
     mov @dwRet, FALSE
     jmp RET_ReadResourceData
  .endif
  mov @strData, eax
  xor edi, edi
  mov edi, eax
  
  xor eax, eax
  mov eax, DWORD PTR [esi + IMAGE_RESOURCE_DATA_ENTRY.OffsetToData]
  invoke PE_Rva2Foa, eax
  mov @dwFoa, eax
  add eax, g_strBase
  xor esi, esi
  mov esi, eax  ;;;esi:Base Address of the Resource Data
  
  ;;format the header;
  xor eax, eax
  invoke wsprintf, @strData, offset strFmtStrFOA, offset strFOA
  mov @dwLen, eax
  add edi, eax ;;;skip the header1
  
  xor ecx, ecx
  .while ecx < 16
     push ecx
     xor ebx, ebx
     .if ecx == 0FH
        mov ebx, offset strFmtNewLine
     .else
        mov ebx, offset strFmtNoNewLine
     .endif
     
     xor eax, eax
     invoke wsprintf, edi, ebx, ecx
     add edi, eax
     pop ecx
     
     ;Next
     inc ecx
  .endw
  
  xor eax, eax
  invoke wsprintf, edi, offset strFmtStr, offset strSepLine
  add edi, eax
  
  ;;format the resource data;
  mov @k, 0
  mov @j, 0
  xor ecx, ecx
  .while ecx < @dwResSize
     push ecx
     ;;format one line;
     ;;FOA:
     .if (@j == 0) ;;new line
        xor eax, eax
        mov eax, 16
        mul @k          ;;;eax = eax * k = 16 * k
        add eax, @dwFoa ;;;eax = dwFoa + 16*k
        invoke wsprintf, edi, offset strFmtAddress, eax
        add edi, eax
        inc @k          ;;;k++
     .endif
     
     ;;byte:
     xor ebx, ebx
     .if @j == 0FH
        mov ebx, offset strFmtNewLine
     .else
        mov ebx, offset strFmtNoNewLine
     .endif
     
     xor edx, edx
     mov dl, BYTE PTR [esi]
     invoke wsprintf, edi, ebx, edx
     add edi, eax
     
     inc @j
     .if (@j == 16)
        mov @j, 0
     .endif
     
     pop ecx
     
     ;Next
     inc ecx
     inc esi
  .endw
  
  dec edi
  .if BYTE PTR [edi] == 20H
     mov BYTE PTR [edi], 0
  .endif
  
  invoke SetDlgItemText, _hWnd, IDC_EDT_RES_TBL_DATA, @strData
  
  ;;Free Memory
  invoke HeapAlloc, @hHeap, 0, @strData
  mov @dwRet, TRUE
  
  RET_ReadResourceData:
  popad
  mov eax, @dwRet
  ret
_ReadResourceData endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Message Handlers
_OnFillForm proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  pushad
  invoke _Fill, NULL
  popad
  mov eax, TRUE
  ret
_OnFillForm endp

_OnSelchangedTreeResourceTable proc NEAR32 STDCALL PRIVATE __lpNMHDR:LPNMHDR
  local @dwRet:DWORD, @dwHasSubNode:DWORD
  local @hLeaf:HTREEITEM
  local @tvNode:TVITEM
  local @lpResDataEntry:PIMAGE_RESOURCE_DATA_ENTRY
  
  .if __lpNMHDR == NULL
     ret
  .endif
  
  mov @dwRet, FALSE
  mov @dwHasSubNode, FALSE
  mov @hLeaf, NULL
  
  pushad
	xor esi, esi
	mov esi, __lpNMHDR
  
  xor eax, eax
  mov eax, DWORD PTR [esi + NMTREEVIEW.itemNew.hItem]
  .if eax == NULL
     mov @dwRet, FALSE
     jmp EXIT_OnSelchangedTreeResourceTable
  .endif
  mov @hLeaf, eax
  
  invoke RtlZeroMemory, addr @tvNode, sizeof TVITEM
  
  ;;设置GetItem时使用的查询条件;
  mov @tvNode.imask, TREE_NODE_MASK
  mov @tvNode.state, TVIS_SELECTED
  xor eax, eax
  mov eax, @hLeaf
  mov @tvNode.hItem, eax
  
  ;;发送查询消息;
  invoke SendMessage, _hTreeCtrl, TVM_GETITEM, 0, addr @tvNode
  .if eax == FALSE  ;;TVM_GETITEM Failed
     mov @dwRet, FALSE
     jmp EXIT_OnSelchangedTreeResourceTable
  .endif
  
  ;;如果所选择的节点没有子节点(即,该节点是叶子节点),则读取叶子节点上保存的资源数据的起始地址;
  .if @tvNode.cChildren == TRUE ;;选择的不是叶子节点;
     mov @dwRet, FALSE
     jmp EXIT_OnSelchangedTreeResourceTable
  .endif
  
  .if ((@tvNode.lParam == NODE_PARAM_VALUE) || (@tvNode.lParam == NODE_PARAM_EMPTY))
     ;;叶子节点上保存的资源数据起始地址无效;
     mov @dwRet, FALSE
     jmp EXIT_OnSelchangedTreeResourceTable
  .endif
  
  ;;依据叶子节点上保存的资源数据的起始地址,读取资源数据;
  mov @lpResDataEntry, NULL
  xor eax, eax
  mov eax, @tvNode.lParam
  mov @lpResDataEntry, eax
  invoke _ReadResourceData, @lpResDataEntry ;;@tvNode.lParam --> lpResDataEntry:PIMAGE_RESOURCE_DATA_ENTRY
  
  EXIT_OnSelchangedTreeResourceTable:
  popad
  mov eax, @dwRet
  ret
_OnSelchangedTreeResourceTable endp

_OnNotify proc NEAR32 STDCALL PRIVATE __wParam:WPARAM, __lParam:LPARAM
  .if __lParam == 0
     ret
  .endif
  
  pushad
  xor esi, esi
  mov esi, __lParam
  
  .if DWORD PTR [esi + NMHDR.code] == TVN_SELCHANGED
     invoke _OnSelchangedTreeResourceTable, __lParam
  .endif
  
  popad
  mov eax, TRUE
  ret
_OnNotify endp

;;实现应用程序对话框过程;
ResTblProc proc NEAR32 STDCALL PUBLIC __hWnd:HWND, __uMsg:UINT, __wParam:WPARAM, __lParam:LPARAM
  local @dwResult:DWORD
  mov @dwResult, 0
  pushad
  .if __uMsg == WM_INITDIALOG
     invoke _InitTabWnd, __hWnd
     invoke _InitTreeView
     mov @dwResult, TRUE
  .elseif __uMsg == UDM_FILLFORM
     invoke _OnFillForm, __wParam, __lParam
     mov @dwResult, TRUE
  .elseif __uMsg == WM_NOTIFY
     .if (__wParam == IDC_TREE_RESOURCE_TABLE)
        invoke _OnNotify, __wParam, __lParam
        mov @dwResult, TRUE
     .endif
  .else
     mov @dwResult, FALSE
  .endif
  popad
  mov eax, @dwResult
  ret
ResTblProc endp

END