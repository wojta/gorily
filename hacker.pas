uses crt;
type TKruh=array [1..27] of char;
const Kruh:TKruh=('Q','W','E','R','T','Y','U','I','O','P','A','S','D',
            'F','G','H','J','K','L','Z','X','C','V','B','N','M',' ');

var Vzorek:array[1..1001] of char;
var N,m,o,ps,vzorlen:word;
    last,cc:char;

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

procedure SediVzorek;
begin
  if ps+1>=vzorlen then exit;
  if (Vzd(Vzorek[ps],Vzorek[ps+1])=Vzd(cc,last)) then Inc(ps) else ps:=1;
end;

begin
  clrscr;
  TextColor (lightgray);
  m:=1;
  ps:=1;
  vzorlen:=0;
  write ('Pocet zadani>');
  readln (N);
  for o:=1 to N do begin
    write ('Vzorek - ',o,'>');
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
    write ('Zprava - ',o,'>');
    repeat
      cc:=readkey;
    until cc='"';
    write ('"');
    repeat
      cc:=readkey;
      if (((cc>='A') and (cc<='Z')) or (cc=#32)) then begin
        write (cc);
        SediVzorek;
        last:=cc;
       end;
    until (cc='"');
    writeln ('"');
    if (ps>1)  then begin
      TextColor (lightgreen);
      writeln ('Vzorek ',o,' se muze vyskytovat ve zprave ',o,' !');
    end else begin
      TextColor (lightred);
      writeln ('Vzorek ',o,' se nevyskytuje ve zprave ',o,' nebo je vzorek jednopismenny !');
    end;
    TextColor (lightgray);
    m:=1;
    ps:=1;
    vzorlen:=0;
 end;
 writeln ('Stisknete ENTER...');
 repeat
 until readkey=#13;
end.
