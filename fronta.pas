type TTypCloveka=(student,ucitel);
     PClovek=^TClovek;
     TClovek=record
               typ:TTypCloveka;
               jmeno:string;
               rocnik:byte;
               dalsi:PClovek;
             end;
     TFronta=object
               Zacatek:PClovek;
	       Konec:PClovek;
	       procedure PrichodCloveka (var Clovek:TClovek);
	       procedure ObslouzeniCloveka;
	       procedure VypisFronty;
	       procedure Anarchie;
	       constructor VytvorFrontu;
	       destructor ZnicFrontu;
	     end;

constructor TFronta.VytvorFrontu;
begin
  Zacatek:=nil;
  Konec:=nil;
end;

destructor TFronta.ZnicFrontu;
  var tmpClovek,tmp2Clovek:PClovek;
begin
  if Zacatek<>nil then begin
     tmpClovek:=Zacatek;
     repeat
       tmp2Clovek:=tmpClovek^.dalsi;
       Dispose (tmpClovek);
       tmpClovek:=tmp2Clovek;
     until tmpClovek=nil;
  end;
end;

procedure TFronta.PrichodCloveka (var Clovek:TClovek);
  var newClovek:PClovek;
begin
  New(newClovek);
  newClovek^:=Clovek;
  newClovek^.dalsi:=nil;
  if Zacatek=nil then begin
     Zacatek:=newClovek;
     Konec:=Zacatek;
  end else begin
     Konec^.dalsi:=newClovek;
     Konec:=newClovek;
  end;
end;

procedure TFronta.ObslouzeniCloveka;
  var ntyp:string;
      tmpClovek:PClovek;
begin
  if Zacatek=nil then writeln ('Neni koho obslouzit.') else begin
     case Zacatek^.typ of
       student:ntyp:='Student(ka)';
       ucitel:ntyp:='Ucitel(ka)';
     end;
     write (ntyp,' ',Zacatek^.jmeno);
     if Zacatek^.typ=student then write (' z ',Zacatek^.rocnik,'. rocniku');
     writeln (' byl(a) obslouzen(a)');
     tmpClovek:=Zacatek^.dalsi;
     Dispose (Zacatek);
     Zacatek:=tmpClovek;
  end;
end;



procedure TFronta.VypisFronty;
  var tmpClovek,tmp2Clovek:PClovek;
      ntyp:string;
begin
  if Zacatek=nil then writeln ('Nikdo neni ve fronte') else begin
     writeln ('Ve fronte cekaji:');
     tmpClovek:=Zacatek;
     repeat
       case tmpClovek^.typ of
	 student:ntyp:='Student(ka)';
	 ucitel:ntyp:='Ucitel(ka)';
       end;
       write (ntyp,' ',tmpClovek^.jmeno);
       if tmpClovek^.typ=student then writeln (' z ',tmpClovek^.rocnik,'. rocniku') else writeln;
       tmp2Clovek:=tmpClovek;
       tmpClovek:=tmpClovek^.dalsi;
     until tmp2Clovek^.dalsi=nil;
  end;
end;

procedure TFronta.Anarchie;
  var tmpClovek,tmp2Clovek,tmp3Clovek,min:PClovek;
      hod:byte;
      stop:boolean;

  procedure Swap (var cl1,cl2:PClovek);
    var tmp:TClovek;
        tmp2,tmp3:PClovek;
  begin
    tmp2:=cl2^.dalsi;
    cl2^.dalsi:=cl1^.dalsi;
    cl1^.dalsi:=tmp2;
    Move (cl1^,tmp,SizeOf(tmp));
    Move (cl2^,cl1^,SizeOf(cl1^));
    Move (tmp,cl2^,SizeOf(cl2^));
end;

begin
   tmpClovek:=Zacatek;
   if tmpClovek^.typ=ucitel then begin
     tmpClovek:=Zacatek^.dalsi;
     Dispose (Zacatek);
     Zacatek:=tmpClovek;
   end;
   repeat
       if tmpClovek^.dalsi^.typ=ucitel then begin
	 tmp2Clovek:=tmpClovek^.dalsi^.dalsi;
	 Dispose(tmpClovek^.dalsi);
	 tmpClovek^.dalsi:=tmp2Clovek;
       end else tmpClovek:=tmpClovek^.dalsi;
   until (tmpClovek=nil);
   tmpClovek:=Zacatek^.dalsi;
   tmp2Clovek:=Zacatek;
   min:=Zacatek;
   while tmp2Clovek<>nil do begin
     tmpClovek:=tmp2Clovek;
     min:=tmpClovek;
     while tmpClovek<>nil do begin
       if (min^.rocnik>tmpClovek^.rocnik) then begin
          min:=tmpClovek;
       end;
       tmpClovek:=tmpClovek^.dalsi;
     end;
     Swap(min,tmp2Clovek);
     tmp2Clovek:=tmp2Clovek^.dalsi;
   end;
end;


var Fronta:^TFronta;
    jmroc,jmeno:string;
    ctyp:char;
    code,rocnik:integer;
    Prac:TClovek;
begin
  New (Fronta,VytvorFrontu);
  repeat
    write ('>');
    readln (jmroc);
    ctyp:=jmroc[1];
    if UpCase(ctyp)='K' then break;
    if UpCase(ctyp)='V' then Fronta^.VypisFronty;
    if UpCase(ctyp)='O' then Fronta^.ObslouzeniCloveka;
    if UpCase(ctyp)='A' then Fronta^.Anarchie;
    jmroc:=Copy (jmroc,3,Length(jmroc)-2);
    jmeno:=Copy (jmroc,1,Pos(' ',jmroc)-1);
    Val (Copy(jmroc,Pos(' ',jmroc),Length(jmroc)-Pos(' ',jmroc)+1),rocnik,code);
    Prac.rocnik:=rocnik;
    case UpCase(ctyp) of
       '?':begin
	     writeln ('Prikazy:');
	     writeln;
	     writeln ('S <jmeno> <rocnik> - prichod studenta do fronty');
	     writeln ('U <jmeno> - prichod ucitele do fronty');
	     writeln ('V - vypis fronty');
	     writeln ('O - obslouzeni cloveka na zacatku fronty');
             writeln ('A - anarchie!!');
	     writeln ('? - napoveda');
	     writeln ('K - konec programu a rozpusteni fronty');
	   end;
       'S':begin
           Prac.typ:=student;
           Prac.jmeno:=jmeno;
           end;
       'U':begin
           Prac.typ:=ucitel;
           Prac.jmeno:=jmroc;
	   end;
       'A','V','O':continue;
       else writeln ('Neplatne zadani (?=napoveda).');
    end;
    Fronta^.PrichodCloveka(Prac);
  until false;
  Dispose (Fronta,ZnicFrontu);
end.