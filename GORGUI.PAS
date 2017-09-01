unit GorGUI;

interface
uses GorGraph;

const mbLeft=$01; {udalost-leve tlaciko}
      mbRight=$02;       {-prave tlaciko}
      mbMove=$20;        {-pohyb mysi}
      cbEdit=$30;        {-editace}

const kbLShift=2;       {flag Levy Shift}
      kbRShift=1;       {flag Pravy Shift}

const ttInt=1;   {TTextArea typu integer}
      ttString=2; {TTextArea typu string}

const objArea=1;  {typy objektu pro ulozeni v TContainer}
      objButton=2;
      objChkButton=3;
      objTxtArea=4;

type
    PArea=^TArea;
    TCallbackProc=procedure (x,y:integer;buttons:word); {procedura udalosti}
    PContObj=^TContObj;
    TContObj=record
               name:string[20];
               obj:PArea;
               Next:PContObj;
               typ:byte;
             end;

    TArea=object        {objekt oblasti}
              private
                px,py:integer;
              public
                x1,y1,x2,y2:integer; {rozmery aktivniho pasma oblasti}
                callback:TCallBackProc; {navratova procedura}
                enabled:boolean;
                procedure Redraw;virtual;
                procedure Callbacker;virtual; {kontrola jestli je nutne zavolat
                                               navratovou proceduru}
                constructor Init(x,y,dx,dy:integer); {inicializace s rozmery pasma oblasti}
                destructor Done; {uvolneni}
              end;

     PButton=^TButton;
     TButton=object (TArea)   {zdedene z TArea}
             private
               imgNormal,imgClicked:TImage;   {obrazky normalniho a stisknuteho tlacitka}
             public
               {zdedi se callback,x1,y1,x2,y2}
               clicked:boolean;  {stisknute ?}
               procedure Callbacker;virtual; {kontrola jestli je nutne zavolat
                                               navratovou proceduru}
               constructor Init(x,y:integer;normimg,climg:string); {inicializace s pozici tlacitka}
               procedure Redraw;virtual;
               procedure DrawClicked; {zobrazit stisknute}
               procedure DrawNormal; {zobrazit normalni}
               destructor Done; {uvolneni}
             end;

     PCheckButton=^TCheckButton;
     TCheckButton=object (TButton)
                  public
                    checked:boolean;
                    constructor Init(x,y:integer;normimg,climg:string);
                    procedure Redraw;virtual; {prekresleni}
                    procedure Callbacker;virtual;
                    destructor Done; {uvolneni}
                  end;

     PTextArea=^TTextArea;
     TTextArea=object (TArea) {textove pole}
               private
                 procedure Edit; {spusteni editacniho rezimu}
               public
                 text:string;
                 intval:integer;
                 intonly:boolean;
                 constructor Init(x,y,dx:integer;txt:string);
                 procedure Callbacker;virtual;
                 procedure Redraw;virtual; {prekresli pole}
                 destructor Done; {uvolneni}
               end;

    TMouseCursor=object   {kurzor mysi}
                   public
                     x,y:integer;  {pozice}
                     constructor Init (curfile:string); {inicializace}
                     procedure RedrawCursor(force:boolean); {prekresleni,
                                                             force=vynucene prekresleni}
                     procedure CleanCursor; {smazani kurzoru, prepsani kurzoru obrazkem z previmg}
                     procedure ResetCursor; {znovusejmuti previmg}
                     procedure ChangeCursor (curfile:string);  {zmena kurzoru}
                     destructor Done; {uvolneni}
                   private
                     cursor:TAnim; {animace kurzoru}
                     previmg:TImage; {obrazek pod kurzorem}
                     phase:longint; {faze animace}
                   end;
     TContainer=object
                  private
                    objBegin,objEnd:PContObj;
                  public
                    constructor Init;
                    destructor Done;

                       {pridani objektu do kontejneru; vraci ukazatel na kontejterovy objekt}
                       {do nej lze potom vlozit objekt TArea nebo jeho potomky}
                    function AddObject(name:string;typ:byte):PContObj;

                       {vraci ukazatel na kontejnerovy objekt}
                    function GetObject(name:string):PContObj;

                       {vraci ukazatel na objekt TArea}
                    function GetArea(name:string):PArea;

                       {provede proceduru Callbacker u vsech objektu v kontejneru}
                    procedure Callbacker;
                    procedure Redraw;
                end;


