uses Graph,Dos,Crt,GorGraph,GorGUI,GorGame,RunERR;
var gd,gm:integer;
    tx,ty:integer;
    xeend:byte;


   procedure InitGraphics;
   var dx,dy:integer;
   begin
     gd:=InstallUserDriver('SVGA256',nil);
     gm:=2;
     InitGraph (gd,gm,'');
     if GraphResult<>grOk then begin
        writeln ('Selhala inicializace grafiky');
        Halt(1);
     end else begin
        DrawPCX (0,0,'images\pal.pcx',dx,dy,true);
        slowdown:=1;
        SetTextStyle(SmallFont,0,4);
        ClearDevice;
     end;
   end;

{$F+} {callback OK tlacitka z okna chyby}
   procedure bOkErrCB(x,y:integer;buttons:word);
   begin
     if buttons=mbLeft then xeend:=1;
   end;
{$F-}


   procedure MyExitProc;
   var hx,hy,gx,gy:integer;
       key:word;
       flags:byte;
       butOk:TButton;
   begin
     if ExitCode=0 then Halt(0);
     if MaxAvail<10000 then begin
        CloseGraph;
        write (#7);
        writeln ('DoØlo k chybØ v programu:');
        writeln (ExitCode,':',GetErrorStr(ExitCode),' na adrese ',Seg(ErrorAddr),':',Ofs(ErrorAddr));
        writeln;
        writeln ('Program bude ukonŸen.');
        readkey;
        Halt(ExitCode);
     end;
     mcur.CleanCursor;
     mcur.ChangeCursor ('cursors\pointer.gnm');
     gx:=200;
     gy:=100;
     hx:=(GetMaxX-gx) div 2;
     hy:=(GetMaxY-gy) div 2;
     Draw3DBox (hx,hy,hx+gx,hy+gy);
     SetColor (255);
     mcur.ResetCursor;
     butOk.Init (((2*hx+gx) div 2)-40,hy+gy-30,'images\ok.gim','images\ok2.gim');
     butOk.callback:=bOkErrCB;
     mcur.CleanCursor;
     OutTextXY (hx+20,hy+10,'Doçlo k chybØ v programu:');
     SetColor (12);
     OutTextXY (hx+20,hy+25,SStr(ExitCode)+': '+GetErrorStr(ExitCode));
     SetColor (255);
     OutTextXY (hx+20,hy+40,'Program bude ukonŸen.');
     mcur.ResetCursor;
     mcur.RedrawCursor(true);
     xeend:=0;
     repeat
       butOk.callbacker;
       if keypressed then KeyStroke(key,flags);
       case key of
          283:xeend:=1;
       end;
       key:=0;
       mcur.RedrawCursor(false);
     until xeend<>0;
     butOk.Done;
     CloseGraph;
     Halt(ExitCode);
end;

var img:TAnim;
    hx,hy:integer;
    i:integer;

begin
  InitGraphics;
  ExitProc:=@MyExitProc;
  NTMouse:=false;
  InitMouse;
  GlobalCursor:=@mcur;
  mcur.Init ('cursors\pointer.gnm');
  MainMenu;
  mcur.Done;
  CloseGraph;
end.