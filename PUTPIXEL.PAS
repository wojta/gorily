uses crt,graph,gorgraph;
var gd,gm:integer;
    c,x,y:word;
    dx,dy:integer;
    sc:real;
    p:pointer;
var anim:TAnim;
    img:TImage;
begin
writeln (MaxAvail);
readln;
gd:=InstallUserDriver('SVGA256',nil);
gm:=2;
InitGraph (gd,gm,'');
ConvertToBImage ('images\ok2.pcx','images\ok2.gim');
ClearDevice;
LoadBImage ('images\ok2.gim',img);
DrawBImage (400,300,img,NormalPut);
repeat
until keypressed;
CloseGraph;
end.