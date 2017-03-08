
OUTDIR=.\release
TMPDIR=.\tmp
RESDIR=.\res

NAME = PeToolA
EXE  = $(OUTDIR)\$(NAME).exe
RES  = $(TMPDIR)\$(NAME).res
OBJS = $(TMPDIR)\String.obj $(TMPDIR)\Define.obj $(TMPDIR)\PeFile.obj $(TMPDIR)\PeToolA.obj $(TMPDIR)\MainWnd.obj $(TMPDIR)\TabPeFile.obj \
       $(TMPDIR)\TabDosHdr.obj $(TMPDIR)\TabFilHdr.obj $(TMPDIR)\TabOptHdr.obj $(TMPDIR)\TabDatDir.obj $(TMPDIR)\TabBlkTbl.obj \
       $(TMPDIR)\TabExpTbl.obj $(TMPDIR)\TabImpTbl.obj $(TMPDIR)\TabRlcTbl.obj $(TMPDIR)\TabResTbl.obj $(TMPDIR)\TabUsrOpr.obj

ML_FLAGS = /nologo /c /coff /Cp
LK_FLAGS = /nologo /subsystem:windows

$(EXE): $(TMPDIR) $(OUTDIR) $(OBJS) $(RES)
	LINK $(LK_FLAGS) /out:$(EXE) $(OBJS) $(RES)
	@ cscript //Nologo cmd\CopyByTime.js $(EXE) R

$(TMPDIR):
	@if not exist $(TMPDIR) mkdir $(TMPDIR)

$(OUTDIR):
	@if not exist $(OUTDIR) mkdir $(OUTDIR)

$(TMPDIR)\$(NAME).res: $(RESDIR)\PeToolA.rc
	RC $(RESDIR)\PeToolA.rc
	@move $(RESDIR)\PeToolA.res $(TMPDIR)

$(TMPDIR)\String.obj : String.asm
	@ML $(ML_FLAGS) String.asm
	@move String.obj $(TMPDIR)

$(TMPDIR)\Define.obj : Define.asm
	@ML $(ML_FLAGS) Define.asm
	@move Define.obj $(TMPDIR)

$(TMPDIR)\PeFile.obj : PeFile.asm
	@ML $(ML_FLAGS) PeFile.asm
	@move PeFile.obj $(TMPDIR)

$(TMPDIR)\PeToolA.obj: PeToolA.asm
	@ML $(ML_FLAGS) PeToolA.asm
	@move PeToolA.obj $(TMPDIR)

$(TMPDIR)\MainWnd.obj: MainWnd.asm
	@ML $(ML_FLAGS) MainWnd.asm
	@move MainWnd.obj $(TMPDIR)

$(TMPDIR)\TabPeFile.obj: TabPeFile.asm
	@ML $(ML_FLAGS) TabPeFile.asm
	@move TabPeFile.obj $(TMPDIR)

$(TMPDIR)\TabDosHdr.obj: TabDosHdr.asm
	@ML $(ML_FLAGS) TabDosHdr.asm
	@move TabDosHdr.obj $(TMPDIR)

$(TMPDIR)\TabFilHdr.obj: TabFilHdr.asm
	@ML $(ML_FLAGS) TabFilHdr.asm
	@move TabFilHdr.obj $(TMPDIR)

$(TMPDIR)\TabOptHdr.obj: TabOptHdr.asm
	@ML $(ML_FLAGS) TabOptHdr.asm
	@move TabOptHdr.obj $(TMPDIR)

$(TMPDIR)\TabDatDir.obj: TabDatDir.asm
	@ML $(ML_FLAGS) TabDatDir.asm
	@move TabDatDir.obj $(TMPDIR)

$(TMPDIR)\TabBlkTbl.obj: TabBlkTbl.asm
	@ML $(ML_FLAGS) TabBlkTbl.asm
	@move TabBlkTbl.obj $(TMPDIR)

$(TMPDIR)\TabExpTbl.obj: TabExpTbl.asm
	@ML $(ML_FLAGS) TabExpTbl.asm
	@move TabExpTbl.obj $(TMPDIR)

$(TMPDIR)\TabImpTbl.obj: TabImpTbl.asm
	@ML $(ML_FLAGS) TabImpTbl.asm
	@move TabImpTbl.obj $(TMPDIR)

$(TMPDIR)\TabRlcTbl.obj: TabRlcTbl.asm
	@ML $(ML_FLAGS) TabRlcTbl.asm
	@move TabRlcTbl.obj $(TMPDIR)

$(TMPDIR)\TabResTbl.obj: TabResTbl.asm
	@ML $(ML_FLAGS) TabResTbl.asm
	@move TabResTbl.obj $(TMPDIR)

$(TMPDIR)\TabUsrOpr.obj: TabUsrOpr.asm
	@ML $(ML_FLAGS) TabUsrOpr.asm
	@move TabUsrOpr.obj $(TMPDIR)

clean:
	@del /s *.obj
	rem @del /s *.exe
	@del /s *.res
	@rd    /s /q $(TMPDIR)
	@rmdir /s /q $(OUTDIR)