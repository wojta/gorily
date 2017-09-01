unit GorGraph;

interface
  type
       PBImage=^TBImage;
       TImage=record                    {obrazek pomoci spojoveho seznamu,}
           imgBegin,imgEnd:PBImage;     {odpada omezeni 64kB}
           dx,dy:integer;               {dx,dy=velikosti obrazku}
       end;

       PFrame=^TFrame;
       TAnim=record                     {animace pomoci spojoveho seznamu,}
           imgBegin,imgEnd:PFrame;      {jeden snimek <64kB}
           Pos:PFrame;                  {Pos=ukazatel na pozici akt. snimku}
           dx,dy:integer;               {dx,dy=velikosti snimku}
       end;

       TFrame=record                {snimek animace}
            Image:pointer;          {ukazatel na obrazek kompatibilni s PutImage}
            IsNext:boolean;         {je dalsi, pro cteni ze souboru}
            Next:PFrame;            {ukazatel na dalsi snimek}
       end;

       TBImage=record               {blok(cast) obrazku TImage}
             y1,y2:integer;         {rozsah bloku}
             size:word;             {velikost obrazku}
             Image:pointer;         {ukazatel na obrazek kompatibilni s PutImage}
             IsNext:boolean;        {je dalsi, pro cteni ze souboru}
             Next:PBImage;
       end;

{Prevod integeru na string}
   function SStr(i:longint):string;

{Zobrazeni obrazku PCX na pozici x1,y1. Do dx,dy se ulozi rozmery.
setpal povoluje nastaveni palety}
   function DrawPCX (x1,y1:integer;filename:string;var dx,dy:integer;setpal:boolean):boolean;

{Okamzite zobrazeni blokoveho obrazku typu TImage pomoci nacteni ze souboru.
Do dx,dy se ulozi rozmery. BitBlt je zpusob vykresleni.}
   function DrawGIM (x1,y1:integer;filename:string;var dx,dy:integer;BitBlt:word):boolean;

{Inicializace blokoveho obrazku typu TImage}
   procedure NewBImage (var Image:TImage);

{Uvolneni blokoveho obrazku typu TImage}
   procedure DisposeBImage (var Image:TImage);

{Sejmuti blokoveho obrazku typu TImage z obrazovky z obdelnika o
souradnicich x1,y1,x2,y2}
   procedure GetBImage (x1,y1,x2,y2:integer;var Image:TImage);

{Zobrazeni blokoveho obrazku typu TImage ulozeneho v pameti v
promenne predane pomoci Image. BitBlt je zpusob vykresleni.}
   procedure DrawBImage (x1,y1:integer;var Image:TImage;BitBlt:word);

{Inicializace animace s rozmery dx,dy}
   procedure NewAnim (dx,dy:integer;var Anim:TAnim);

{Uvolneni animace}
   procedure DisposeAnim (var Anim:TAnim);

{Pridani snimku do animace, sejmuteho z obrazovky z obdelnika o
souradnicich x,y,Anim.dx,Anim,dy}
   procedure AddFrame (x,y:integer;var Anim:TAnim);

{Vykresleni snimku animace na pozici x,y. Je-li jump true, skoci na dalsi snimek}
   procedure DrawFrame (x,y:integer;var Anim:TAnim;BitBlt:word;jump:boolean);

{Konverze PCX souboru na animaci}
   procedure ConvertToAnim (filemask,filename:string);

{Nahrani animace ze souboru do Anim}
   procedure LoadAnim (filename:string;var Anim:TAnim);

{Konverze PCX na blokovy obrazek}
   procedure ConvertToBImage (filemask:string;filename:string);

{Nahrani blokoveho obrazku do Image}
   procedure LoadBImage (filename:string;var Image:TImage);

{Zjisteni hodnoty pixelu z blokoveho obrazku ulozeneho v Image}
   function GetBImPixel (x,y:integer;var Image:TImage):word;

