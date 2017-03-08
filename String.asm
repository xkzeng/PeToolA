;;;模式定义;;;
.386
.model flat,stdcall
option casemap:none

PUBLIC strCapInf, strCapErr, strCapWrn, strAppInstErr, strMainIcoErr, strMainWndErr
PUBLIC strFmtNone, strFmtStr, strFmtStrL, strFmtDateTime
PUBLIC strFmt2X, strFmt2XL, strFmt4X, strFmt4XL, strFmt8X, strFmt8XL
PUBLIC strFmt1D, strFmt2D, strFmt4D, strFmt1U, strFmt2U, strFmt4U
PUBLIC strDefSoftName, strDefAuthor, strDefEmail

.const
   strCapInf db 'Message', 0
   strCapErr db 'Error', 0
   strCapWrn db 'Warn', 0
   strAppInstErr db 'Failed to initialize the instance of application!', 0
   strMainIcoErr db 'failed to load the icon of the application main window', 0
   strMainWndErr db 'failed to create main dialog', 0
   strFmtNone db 'None', 0
   strFmtStr  db '%s', 0
   strFmt2X   db '%02X', 0
   strFmt4X   db '%04X', 0
   strFmt8X   db '%08X', 0
   strFmtStrL db ' %s', 0
   strFmt2XL  db ' %02X', 0
   strFmt4XL  db ' %04X', 0
   strFmt8XL  db ' %08X', 0
   strFmt1D   db '%d', 0
   strFmt2D   db '%02d', 0
   strFmt4D   db '%04d', 0
   strFmt1U   db '%u', 0
   strFmt2U   db '%02u', 0
   strFmt4U   db '%04u', 0
   strFmtDateTime db ' %Y-%m-%d %H:%M:%S', 0
   strDefSoftName db 'PeToolA', 0
   strDefAuthor   db '曾现奎', 0
   strDefEmail    db 'zengxiankui@qq.com', 0

END