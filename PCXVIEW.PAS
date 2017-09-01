{$X+}
Uses DOS, Crt, Graph,BMP;
Const
  BufferSize = 4096;
Type
  HeaderTyp = RECORD
    Pass, Ver, Code, BPP  :  Byte;
    X1, Y1, X2, Y2, {ake okno sa ma pouzit x1,y1,x2,y2}
    Xr, Yr : Word; {x,y ove rozlisenie}
    Pall : array[1..48] of Byte; {paleta pre 16 farieb}
    R, {rezervovany} Colplane  :  Byte;
    BPL, {pocet bajtov na riadok} PalTyp  :  Word;
    free  :  array[1..58] of Byte;
  END;
Var
  f : file;
  gd,gm,grer : integer;
  NumRead, Counter: Word;
  Header: HeaderTyp;
  XEnd2: Word;
  po:pointer;
  L1, L2, X, Y: Word;
  Buffer:  ARRAY[1..BufferSize] OF Byte;
  Color,oPak:  Byte;
  RGBPal: ARRAY[0..255] of Record Red,Green,Blue: Byte end;

{$I SVGAUTIL.INC}

Procedure Abort(s: String);
begin
  Writeln(s);
  Writeln;
  halt(2);
end;

procedure Usage;
begin
 WriteLn('Usage : PCXView <file name> [mode]');
 WriteLn;
 WriteLn('Display modes : 0 -  320x200');
 WriteLn('                1 -  640x400');
 WriteLn('                2 -  640x480');
 WriteLn('                3 -  800x600');
 WriteLn('                4 - 1024x768');
 Halt;
end;


procedure SetDACPalette(ColorsNum:Word;var RGBBuf);
 var Regs:Registers;
begin
 with Regs do
 begin
  AH:=$10;
  AL:=$12;
  ES:=Seg(RGBBuf);
  DX:=Ofs(RGBBuf);
  BX:=$00;
  CX:=ColorsNum;
 end;
 Intr($10,Regs);
end;

function GetVideoMode(Width,Height:Word):Integer;

 const Res:array[0..3,1..2] of Word=((320,200),(0,0),(640,480),(800,600));
 var I,Code:Integer;
     S:String;
begin
 S:=Paramstr(2);
 Val(S,I,Code);
 If (I<>0) and (Code=0) Then
  begin
   GetVideoMode:=I;
   Exit;
  End;
 GetVideoMode:=0;
 for I:=0 to 3 do
 if (Width>Res[I,1]) or (Height>Res[I,2]) then GetVideoMode:=I+1
                                                           else Exit;
end;





begin
  If ParamCount < 1 then Usage;
  Assign(f, ParamStr(1));
  {$I-} Reset(f, 1); {$I+}
  if ioresult<>0 then halt(1);
  BlockRead(f, Header, SizeOf(Header), NumRead);
  If NumRead <> SizeOf(Header) then Abort('zly PCX file');
    XEnd2:= Header.BPL;
  With Header Do
   Begin
    If Header.Pass <> 10 then Abort('Zly PCX file');
    If Header.Ver <> 5 then Abort('Zla verzia PCX');
    If Header.Code<>1 then Abort('Zly sposob kodovania');
    Gm:=GetVideoMode(X2-X1,Y2-Y1);
  End;
  Gd:=InstallUserDriver('svga256',nil);
  InitGraph(Gd,Gm,'');

  GrEr:=GraphResult;
  if GreR<>grOK then abort(GraphErrorMsg(GrEr));

  Seek(f, FileSize(f)-768);  {skoci na pred paletu}
  BlockRead(f, RGBPal, Sizeof(RGBPal)); {nacita paletu do bufera}

    FOR L2:=0 TO 255 DO {nacita paletu}
     with RGBPal[L2] do
     Begin
      Red:=Red shr 2;
      Green:=Green shr 2;
      Blue:=Blue shr 2;
     end;
     SetDACPalette(256,RGBPal);

  Seek(f, 128);      { Skoci na zaciatok dat}
  Y:= 0;
  X:= 0;
  Counter:= 4096; {aktualna pozicia v bufery}
  While (Y < Header.Y2-1) and (Port[$60] > $80) do
  {robi kym je y-ova suradnica mensia ako ymax}
  begin
    Inc(Counter);
    If Counter>BufferSize then {ak je na konci bufra nacita novy bufer}
    begin
      BlockRead(f, Buffer, BufferSize, NumRead);
      Counter:=1;
    end;

    If Buffer[Counter]>=192 then
    begin
      oPak:=Buffer[Counter]-192; {nastavi kolkokrat sa opakuje bod}
      Inc(Counter); {ide o bod dalej}
     If Counter > BufferSize then
      begin {ak je na konci bufra tak nacita novy bufer}
        BlockRead(f, Buffer, BufferSize, NumRead);
        Counter:=1;
      end;
      Color:= Buffer[Counter];
    end
    else begin
      oPak:=1;
      Color:=Buffer[Counter];
    end;
    For L1:= 1 to oPak do {kolkokrat sa ma opakovat}
    begin  {opakuje po l2}
      If X = XEnd2 then {test ci nie je koniec riadku}
      begin
        Inc(Y);
        X:= 0;
      end; {polozi pixel na plochu}
       PutPixel(X, Y, Color);
       Inc(X)
    end;
  end;
  ReadKey;
  {GetMem (po,4+100*100);
  GetImage (100,100,200,200,po^);
  PutImage (200,200,po^,NOR_PUT);
  FreeMem (po,4+100*100);}
  readkey;
  Closegraph;
{  ASM
    MOV AX, $3;
    INT 10h
  END;}
  Close(f);
End.