{Zjisteni hodnoty pixelu obrazku kompatibilniho z PutImage ulozeneho v Image}
   function GetImagePixel (x,y:integer;Image:pointer):word;

implementation

uses dos,graph,crt;


{$I SVGAUTIL.INC}

   function SStr(i:longint):string;
   var s:string;
   begin
     Str(i,s);
     SStr:=s;
   end;

{Nastaveni palety}
   procedure SetDACPalette(NumOfColors:Word;var RGBBuf);
   var Regs:Registers;
   begin
     with Regs do begin
       AH:=$10;
       AL:=$12;
       ES:=Seg(RGBBuf);
       DX:=Ofs(RGBBuf);
       BX:=$00;
       CX:=NumOfColors;
    end;
    Intr($10,Regs);
   end;

   procedure NewAnim (dx,dy:integer;var Anim:TAnim);
   begin
     Anim.imgBegin:=nil;
     Anim.imgEnd:=nil;
     Anim.Pos:=nil;
     Anim.dx:=dx;
     Anim.dy:=dy;
   end;

   procedure DisposeAnim (var Anim:TAnim);
   var tmpFrame:PFrame;
   begin
     if Anim.imgBegin=nil then exit; {nic tam neni}
     repeat
       tmpFrame:=Anim.imgBegin;
       Anim.imgBegin:=Anim.imgBegin^.Next;
       FreeMem (tmpFrame^.Image,word(Anim.dx+1)*word(Anim.dy+1)+4);
       Dispose (tmpFrame);
       tmpFrame:=nil;
     until Anim.imgBegin=nil;
   end;

   procedure AddFrame (x,y:integer;var Anim:TAnim);
   var img:pointer;
       size:longint;
       tmpFrame:PFrame;
   begin
     New (tmpFrame);
     size:=word(Anim.dx+1)*word(Anim.dy+1)+4; {velikost snimku}
     if (size>MaxAvail) or (size>65500) then exit;    {je dost pameti?}
     GetMem(img,size);                                {alokace}
     GetImage(x,y,x+Anim.dx,y+Anim.dy,img^);          {sejmuti}
     tmpFrame^.Image:=img;
     tmpFrame^.IsNext:=false;
     tmpFrame^.Next:=nil;
     if Anim.imgBegin=nil then begin                  {pridani}
        Anim.imgBegin:=tmpFrame;
        Anim.Pos:=Anim.imgBegin;
        Anim.imgEnd:=tmpFrame;
     end else begin
        Anim.imgEnd^.Next:=tmpFrame;
        Anim.imgEnd^.IsNext:=true;
        Anim.imgEnd:=tmpFrame;
     end;
   end;

   procedure DrawFrame (x,y:integer;var Anim:TAnim;BitBlt:word;jump:boolean);
   begin
     if Anim.Pos<>nil then begin
       PutImage (x,y,Anim.Pos^.Image^,BitBlt);
       if jump then Anim.Pos:=Anim.Pos^.Next;
     end else begin
       PutImage (x,y,Anim.imgBegin^.Image^,BitBlt);
       if jump then Anim.Pos:=Anim.imgBegin^.Next;
     end;
   end;

