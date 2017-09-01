uses crt,graph,gorgraph;
var gd,gm:integer;
    c,x,y:word;
    dx,dy:integer;
    sc:real;
    p:pointer;
var anim:TAnim;
    img:TImage;
begin
if (ParamStr(1)='') or (ParamStr(2)='') then begin
   writeln;
   writeln ('Pouzijte parametry podle n vodu:');
   writeln ('PCXTOGIM file1.pcx file2.gim');
   writeln ('PCXTOGNM filemask.pcx file2.gnm {PCXTOGNM gorila*.pcx gorila.anm}');
   exit;
end;
gd:=InstallUserDriver('SVGA256',nil);
gm:=2;
InitGraph (gd,gm,'');
if GraphResult<>grOk then begin
   writeln ('Selhala inicializace grafiky');
end else begin
  ConvertToAnim (ParamStr(1),ParamStr(2));
  CloseGraph;
end;
end.