var GlobalCursor:^TMouseCursor; {globalni kurzor}
    Slowdown:real; {zpomaleni, 1-standartni,0.5-rychlejsi,2-pomalejsi}
    NTMouse:boolean; {oprava mysi pro Windows NT}

   function InitMouse:boolean; {Inicializace mysi pro dany rezim}
   procedure MouseStatus (var mx,my:integer;var Buttons:word); {stav mysi}
   procedure Keystroke (var code:word;var flags:byte); {zisti stisknutou klavesu}
   procedure Draw3DBox (x1,y1,x2,y2:integer); {Nakresli 3D tlacitko}
   procedure Draw3DBox2 (x1,y1,x2,y2:integer); {Nakresli 3D protlacene tlacitko}


implementation
uses Graph,Dos,crt;


   {$I SVGAUTIL.INC}


   constructor TArea.Init(x,y,dx,dy:integer);
   begin
     with self do begin
       x1:=x;
       y1:=y;
       x2:=dx;
       y2:=dy;
       px:=0;
       py:=0;
       callback:=nil;
       enabled:=true;
     end;
   end;

   procedure TArea.Redraw;
   begin
   end;

   destructor TArea.Done;
   begin
     {nic}
   end;

   procedure Keystroke (var code:word;var flags:byte);
   var Regs:registers;
   begin
     Regs.AH:=$00;
     Intr($16,Regs);
     code:=Regs.AX;
     Regs.AH:=$02;
     Intr($16,Regs);
     flags:=Regs.AL;
   end;

   procedure TArea.Callbacker;
   var bx,by:integer;
       but:word;
       cb:word;
   begin
     if not enabled then exit;
     MouseStatus (bx,by,but); {zjisteni stavu mysi}
     cb:=0;
                {je-li mys uvnitr pasma, tak...}
     if (bx>=x1) and (bx<=x2) and (by>=y1) and (by<=y2) then begin
        if (bx<>px) or (by<>py) then begin {pohnula-li se mys}
           px:=bx;
           py:=by;
          cb:=mbMove;
        end;
        {Stisklo-li se tlacitko}
        if (but<>0) and (px>=x1) and (px<=x2) and (py>=y1) and (py<=y2) then cb:=but;
     end;
     if (cb<>0) and (@callback<>nil) then callback(px,py,cb); {zavola udalostni proceduru}
   end;

   procedure TButton.Redraw;
   begin
     DrawNormal;
   end;

   procedure TButton.Callbacker;
   var bx,by:integer;
       but:word;
       cb:word;
   begin
     if not enabled then exit;
     MouseStatus (bx,by,but);
     cb:=0;
     if (bx>=x1) and (bx<=x1+imgNormal.dx) and (by>=y1) and (by<=y1+imgNormal.dy) then begin
        if (bx<>px) or (by<>py) then begin
           px:=bx;
           py:=by;
          cb:=mbMove;
        end;
        if (but<>0) and (px>=x1) and (px<=x2) and (py>=y1) and (py<=y2) then begin
          cb:=but;
          if But=mbLeft then DrawClicked; {vykresli stisk tlacitka}
        end;
     end;
     if (cb<>0) and (@callback<>nil) then callback(px,py,cb);
   end;

   function InitMouse:boolean;
   var Regs:registers;
   begin
     Regs.AX:=$0000;
     Intr ($33,Regs);
     {je zaven ovladac?}
     if Regs.AX=$FFFF then InitMouse:=true else InitMouse:=false;
     {nastaveni rozliseni mysi}
     Regs.AX:=$0007;
     Regs.CX:=$0000;
     Regs.DX:=GetMaxX;
     Intr ($33,Regs);
     Regs.AX:=$0008;
     Regs.CX:=$0000;
     Regs.DX:=GetMaxY;
     Intr ($33,Regs);
   end;

   procedure MouseStatus (var mx,my:integer;var Buttons:word);
   var Regs:registers;
   begin
     Regs.AX:=$0003;
     Intr ($33,Regs);
     mx:=Regs.CX;
     my:=Regs.DX;
     if NTMouse then my:=Round(my*2.4);
     Buttons:=Regs.BX;
   end;

   constructor TMouseCursor.Init (curfile:string);
   var but:word;
       Regs:Registers;
   begin
      Regs.AX:=$0004;          {nastaveni na stred obrazovky}
      Regs.CX:=GetMaxX div 2;
      Regs.DX:=GetMaxY div 2;
      Intr ($33,Regs);
      MouseStatus (x,y,but);
      LoadAnim (curfile,cursor); {nahrani kurzoru}
      NewBImage (previmg);
      GetBImage (x,y,x+cursor.dx,y+cursor.dy,previmg); {sejmuti mista pod kurzorem}
   end;

   procedure TMouseCursor.RedrawCursor(force:boolean);
   var but:word;
       px,py:integer;
   begin
      MouseStatus (px,py,but);
      {vykresli pokud se pohnul, pokud nastala faze nebo pokud to bylo vynucene}
      if ((px<>x) or (py<>y)) or (phase>Round(slowdown*300)) or force then begin
           DrawBImage (x,y,previmg,NormalPut);
           DisposeBImage (previmg);
           NewBImage (previmg);
           x:=px;
           y:=py;
           GetBImage (x,y,x+cursor.dx,y+cursor.dy,previmg);
           if phase>Round(slowdown*300) then begin       {faze animovaneho kurzoru}
             DrawFrame (x,y,cursor,TRANS_COPY_PUT,true);
             phase:=0;
           end else DrawFrame (x,y,cursor,TRANS_COPY_PUT,false);
      end;
      if cursor.imgBegin^.Next<>nil then Inc (phase);
   end;

   procedure TMouseCursor.CleanCursor;
   begin
     DrawBImage (x,y,previmg,NormalPut);
   end;

   procedure TMouseCursor.ResetCursor;
   begin
     DisposeBImage (previmg);
     NewBImage (previmg);
     GetBImage (x,y,x+cursor.dx,y+cursor.dy,previmg);
   end;

   procedure TMouseCursor.ChangeCursor (curfile:string);
   begin
     DisposeAnim (cursor);
     LoadAnim (curfile,cursor); {nahrani kurzoru}
   end;

   destructor TMouseCursor.Done;
   begin
     DisposeBImage(previmg);
     DisposeAnim (cursor);
   end;

   constructor TButton.Init(x,y:integer;normimg,climg:string);
   begin
      clicked:=true;
      LoadBImage (normimg,imgNormal);
      LoadBImage (climg,imgClicked);
      TArea.Init (x,y,x+imgNormal.dx,y+imgNormal.dy);
      DrawBImage(x1,y1,imgNormal,TRANS_COPY_PUT);
   end;

   destructor TButton.Done;
   begin
     DisposeBImage(imgNormal);
     DisposeBImage(imgClicked);
   end;

   procedure TButton.DrawClicked;
   begin
     GlobalCursor^.CleanCursor;
     DrawBImage(x1,y1,imgClicked,TRANS_COPY_PUT);
     clicked:=true;
     GlobalCursor^.ResetCursor;
     GlobalCursor^.RedrawCursor(true);
     Delay (Round(slowdown*150));
     DrawNormal;
   end;

   procedure TButton.DrawNormal;
   begin
     GlobalCursor^.CleanCursor;
     DrawBImage(x1,y1,imgNormal,TRANS_COPY_PUT);
     GlobalCursor^.ResetCursor;
     GlobalCursor^.RedrawCursor(true);
     clicked:=false;
   end;

   procedure Draw3DBox (x1,y1,x2,y2:integer);
   begin
     SetColor (15);
     Rectangle (x1,y1,x2-1,y2-1);
     SetColor (8);
     Rectangle (x1+1,y1+1,x2,y2);
     SetColor (7);
     SetFillStyle (SolidFill,7);
     Bar (x1+1,y1+1,x2-1,y2-1);
   end;

   procedure Draw3DBox2 (x1,y1,x2,y2:integer);
   begin
     SetColor (8);
     Rectangle (x1,y1,x2-1,y2-1);
     SetColor (15);
     Rectangle (x1+1,y1+1,x2,y2);
     SetColor (7);
     SetFillStyle (SolidFill,7);
     Bar (x1+1,y1+1,x2-1,y2-1);
   end;

   constructor TTextArea.Init(x,y,dx:integer;txt:string);
   var code:integer;
   begin
     TArea.Init (x,y,dx,y+18);
     text:=txt;
     intonly:=false;
     Redraw;
   end;

   destructor TTextArea.Done;
   begin
     GlobalCursor^.ChangeCursor ('cursors\pointer.gnm');
   end;

   procedure TTextArea.Edit;         {editace textoveho pole}
   var key:word;
       flags:byte;
       eend:byte;
       first:boolean;
       ssave:string;
       i,clen,mlen:integer;
       b,e:byte;
   begin
     GlobalCursor^.CleanCursor;
     SetViewPort (x1+2,y1+2,x2-2,y2-2,ClipOn);
     key:=0;
     eend:=0;
     ssave:=text;
     first:=true;
     repeat
       if keypressed then Keystroke(key,flags);
       case key of
          283:eend:=1;                   {ESC - zrusi a necha puvodni hodnotu}
          3592:begin                                {Backspace - zpet o jeden znak}
                 text:=Copy(text,1,length(text)-1);
                 first:=true;
               end;
          7181:eend:=2;   {ENTER - potvrzeni zmeny}
       end;
       if first or (((Lo(key)>31)) and ((not intonly) or ((Lo(key)>47) and (Lo(key)<58)))) then begin   {Pise text?}
          if (length(text)<=254) and not first then text:=text+Chr(Lo(key)); {omezeni delky}
          SetColor (255);
          SetFillStyle (SolidFill,15);
          Bar (0,0,abs(x1-x2),abs(y1-y2));
          if length(text)>0 then clen:=length(text)*(TextWidth('X')) div length(text) else clen:=1;
          mlen:=(abs(x2-x1) div clen);
                                {vejde se na zacatek nebo posune text}
          if length(text)+clen>=mlen+1 then b:=length(text)+clen-mlen else b:=1;
          e:=length(text);
          i:=0;
          for i:=0 to e-b do begin
             OutTextXY (2+((i)*(clen)),1,text[b+i]);
          end;
          SetColor (13);
          OutTextXY (2+((i+1)*(clen)),1,'_'); {"kurzor"}
          SetColor (255);
          first:=false;
       end;
       key:=0;
     until eend<>0;
     SetViewPort (0,0,GetMaxX,GetMaxY,ClipOn);
     if eend=1 then text:=ssave;
     GlobalCursor^.ResetCursor;
     GlobalCursor^.RedrawCursor(true);
     Redraw;
   end;

   procedure TTextArea.Callbacker;
   var bx,by:integer;
       but:word;
       cb:word;
   begin
     if not enabled then exit;
     MouseStatus (bx,by,but); {zjisteni stavu mysi}
     cb:=0;
     {je-li mys uvnitr pasma, tak...}
     if (bx>=x1) and (bx<=x2) and (by>=y1) and (by<=y2) then begin
        if (bx<>px) or (by<>py) then begin {pohnula-li se mys}
           px:=bx;
           py:=by;
           GlobalCursor^.ChangeCursor ('cursors\icur.gnm'); {zmena kurzoru na I}
           repeat
             GlobalCursor^.RedrawCursor (false);
             MouseStatus (bx,by,but);
             cb:=but;
           until (cb<>0) or not ((bx>=x1) and (bx<=x2) and (by>=y1) and (by<=y2));
           GlobalCursor^.ChangeCursor ('cursors\pointer.gnm');
        end;
        {Stisklo-li se tlacitko}
        if (but<>0) and (px>=x1) and (px<=x2) and (py>=y1) and (py<=y2) then begin
           cb:=but;
           if cb=mbLeft then begin {spustit editaci}
              Edit;
              cb:=cbEdit;
           end;
        end;
     end;
     if (cb<>0) and (@callback<>nil) then callback(px,py,cb); {zavola udalostni proceduru}
   end;

   procedure TTextArea.ReDraw;
   var code:integer;
   begin
     GlobalCursor^.CleanCursor;
     Val (text,intval,code);
     Draw3DBox2 (x1,y1,x2,y2);
     SetFillStyle (SolidFill,15);
     Bar (x1+2,y1+2,x2-2,y2-2);
     SetViewPort (x1+2,y1+2,x2-2,y2-2,ClipOn);      {vykresleni text. pole}
     SetColor (255);
     OutTextXY (2,1,text);
     SetViewPort (0,0,GetMaxX,GetMaxY,ClipOn);
     GlobalCursor^.ResetCursor;
     GlobalCursor^.RedrawCursor(true);
   end;

   constructor TCheckButton.Init(x,y:integer;normimg,climg:string);
   begin
     TButton.Init (x,y,normimg,climg);
     checked:=false;
   end;

   procedure TCheckButton.Redraw;
   begin
     GlobalCursor^.CleanCursor;
     if checked then begin    {vykresli zmacknute nebo nezmacknute?}
        DrawBImage(x1,y1,imgClicked,TRANS_COPY_PUT);
        clicked:=true;
     end else DrawBImage(x1,y1,imgNormal,TRANS_COPY_PUT);
     GlobalCursor^.ResetCursor;
     GlobalCursor^.RedrawCursor(true);
   end;

   procedure TCheckButton.Callbacker;
   var bx,by:integer;
       but:word;
       cb:word;
   begin
     if not enabled then exit;
     MouseStatus (bx,by,but);
     cb:=0;
     if (bx>=x1) and (bx<=x1+imgNormal.dx) and (by>=y1) and (by<=y1+imgNormal.dy) then begin
        if (bx<>px) or (by<>py) then begin
           px:=bx;
           py:=by;
          cb:=mbMove;
        end;
        if (but<>0) and (px>=x1) and (px<=x2) and (py>=y1) and (py<=y2) then begin
          cb:=but;
          if But=mbLeft then begin
             if checked then checked:=false else checked:=true; {zatrhnuti}
             Redraw;
             delay(250);
          end;
        end;
     end;
     if (cb<>0) and (@callback<>nil) then callback(px,py,cb);
   end;

   destructor TCheckButton.Done;
   begin
     TButton.Done;
   end;

   constructor TContainer.Init;
   begin
     objBegin:=nil;
     objEnd:=nil;
   end;

   function TContainer.AddObject(name:string;typ:byte):PContObj;
   var tmpObj:PContObj;
   begin
     New (tmpObj);
     tmpObj^.Next:=nil;
     tmpObj^.name:=name;
     tmpObj^.typ:=typ;
     if objBegin=nil then begin                  {pridani}
        objBegin:=tmpObj;
        objEnd:=tmpObj;
     end else begin
        objEnd^.Next:=tmpObj;
        objEnd:=tmpObj;
     end;
     AddObject:=tmpObj;
   end;

   function TContainer.GetObject(name:string):PContObj;
   var tmpObj:PContObj;
   begin
     tmpObj:=objBegin;
     repeat
       if tmpObj^.name=name then break;
       tmpObj:=tmpObj^.Next;
     until tmpObj=nil;
     if tmpObj=nil then RunError (217);
     GetObject:=tmpObj;
   end;

   function TContainer.GetArea(name:string):PArea;
   begin
     GetArea:=TContainer.GetObject(name)^.obj;
   end;

   procedure TContainer.CallBacker;
   var tmpObj:PContObj;
   begin
     tmpObj:=objBegin;
     repeat
       tmpObj^.obj^.Callbacker;
       tmpObj:=tmpObj^.Next;
     until tmpObj=nil;
   end;

   procedure TContainer.Redraw;
   var tmpObj:PContObj;
   begin
     tmpObj:=objBegin;
     repeat
       tmpObj^.obj^.Redraw;
       tmpObj:=tmpObj^.Next;
     until tmpObj=nil;
   end;

   destructor TContainer.Done;
   var tmpObj:PContObj;
   begin
     if objBegin=nil then exit; {nic tam neni}
     repeat
       tmpObj:=objBegin;
       objBegin:=objBegin^.Next;
       case tmpObj^.typ of
          objArea:Dispose (tmpObj^.obj,Done);
          objButton:Dispose (PButton(tmpObj^.obj),Done);
          objChkButton:Dispose (PCheckButton(tmpObj^.obj),Done);
          objTxtArea:Dispose (PTextArea(tmpObj^.obj),Done);
       else RunError (217)
       end;
       Dispose (tmpObj);
     until objBegin=nil;
   end;

begin
end.