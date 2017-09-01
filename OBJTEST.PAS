type P1=^T1;
     T1=object
          hello:word;
          constructor Init;
          destructor Done;
          procedure Vidlak;virtual;
        end;
     P2=^T2;
     T2=object(T1)
          hovno:byte;
          constructor Init;
          destructor Done;
          procedure Mudla;
          procedure Vidlak;virtual;
        end;

procedure T1.Vidlak;
begin
  writeln ('T1.Vidlak');
end;

procedure T2.Vidlak;
begin
  writeln ('T2.Vidlak');
end;

procedure T2.Mudla;
begin
  writeln ('T2.Mudla');
end;

constructor T1.Init;
begin
  writeln ('T1.Init');
end;

constructor T2.Init;
begin
  writeln ('T2.Init');
end;

destructor T1.Done;
begin
  writeln ('T1.Done');
end;

destructor T2.Done;
begin
  writeln ('T2.Done');
end;

var A:P1;
    B:P2;
    C:P1;
begin
  new (A,Init);
  new (B,Init);
  C:=B;
  P2(C)^.Mudla;
  dispose (A,Done);
  dispose (P2(C),Done);
end.