{Pridani lomitka na konec cesty}
   function AddPSlash (path:string):string;
   begin
      if path[length(path)]<>'\' then AddPSlash:=path+'\' else AddPSlash:=path;
      if path='' then AddPSlash:='';
   end;

   procedure ConvertToAnim (filemask,filename:string);
   var srec:SearchRec;
       tmpFrame:PFrame;
       path:DirStr;
       name:NameStr;
       ext:ExtStr;
       NumWrite:word;
       Anim:TAnim;
       dx,dy:integer;
       f:file;
   begin
     FindFirst(filemask,AnyFile,srec); {nalezeni prvniho souboru}
     FSplit(filemask,path,name,ext);   {rozporcovani cesty}
     ClearDevice;                      {smazani obrazovky}
     DrawPCX(0,0,AddPSlash(path)+srec.Name,dx,dy,false); {vykresleni PCX souboru}
     NewAnim (dx,dy,Anim); {inicializace animace}
     while DosError = 0 do
     begin
       AddFrame (0,0,Anim);    {pridani snimku}
       FindNext(srec);         {dalsi soubor}
       if DosError=0 then DrawPCX(0,0,AddPSlash(path)+srec.Name,dx,dy,false);
     end;
     Assign (f,filename);                        {otevreni vysledneho souboru}
     Rewrite (f,1);                              {pro prepis}
     BlockWrite (f,Anim,SizeOf(Anim),NumWrite);
     repeat                                       {ukladani a uvolnovani pameti}
       tmpFrame:=Anim.imgBegin;
       BlockWrite (f,tmpFrame^,SizeOf(TFrame),NumWrite);
       BlockWrite (f,tmpFrame^.Image^,word(Anim.dx+1)*word(Anim.dy+1)+4,NumWrite);
       Anim.imgBegin:=Anim.imgBegin^.Next;
       FreeMem (tmpFrame^.Image,word(Anim.dx+1)*word(Anim.dy+1)+4);
       Dispose (tmpFrame);
       tmpFrame:=nil;
     until Anim.imgBegin=nil;
     Close(f);   {uzavreni souboru}
   end;

   procedure ConvertToBImage (filemask:string;filename:string);
   var srec:SearchRec;
       tmpBImage:PBImage;
       path,path2:DirStr;
       name:NameStr;
       ext:ExtStr;
       NumWrite:word;
       Image:TImage;
       dx,dy:integer;
       f:file;
   begin
     FindFirst(filemask,AnyFile,srec);
     FSplit(filemask,path,name,ext);
     ClearDevice;
     DrawPCX(0,0,AddPSlash(path)+srec.Name,dx,dy,true);
     NewBImage (Image);
     while DosError = 0 do
     begin
        Assign (f,filename);
        Rewrite (f,1);
        BlockWrite (f,dx,SizeOf(dx),NumWrite);
        BlockWrite (f,dy,SizeOf(dy),NumWrite);
        GetBImage(0,0,dx,dy,Image);
        repeat
          tmpBImage:=Image.imgBegin;
          if tmpBImage=nil then break;
          with tmpBImage^ do begin
            BlockWrite (f,y1,SizeOf(y1),NumWrite);
            BlockWrite (f,y2,SizeOf(y2),NumWrite);
            BlockWrite (f,size,SizeOf(size),NumWrite);
            BlockWrite (f,Image^,size,NumWrite);
            BlockWrite (f,IsNext,SizeOf(IsNext),NumWrite);
          end;
         Image.imgBegin:=Image.imgBegin^.Next;
         FreeMem (tmpBImage^.Image,tmpBImage^.size);
         Dispose (tmpBImage);
         tmpBImage:=nil;
       until Image.imgBegin=nil;
       Close(f);
       FindNext(srec);
       if DosError=0 then begin
         DrawPCX(0,0,AddPSlash(path)+srec.Name,dx,dy,false);
         ClearDevice;
       end;
     end;
   end;

   procedure LoadAnim (filename:string;var Anim:TAnim);
   var f:file;
       tmpFrame:PFrame;
       img:pointer;
       size:longint;
       NumRead:word;
   begin
     Assign (f,filename);
     Reset (f,1);
     BlockRead (f,Anim,SizeOf(Anim),NumRead);
     with Anim do begin
        imgBegin:=nil;
        imgEnd:=nil;
        Pos:=nil;
     end;
     repeat
       New (tmpFrame);
       BlockRead (f,tmpFrame^,SizeOf(TFrame),NumRead);
       if SizeOf(TFrame)<>NumRead then begin
         Dispose (tmpFrame);
         break;
       end;
       size:=word(Anim.dx+1)*word(Anim.dy+1)+4;
       if (size>MaxAvail) or (size>65500) then exit;
       GetMem(img,size);
       BlockRead (f,img^,size,NumRead);
       tmpFrame^.Image:=img;
       tmpFrame^.Next:=nil;
       if Anim.imgBegin=nil then begin
         Anim.imgBegin:=tmpFrame;
         Anim.Pos:=Anim.imgBegin;
         Anim.imgEnd:=tmpFrame;
       end else begin
         Anim.imgEnd^.Next:=tmpFrame;
         Anim.imgEnd:=tmpFrame;
       end;
     until (NumRead = 0);
     close (f);
