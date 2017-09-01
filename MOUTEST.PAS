uses Graph,GorGraph,GorGUI,crt,dos;
var gd,gm:integer;
    x,y:integer;
    c:word;
    dx,dy:integer;
    sc:real;
    p:pointer;
    regs:registers;
var anim:TAnim;
    mcur:TMouseCursor;
    ar1:TButton;

{$F+}
procedure clb (x,y:integer;buttons:word);
begin
  Bar (0,0,200,200);
  OutTextXY (20,20,SStr(x)+','+SStr(y)+';'+SStr(buttons));
  SetFillStyle (SolidFill,255);
  if buttons=mbLeft then mcur.RedrawCursor (true);
end;
{$F-}


begin
gd:=InstallUserDriver('SVGA256',nil);
gm:=2;
InitGraph (gd,gm,'');
InitMouse;
DrawPCX (0,0,'cursors\pointer.pcx',dx,dy,true);
mcur.Init ('cursors\pointer.gcr');
GlobalCursor:=mcur;
Draw3DBox (0,0,GetMaxX,25);
SetColor (15);
ar1.Init(300,300,'images\ok.gim','images\ok2.gim');
ar1.callback:=clb;
repeat
  mcur.RedrawCursor(false);
  ar1.Callbacker;
until (keypressed) and (readkey=#27);
mcur.Done;
ar1.Done;
end.