uses crt;
type TKruh=array [1..27] of char;
const Kruh:TKruh=('Q','W','E','R','T','Y','U','I','O','P','A','S','D',
            'F','G','H','J','K','L','Z','X','C','V','B','N','M',' ');

var Vzorek:array[1..1001] of char;
var N,m,o,p,ps,vzorlen:word;
    cc,dd:char;

function Vzd(c,k:char):byte;
var i,a,b:byte;
begin
  i:=1;
  a:=0;
  b:=0;
  if c=k then Vzd:=0 else begin
    repeat
      if Kruh[i]<>c then begin
        if Kruh[i]=k then b:=i;
      end
      else a:=i;
        Inc (i);
     until ((a<>0) and (b<>0));
     if (abs(b-a)<13) then Vzd:=abs(a-b) else begin
        if (b<a) then Vzd:=b+(27-a) else Vzd:=a+(27-b);
    end;
  end;
end;


begin
  clrscr;
  TextColor (lightgray);
  writeln;
  writeln ('QWERTYUIOPASDFGHJKLZXCVBNM QWERTYUIOPASDFGHJKLZXCVBNM');
  m:=1;
  write ('Klic>');
  readln (N);
  write ('Zadejte text>');
  repeat
     cc:=readkey;
  until cc='"';
    write ('"');
    repeat
      cc:=readkey;
      if (((cc>='A') and (cc<='Z')) or (cc=#32)) then begin
        write (cc);
        Vzorek[m]:=cc;
        Inc(m);
      end;
    until ((cc='"') or (m>=1000));
    vzorlen:=m;
    writeln ('"');
    writeln ('Zasifrovany text:');
    write ('"');
    for o:=1 to vzorlen-1 do begin
      p:=1;
      repeat
       Inc (p)
      until Kruh[p]=Vzorek[o];
      write (Kruh[(p+N) mod 27]);
    end;
    writeln ('"');
end.