end;

   procedure NewBImage(var Image:TImage);
   begin
     Image.imgBegin:=nil;
     Image.imgEnd:=nil;
   end;

   procedure DisposeBImage (var Image:TImage);
   var tmpBImage:PBImage;
   begin
     if Image.imgBegin=nil then exit;
     repeat
       tmpBImage:=Image.imgBegin;
       Image.imgBegin:=Image.imgBegin^.Next;
       FreeMem (tmpBImage^.Image,tmpBImage^.size);
       Dispose (tmpBImage);
     until Image.imgBegin=nil;
   end;

   procedure GetBImage (x1,y1,x2,y2:integer;var Image:TImage);
   var tmpBImage:PBImage;
       img:pointer;

     procedure AddNewBlock (x1,y1,x2,y2:integer); {adds part of image (size<64kB)}
     var size:longint;
     begin
       size:=word(abs(x1-x2)+1)*word(abs(y1-y2)+1)+4;
       if size>MaxAvail then exit;
       new (tmpBImage);
       tmpBImage^.size:=size;
       GetMem (img,size);
       GetImage (x1,y1,x2,y2,img^);
       tmpBImage^.IsNext:=false;
       tmpBImage^.Next:=nil;
       tmpBImage^.Image:=img;
       tmpBImage^.y1:=y1;
       tmpBImage^.y2:=y2;
       if Image.imgBegin=nil then begin
          Image.imgBegin:=tmpBImage;
          Image.imgEnd:=tmpBImage;
       end else begin
          Image.imgEnd^.Next:=tmpBImage;
          Image.imgEnd^.IsNext:=true;
          Image.imgEnd:=tmpBImage;
       end;
     end;

   var usize:longint;
       lsize:integer;  {size of a line}
       bsize:word;
       dy1,dy2:integer;
   const safesize=65000; {bezpecna velikost}
   begin
     usize:=(longint(abs(x2-x1)+1)*longint(abs(y2-y1)+1))+4; {celova velikost obrazku (muze byt >64kB)}
     if usize>MaxAvail then exit;
     lsize:=abs(x1-x2); {velikost radku}
     if lsize=0 then exit;
     bsize:=(safesize div lsize)*lsize; {velikost bloku}
     dy1:=y1;                      {blok od radku dy1}
     dy2:=y1+(bsize div lsize);    {     do radku dy2}
     if dy2>y2 then dy2:=y2;
     Image.dx:=abs(x1-x2);
     Image.dy:=abs(y1-y2);
     while usize>=0 do begin
        AddNewBlock (x1,dy1,x2,dy2); {pridani bloku}
        usize:=usize-bsize;          {zmensuje velikost s pridavanim bloku}
        dy1:=dy2;                    {blok od-do}
        dy2:=dy2+(bsize div lsize);
        if dy2>y2 then dy2:=y2;      {posledni blok je zbytek}
     end;
   end;

   procedure LoadBImage (filename:string;var Image:TImage);
   var f:file;
       tmpBImage:PBImage;
       img:pointer;
       size:longint;
       NumRead:word;
   begin
     Assign (f,filename);
     Reset (f,1);
     with Image do begin
        imgBegin:=nil;
        imgEnd:=nil;
     end;
     BlockRead (f,Image.dx,SizeOf(Image.dx),NumRead);
     BlockRead (f,Image.dy,SizeOf(Image.dy),NumRead);
     repeat
       New (tmpBImage);
       tmpBImage^.Next:=nil;
       with tmpBImage^ do begin
         BlockRead (f,y1,SizeOf(y1),NumRead);
         BlockRead (f,y2,SizeOf(y2),NumRead);
         BlockRead (f,size,SizeOf(size),NumRead);
         if size>MaxAvail then begin {neni-li dost pameti, tak konec}
            Dispose(tmpBImage);
            exit
         end else GetMem (Image,size);
         BlockRead (f,Image^,size,NumRead);
         BlockRead (f,IsNext,SizeOf(IsNext),NumRead);
         if SizeOf(IsNext)<>NumRead then begin    {to uz je konec}
           FreeMem (Image,size);
           Dispose (tmpBImage);
           break;
         end;
       end;
       if Image.imgBegin=nil then begin
          Image.imgBegin:=tmpBImage;
          Image.imgEnd:=tmpBImage;
       end else begin
          Image.imgEnd^.Next:=tmpBImage;
          Image.imgEnd^.IsNext:=true;
          Image.imgEnd:=tmpBImage;
       end;
     until (not tmpBImage^.IsNext);
     close (f);
