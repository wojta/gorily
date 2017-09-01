uses GorGUI,crt;
var  code:word;
     flags:byte;
begin
TextMode (Co80);
repeat
  Keystroke(code,flags);
  writeln (code,';',flags,';');
until code=283;
end.