end;

   function GetBImPixel (x,y:integer;var Image:TImage):word;
   var tmpBImage,tmp2BImage:PBImage;
       pc:^word;
   begin
     GetBImPixel:=0;
     if Image.imgBegin=nil then exit;
     tmpBImage:=Image.imgBegin;
     while (tmpBImage<>nil) and not ((tmpBImage^.y1<=y) and (tmpBImage^.y2>=y)) do begin
       tmpBImage:=tmpBImage^.Next;
     end;
     {Zjisteni pixelu pomoci pointeru na word}
     {Zacina se na segmentu a offsetu tmpBImage^.Image^}
     {prida se potrebny posun v pameti 1pixel=1byte ve 256-barevnem rezimu}
     {prvni 4 bajty jsou pro rozmery obrazku}
     if (tmpBImage=nil) or ((longint(y-tmpBImage^.y1)*longint(Image.dx+1)+x+4)<0) then exit;
     pc:=Ptr(Seg(tmpBImage^.Image^),Ofs(tmpBImage^.Image^)+(word(y-tmpBImage^.y1)*word(Image.dx+1))+x+4);
     GetBImPixel:=pc^;
   end;

   function GetImagePixel (x,y:integer;Image:pointer):word;
   var pc:^word;
       dx,dy:^word;
   begin
     GetImagePixel:=0;
     dx:=Ptr(Seg(Image^),Ofs(Image^)); {zjisteni rozmeru - prvni 4 bajty}
     dy:=Ptr(Seg(Image^),Ofs(Image^)+2);
     {podobne jako v GetBImPixel}
     if (y*(dx^+1)+x+4)<0 then exit;
     pc:=Ptr(Seg(Image^),Ofs(Image^)+(y*(dx^+1))+x+4);
     GetImagePixel:=pc^;
   end;

   function DrawGIM (x1,y1:integer;filename:string;var dx,dy:integer;BitBlt:word):boolean;
   var dy1,dy2:integer;
       size:word;
       Image:pointer;
       IsNext:boolean;
       NumRead:word;
       f:file;
   begin
    Assign (f,filename);
    Reset (f,1);
    BlockRead (f,dx,SizeOf(dx),NumRead);
    BlockRead (f,dy,SizeOf(dy),NumRead);
     repeat
         BlockRead (f,dy1,SizeOf(dy1),NumRead);
         BlockRead (f,dy2,SizeOf(dy2),NumRead);
         BlockRead (f,size,SizeOf(size),NumRead);
         if size>MaxAvail then begin   {pokud neni pamet tak se procedura ukonci}
            DrawGIM:=false;
            exit;
         end else GetMem (Image,size);
         BlockRead (f,Image^,size,NumRead);
         BlockRead (f,IsNext,SizeOf(IsNext),NumRead);
         PutImage(x1,y1+dy1,Image^,BitBlt);
         FreeMem (Image,size); {pamet se hned uvolni}
     until (not IsNext);
     close (f);
end;

   procedure DrawBImage (x1,y1:integer;var Image:TImage;BitBlt:word);
   var tmpBImage:PBImage;
       ry:integer;
   begin
      tmpBImage:=Image.imgBegin;
      ry:=0;
      while tmpBImage<>nil do begin
        PutImage (x1,y1+ry,tmpBImage^.Image^,BitBlt);
        ry:=ry+tmpBImage^.y2-tmpBImage^.y1;
        tmpBImage:=tmpBImage^.Next;
      end;
   end;

   function DrawPCX (x1,y1:integer;filename:string;var dx,dy:integer;setpal:boolean):boolean;
   Const
     BufferSize = 4096;
   type
     TPCXHeader = record
          Ident, {PCX identifikace=$0a}
          Ver,   {PCX verze}
          Code,  {PCX komprese $01-RLE}
          BPP  :  Byte; {bitu na pixel}
          X1, Y1, X2, Y2, {rozmery}
          Xr, Yr : Word; {dpi rozliseni}
          Pall : array[1..48] of Byte; {16-barevna paleta}
          R, {rezervovano=0}
          colplane  :  Byte; {?}
          BPL, {bajtu na radku}
          PalTyp  :  Word; {typ palety}
          other  :  array[1..58] of Byte; {zbytek rezervovan}
   end;
   Var f : file;
       NumRead, Counter: Word;
       Header: TPCXHeader;
       XEnd2: Word;
       L1, i, X, Y: Word;
       Buffer:  ARRAY[1..BufferSize] OF Byte;
       Color, rep:  Byte;
       RGBPal: ARRAY[0..255] of Record R,G,B: Byte end;
   begin
     DrawPCX:=false;
     Assign(f, filename);
     {$I-} Reset(f, 1); {$I+}
     if ioresult<>0 then exit;
     BlockRead(f, Header, SizeOf(Header), NumRead);
     If NumRead <> SizeOf(Header) then exit;
     If (Header.Ident <> 10) or (Header.Ver <> 5) or (Header.Code<>1) then exit;
     if setpal then begin
       Seek(f, FileSize(f)-768);  {skoci pred paletu}
       BlockRead(f, RGBPal, Sizeof(RGBPal)); {precte paletu}
       FOR i:=0 TO 255 DO {nastavi paletu}
        with RGBPal[i] do
        begin
          R:=R shr 2;
          G:=G shr 2;
          B:=B shr 2;
        end;
     SetDACPalette(256,RGBPal);
     end;
     Seek(f, 128);      {skoci pred zacatek dat obrazku}
     Y:= 0;
     X:= 0;
     Counter:= 4096; {pozice v bufferu}
     While (Y < Header.Y2+1) do begin
       Inc(Counter);
     If Counter>BufferSize then {nacteni bufferu}
     begin
      BlockRead(f, Buffer, BufferSize, NumRead);
      Counter:=1;
     end;
     If Buffer[Counter]>=192 then begin
      rep:=Buffer[Counter]-192; {kolikrat se pixel opakuje}
      Inc(Counter); {dalsi pixel}
     If Counter > BufferSize then begin
        BlockRead(f, Buffer, BufferSize, NumRead);
        Counter:=1;
     end;
     Color:= Buffer[Counter];
     end else begin
      rep:=1;
      Color:=Buffer[Counter];
     end;
     for L1:= 1 to rep do
     begin
      If X = Header.BPL then {test konce radku}
      begin
        Inc(Y);
        X:= 0;
      end;
       PutPixel(X+x1, Y+y1, Color); {vykresleni pixelu}
       Inc(X)
     end;
     end;
     dx:=Header.X2-Header.X1; {nastaveni velikosti}
     dy:=Header.Y2-Header.Y1;
     Close(f);
   end;

begin
end.