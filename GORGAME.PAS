unit GorGame;
interface
uses GorGraph,GorGUI;
  const mntMin=240;
        mntMax=253;
        mntPos=254;

  const wBanana=1;   {zbrane}
        wDynamite=2;
        wBBanana=3;
        wSBall=4;
        wDHead=5;

  const pl1col=199; {barvy hrace}
        pl2col=112;
        pl3col=111;
        pl4col=147;
  type
       PWeapon=^TWeapon;
       TWeapon=object  {objekt zbrane}
                 public
                   fx,fy:integer;   {pozice hrace, ktery strelu odpalil}
                   x1,y1,x2,y2:integer; {pozice animace}
                   Name:string;  {jmeno zbrane}
                   typ:byte; {typ zbrane}
                   Amount:byte;  {pocet strel}
                   Charge:word;  {sila zbrane}
                   ERange:real;  {dosah vybuchu}
                   Health:real; {zdravi zbrane-nevyuzito}
                   Speed:real; {rychlost strely}
                   Time:real;  {cas-udava pozici na krivce trajektorie}
                   Direction:word; {smer vystrelu}
                   dirt:boolean; {spinava zbran-vytvari hory}
                   color:word; {barva trajektorie}
                   Unlimited:boolean; {neomezene strelivo}
                   imgPrev:TImage; {predchozi obrazek pod animaci}
                   anmMove,anmExpl:TAnim; {animace pohybu a vybuchu}
                   {inicializace se soubory pro animaci pohybu a vybuchu}
                   constructor Init(movest,animst:string);
                   constructor Init2(var aMove,aExpl:TAnim);
                   {zasah zbrane-nevyuzito}
                   procedure Hit(amt:real);
                   procedure Explode; {vybuuuch}
                   procedure Move;  {pohyb}
                   procedure DrawMove; {vykresleni animace pohybu}
                   destructor Done; {uvolneni}
                   destructor Done2;
               end;

       PShield=^TShield; {nevyuzito}
       TShield=object

               end;
       PTgtnResult=^TTgtnResult;
       PPlayer=^TPlayer;
       TPlayer=object      {objekt hrace}
                 public
                    x1,y1,x2,y2:integer; {pozice hrace}
                    Name:string;         {jmeno}
                    Power:real;          {sila(rychlost) vystrelu}
                    Direction:integer;   {smer vystrelu}
                    Fuel:real;           {palivo-nevyuzito}
                    Strength:real;       {sila hrace-odolnost}
                    Health:real;         {zdravi}
                    color:word;          {barva}
                    CurWeapon,MaxWeapon:byte; {zvolena zbran, max. zbran}
                    Computer,IsALive:boolean; {je zivy}
                    Weapons: array[0..20] of PWeapon; {zbrane}
                    {CurShield,MaxShield:byte;
                    Shields: array[0..20] of PShield;}
                    imgPrev:TImage; {predchozi obrazek pod hracem}
                    anmNormal,anmThrowL,anmThrowR,anmWon,anmDie:TAnim; {animace}
                    LastResult:PTgtnResult;
                    constructor Init; {inicializace}
                    destructor Done;  {uvolneni}
                    procedure DrawNormal; {vykresleni normalniho hrace}
                    procedure DrawWin;    {vykresleni viteziciho hrace}
                    procedure DrawDie;    {vykresleni umirajiciho hrace}
                    procedure DrawThrowL; {vykresleni hodu vlevo}
                    procedure DrawThrowR; {vykresleni hodu vpravo}
                    procedure DrawHBar; {vykresleni listy zdravi}
                    procedure DrawTargeting; {vykresleni zamerovadla}
                    procedure AutoTarget; {pocitacove zamereni}
                    procedure Fall; {pad hrace}
                    procedure Hit(amount:real); {zasah hrace}
                    procedure Move(x,y:integer); {pohyb hrace na souradnice x,y}
                    procedure AddWeapon (l:word;amt:byte); {pridani zbrane}
                    procedure Fire; {vystrel}
                    procedure Clean; {prekresleni hrace obrazkem imgPrev}
                    procedure Talk(tlkfile,name2,name3:string); {"mluveni" pocitace}
                    procedure ResetPl; {znovu sejmuti obrazku imgPrev}
               end;

       TMountain=object
                    constructor Init(mntfile,bckfile:string); {inicializace hor, nacteni souboru hor a pozadi}
                    destructor Done; {uvolneni}
                    procedure Fall(x1,x2:integer); {pad hor od x1 do x2}
                    procedure FallDown (x,y1,y2:integer;first:boolean); {pad sloupce hory x od y1 do y2}
                 private
                    bckImg:TImage; {pozadi}
                 end;

       TTgtnResult=record {vyhodnoceni zamereni}
                     pl:PPlayer; {nejblizsi hrac, ktereho strela zasahne}
                     weap:PWeapon;
                     dist:real; {vzdalenost od hrace}
                     more:boolean; {zasahne vice hracu}
                     direction:word; {smer}
                     power:real;     {sila/rychlost}
                     wind:real; {vitr}
                     hit:real; {sila zasahu hrace}
                   end;

       TStartPos=record  {startovni pozice}
                   Players:byte;
                   Pos:array [1..10] of record
                       x,y:integer;
                       end;
                 end;

       procedure MainMenu; {Hlavni menu}
       procedure Setup; {Nastaveni}
       procedure StartGame; {Start hry}
       procedure DrawGameScene (mntfile,bckfile:string); {vykresleni prostredi hry}
       procedure PlaySound (hz,dur:word); {zvuk}
       procedure ClearKeyboardBuffer; {vymaze buffer klavesnice}
       function MainGameLoop:boolean; {Hlavni herni smycka}
       procedure EndGame; {konec hry}

var Mountain:TMountain; {globalni hory}
    StartPos:TStartPos; {globalni startovni pozice}
    players:array [1..10] of PPlayer; {globalni hraci}
    alive:shortint; {zivych hracu}
    humans:byte; {lidskych hracu}
    mcur:TMouseCursor; {globalni kursor}
    wind:real; {globalni vitr a gravitace}

implementation
uses Dos,Graph,crt;
{$I SVGAUTIL.INC}

type TConfigFile=record     {konfiguracni soubor}
     lowmem:boolean;
     slowdown:real;
     NTMouse:boolean;
     sound:boolean;
     drawpaths:boolean;
     maxwind,gravity:real;
     fallmnts,fallpls:boolean;
     plname1,plname2,plname3,plname4:string;
     plcomp1,plcomp2,plcomp3,plcomp4:boolean;
     comphum:boolean;
     talking:boolean;
     stamina:real;
     ndyn,nbban,nsbal:byte;
     numofpl:byte;
end;

type TAnimations=record        {typ pro nahrani animaci zbrani}
        anmExpl,anmMove:TAnim;
     end;

var bend:byte; {navratova hodnota}
    kend:byte; {navratova hodnota hlavniho menu}
    send:byte; {navratova hodnota nastaveni}
    actplayer:byte; {cislo souc. hrace}
    chfile1,chfile2:boolean;
    mrec,brec:SearchRec;
    ppl:PPlayer;
    cfg:TConfigFile;

var Animations:array [0..20] of TAnimations;

 {----Callback procs---}
             {$F+}
             procedure bYesCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then bend:=2;
             end;

             procedure bNoCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then bend:=1;
             end;

             procedure aWeapCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then begin
                 Inc (ppl^.CurWeapon);
                 if ((ppl^.MaxWeapon)<=(ppl^.CurWeapon)) then ppl^.CurWeapon:=0;
                 ppl^.DrawTargeting;
                 delay (500);
               end;
             end;

             procedure aPowrCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then ppl^.Power:=ppl^.Power+2 else
               if buttons=mbRight then ppl^.Power:=ppl^.Power-2;
               if (buttons=mbLeft) or (buttons=mbRight) then ppl^.DrawTargeting;
             end;

             procedure aDirCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then ppl^.Direction:=ppl^.Direction+2;
               if buttons=mbRight then ppl^.Direction:=ppl^.Direction-2;
               if (buttons=mbLeft) or (buttons=mbRight) then ppl^.DrawTargeting;
             end;

             procedure bStartCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then kend:=1;
             end;

             procedure bEndCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then kend:=3;
             end;

             procedure bSetupCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then kend:=2;
             end;

             procedure butOk1CB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then send:=2;
             end;

             procedure butCancel1CB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then send:=1;
             end;

             procedure butDefCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then send:=3;
             end;

             procedure butNextMCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then begin
                  chfile1:=true;
                  FindNext (mrec);
                  if DosError<>0 then FindFirst ('mnts\*.mnt',AnyFile,mrec);
               end;
             end;

             procedure butNextBCB(x,y:integer;buttons:word);
             begin
               if buttons=mbLeft then begin
                  chfile2:=true;
                  FindNext (brec);
                  if DosError<>0 then FindFirst ('bkgs\*.bck',AnyFile,brec);
               end;
             end;

             {$F-}

 {----End of callback procs---}

       procedure ClearKeyboardBuffer;
       var Regs:registers;
       begin
         Regs.AH:=$0C;
         Regs.AL:=$00;
         Intr ($21,Regs);
       end;

       procedure SaveCfg(default:boolean);
       var f:file;
           NumWrite:word;
       begin
         Assign (f,'gorillas.cfg');
         Rewrite (f,1);
         if default then
            with cfg do begin
              lowmem:=false;
              slowdown:=1;
              NTMouse:=false;
              sound:=true;
              maxwind:=2;
              gravity:=1;
              stamina:=1;
              fallmnts:=true;
              fallpls:=true;
              plname1:='Hr†ü1';
              plname2:='Hr†ü2';
              plname3:='Hr†ü3';
              plname4:='Hr†ü4';
              plcomp1:=false;
              plcomp2:=true;
              plcomp3:=true;
              plcomp4:=true;
              comphum:=true;
              talking:=true;
              ndyn:=2;
              nbban:=3;
              nsbal:=5;
              numofpl:=2;
         end;
         BlockWrite (f,cfg,SizeOf(cfg),NumWrite);
         Close (f);
       end;

       procedure LoadCfg;
       var f:file;
           NumRead:word;
       begin
         if FSearch ('gorillas.cfg','')='' then SaveCfg(true);
         Assign (f,'gorillas.cfg');
         Reset (f,1);
         BlockRead (f,cfg,SizeOf(cfg),NumRead);
         if (MaxAvail div 1024)<410 then cfg.lowmem:=true;
         Close (f);
         slowdown:=cfg.slowdown;
         NTMouse:=cfg.NTMouse;
       end;

       procedure MainMenu;
       var Cont:TContainer;
           dx,dy:integer;
           key:word;
           flags:byte;
       begin
         LoadCfg;
         DrawGIM (0,0,'images\gorily.gim',dx,dy,NormalPut);
         SetColor (14);
         OutTextXY (20,GetMaxY-35,'Verze: 1.1');
         OutTextXY (15,GetMaxY-25,'Vojtÿch S†zel');
         OutTextXY (GetMaxX-70,2,SStr(MaxAvail div 1024)+'kB volno');
         if cfg.lowmem then OutTextXY (GetMaxX-100,15,'Reßim malÇ pamÿti');
         kend:=0;
         mcur.ResetCursor;
         Cont.Init;
         New(PButton(Cont.AddObject('butNew',objButton)^.obj),Init (80,122,'images\start.gim','images\start2.gim'));
         New(PButton(Cont.AddObject('butSet',objButton)^.obj),Init (80,222,'images\set.gim','images\set2.gim'));
         New(PButton(Cont.AddObject('butEnd',objButton)^.obj),Init (60,322,'images\end.gim','images\end2.gim'));
         Cont.GetArea('butNew')^.callback:=bStartCB;
         Cont.GetArea('butSet')^.callback:=bSetupCB;
         Cont.GetArea('butEnd')^.callback:=bEndCB;
         key:=0;
         mcur.ResetCursor;
         mcur.RedrawCursor (true);
         repeat
           if keypressed then KeyStroke(key,flags);
           Cont.callbacker;
           case key of
             283,9579,9547:kend:=3;
             8051,8019:kend:=1;
             12622,12654:kend:=2;
           end;
           key:=0;
           mcur.RedrawCursor (false);
         until kend<>0;
         mcur.CleanCursor;
         Cont.Done;
         case kend of
            2:begin
                Setup;
                MainMenu;
              end;
            1:begin
                StartGame;
                MainMenu;
              end;
            3:exit;
         end;
       end;

       procedure Setup;
       var Cont:TContainer;
           hx,hy,gx,gy:integer;
           key:word;
           flags:byte;
       begin
         gx:=320;
         gy:=200;
         hx:=(GetMaxX-gx) div 2;
         hy:=(GetMaxY-gy) div 2;
         Draw3DBox (hx,hy,hx+gx,hy+gy);
         mcur.ResetCursor;
         Cont.Init;
         New(PButton(Cont.AddObject('butOk',objButton)^.obj),
             Init (hx+10,hy+gy-40,'images\ok.gim','images\ok2.gim'));
         New (PButton(Cont.AddObject('butCancel',objButton)^.obj),
             Init (hx+gx-90,hy+gy-40,'images\storno.gim','images\storno2.gim'));
         New (PButton(Cont.AddObject('butDef',objButton)^.obj),
             Init (((2*hx+gx) div 2)-40,hy+gy-40,'images\def.gim','images\def2.gim'));
         New (PCheckButton(Cont.AddObject('chkLowMem',objChkButton)^.obj),
             Init (hx+20,hy+20,'images\chk.gim','images\chk2.gim'));
         New (PCheckButton(Cont.AddObject('chkNTM',objChkButton)^.obj),
             Init (hx+20,hy+40,'images\chk.gim','images\chk2.gim'));
         New (PCheckButton(Cont.AddObject('chkSound',objChkButton)^.obj),
             Init (hx+20,hy+60,'images\chk.gim','images\chk2.gim'));
         New (PTextArea(Cont.AddObject('ttSlowdown',objTxtArea)^.obj),
             Init (hx+80,hy+80,hx+130,SStr(Round(cfg.slowdown*100))));
         PTextArea(Cont.GetArea('ttSlowdown'))^.intonly:=true;
         PCheckButton(Cont.GetArea('chkLowMem'))^.checked:=cfg.lowmem;
         PCheckButton(Cont.GetArea('chkLowMem'))^.Redraw;
         PCheckButton(Cont.GetArea('chkNTM'))^.checked:=cfg.NTMouse;
         PCheckButton(Cont.GetArea('chkNTM'))^.Redraw;
         PCheckButton(Cont.GetArea('chkSound'))^.checked:=cfg.sound;
         PCheckButton(Cont.GetArea('chkSound'))^.Redraw;
         mcur.CleanCursor;
         OutTextXY (hx+40,hy+20,'Reßim malÇ pamÿti');
         OutTextXY (hx+40,hy+40,'Oprava myÁi ve Windows NT');
         OutTextXY (hx+40,hy+60,'Zvuk na PC Speakeru');
         OutTextXY (hx+20,hy+85,'Zpomalen°           %');
         OutTextXY (hx+20,hy+105,'50%-rychlejÁ° 100%-norm†ln° 150%-pomalejÁ°');
         Cont.GetArea('butOk')^.callback:=butOk1CB;
         Cont.GetArea('butCancel')^.callback:=butCancel1CB;
         Cont.GetArea('butDef')^.callback:=butDefCB;
         send:=0;
         mcur.ResetCursor;
         mcur.RedrawCursor(true);
         repeat
           Cont.callbacker;
           if keypressed then KeyStroke(key,flags);
           case key of
             283:send:=1;
             7181:send:=2;
           end;
           key:=0;
           mcur.RedrawCursor(false);
         until send<>0;
         mcur.CleanCursor;
         with cfg do begin
           lowmem:=PCheckButton(Cont.GetArea('chkLowMem'))^.checked;
           sound:=PCheckButton(Cont.GetArea('chkSound'))^.checked;
           NTMouse:=PCheckButton(Cont.GetArea('chkNTM'))^.checked;
           slowdown:=PTextArea(Cont.GetArea('ttSlowdown'))^.intval/100;
         end;
         Cont.Done;
         if send=2 then SaveCfg(false);
         if send=3 then SaveCfg(true);
       end;

       procedure LoadAnimations;
       begin
         LoadAnim ('images\banan.gnm',Animations[wBanana].anmMove);
         LoadAnim ('images\bexpl.gnm',Animations[wBanana].anmExpl);
         LoadAnim ('images\dynam.gnm',Animations[wDynamite].anmMove);
         LoadAnim ('images\dexpl.gnm',Animations[wDynamite].anmExpl);
         LoadAnim ('images\canan.gnm',Animations[wBBanana].anmMove);
         LoadAnim ('images\cexpl.gnm',Animations[wBBanana].anmExpl);
         LoadAnim ('images\sball.gnm',Animations[wSBall].anmMove);
         LoadAnim ('images\sexpl.gnm',Animations[wSBall].anmExpl);
         LoadAnim ('images\dhead.gnm',Animations[wDHead].anmMove);
         LoadAnim ('images\hexpl.gnm',Animations[wDHead].anmExpl);
       end;

       procedure DisposeAnimations;
       var i:integer;
       begin
         for i:=0 to 20 do begin
           DisposeAnim (Animations[i].anmMove);
           DisposeAnim (Animations[i].anmExpl);
         end;
       end;


       procedure InitPl (num:byte;images:string;var player:PPlayer);
       var pl:PPlayer;
           i:integer;
       begin
         New (pl,Init);
         with pl^ do begin
           LoadAnim (images+'d.gnm',anmDie);
           LoadAnim (images+'l.gnm',anmThrowL);
           LoadAnim (images+'r.gnm',anmThrowR);
           LoadAnim (images+'n.gnm',anmNormal);
           LoadAnim (images+'w.gnm',anmWon);
           x1:=StartPos.Pos[num].x;
           y1:=StartPos.Pos[num].y-anmNormal.dy;
           x2:=x1+anmNormal.dx;
           y2:=y1+anmNormal.dy;
           NewBImage (imgPrev);
           GetBImage (x1+3,y1+29,x2+3,y2+29,imgPrev);
         end;
         i:=1;
         while (Players[i]<>nil) do Inc(i);
         Players[i]:=pl;
         Inc(alive);
         player:=pl;
         pl^.color:=9+i;
         pl^.DrawNormal;
       end;

       procedure StartGame;
       var Cont:TContainer;
           hx,hy,gx,gy:integer;
           key:word;
           flags:byte;
           i:integer;
           pl1,pl2,pl3,pl4:PPlayer;
       begin
         gx:=400;
         gy:=400;
         hx:=(GetMaxX-gx) div 2;
         hy:=(GetMaxY-gy) div 2;
         FindFirst ('mnts\*.mnt',AnyFile,mrec);
         FindFirst ('bkgs\*.bck',AnyFile,brec);
         Draw3DBox (hx,hy,hx+gx,hy+gy);
         mcur.ResetCursor;
         chfile1:=false;
         chfile2:=false;
         Cont.Init;
         with cfg do begin
         New(PButton(Cont.AddObject('butOk',objButton)^.obj),
            Init (hx+60,hy+gy-40,'images\ok.gim','images\ok2.gim'));
         New(PButton(Cont.AddObject('butCancel',objButton)^.obj),
            Init (hx+gx-140,hy+gy-40,'images\storno.gim','images\storno2.gim'));
         New(PTextArea(Cont.AddObject('ttNumPl',objTxtArea)^.obj),
            Init (hx+90,hy+35,hx+150,SStr(cfg.numofpl)));
         New(PTextArea(Cont.AddObject('ttPl1',objTxtArea)^.obj),
            Init (hx+60,hy+57,hx+130,plname1));
         New(PTextArea(Cont.AddObject('ttPl2',objTxtArea)^.obj),
            Init (hx+60,hy+77,hx+130,plname2));
         New(PTextArea(Cont.AddObject('ttPl3',objTxtArea)^.obj),
            Init (hx+60,hy+97,hx+130,plname3));
         New(PTextArea(Cont.AddObject('ttPl4',objTxtArea)^.obj),
            Init (hx+60,hy+117,hx+130,plname4));
         New(PCheckButton(Cont.AddObject('chkCPl1',objChkButton)^.obj),
            Init (hx+gx-265,hy+60,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkCPl2',objChkButton)^.obj),
            Init (hx+gx-265,hy+80,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkCPl3',objChkButton)^.obj),
            Init (hx+gx-265,hy+100,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkCPl4',objChkButton)^.obj),
            Init (hx+gx-265,hy+120,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkDrPth',objChkButton)^.obj),
            Init (hx+gx-200,hy+60,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkFallMt',objChkButton)^.obj),
            Init (hx+gx-200,hy+80,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkFallPl',objChkButton)^.obj),
            Init (hx+gx-200,hy+100,'images\chk.gim','images\chk2.gim'));
         New(PCheckButton(Cont.AddObject('chkCompHum',objChkButton)^.obj),
            Init (hx+gx-200,hy+120,'images\chk.gim','images\chk2.gim'));
         {New(PCheckButton(Cont.AddObject('chkTalking',objChkButton)^.obj),
            Init (hx+gx-200,hy+140,'images\chk.gim','images\chk2.gim'));   }
         New(PTextArea(Cont.AddObject('ttMaxWind',objTxtArea)^.obj),
            Init (hx+100,hy+177,hx+170,SStr(Round(maxwind*100))));
         New(PTextArea(Cont.AddObject('ttGrav',objTxtArea)^.obj),
            Init (hx+100,hy+197,hx+170,SStr(Round(gravity*100))));
         New(PTextArea(Cont.AddObject('ttStam',objTxtArea)^.obj),
            Init (hx+100,hy+217,hx+170,SStr(Round(stamina*100))));
         New(PTextArea(Cont.AddObject('ttMnt',objTxtArea)^.obj),
            Init (hx+100,hy+237,hx+170,mrec.name));
         New(PTextArea(Cont.AddObject('ttBkg',objTxtArea)^.obj),
            Init (hx+100,hy+257,hx+170,brec.name));
         New(PButton(Cont.AddObject('butNextM',objButton)^.obj),
            Init (hx+172,hy+237,'images\next.gim','images\next2.gim'));
         New(PButton(Cont.AddObject('butNextB',objButton)^.obj),
            Init (hx+172,hy+257,'images\next.gim','images\next2.gim'));
         New(PTextArea(Cont.AddObject('ttDynam',objTxtArea)^.obj),
            Init (hx+gx-100,hy+177,hx+gx-30,SStr(cfg.ndyn)));
         New(PTextArea(Cont.AddObject('ttBigB',objTxtArea)^.obj),
            Init (hx+gx-100,hy+197,hx+gx-30,SStr(cfg.nbban)));
         New(PTextArea(Cont.AddObject('ttSnowB',objTxtArea)^.obj),
            Init (hx+gx-100,hy+217,hx+gx-30,SStr(cfg.nsbal)));
         PTextArea(Cont.GetArea('ttNumPl'))^.intonly:=true;
         PTextArea(Cont.GetArea('ttMaxWind'))^.intonly:=true;
         PTextArea(Cont.GetArea('ttGrav'))^.intonly:=true;
         PTextArea(Cont.GetArea('ttStam'))^.intonly:=true;
         Cont.GetArea('butNextM')^.callback:=butNextMCB;
         Cont.GetArea('butNextB')^.callback:=butNextBCB;
         Cont.GetArea('butOk')^.callback:=butOk1CB;
         Cont.GetArea('butCancel')^.callback:=butCancel1CB;
         PTextArea(Cont.GetArea('ttDynam'))^.intonly:=true;
         PTextArea(Cont.GetArea('ttBigB'))^.intonly:=true;
         PTextArea(Cont.GetArea('ttSnowB'))^.intonly:=true;
         PCheckButton(Cont.GetArea('chkDrPth'))^.checked:=drawpaths;
         PCheckButton(Cont.GetArea('chkFallMt'))^.checked:=fallmnts;
         PCheckButton(Cont.GetArea('chkFallPl'))^.checked:=fallpls;
         PCheckButton(Cont.GetArea('chkCPl1'))^.checked:=plcomp1;
         PCheckButton(Cont.GetArea('chkCPl2'))^.checked:=plcomp2;
         PCheckButton(Cont.GetArea('chkCPl3'))^.checked:=plcomp3;
         PCheckButton(Cont.GetArea('chkCPl4'))^.checked:=plcomp4;
         PCheckButton(Cont.GetArea('chkCompHum'))^.checked:=comphum;
{         PCheckButton(Cont.GetArea('chkTalking'))^.checked:=talking;}
         Cont.Redraw;
         end;
         mcur.CleanCursor;
         SetColor (47);
         OutTextXY (hx+20,hy+20,'Hr†üi:');
         SetColor (255);
         OutTextXY (hx+20,hy+40,'Poüet hr†üÖ             (2-4)');
         SetColor (pl1col);
         OutTextXY (hx+20,hy+60,'Hr†ü 1');
         SetColor (pl2col);
         OutTextXY (hx+20,hy+80,'Hr†ü 2');
         SetColor (pl3col);
         OutTextXY (hx+20,hy+100,'Hr†ü 3');
         SetColor (pl4col);
         OutTextXY (hx+20,hy+120,'Hr†ü 4');
         SetColor (255);
         OutTextXY (hx+gx-180,hy+60,'Vykreslovat trajektorii');
         OutTextXY (hx+gx-180,hy+80,'Padaj°c° hory');
         OutTextXY (hx+gx-180,hy+100,'Padaj°c° gorily');
         OutTextXY (hx+gx-250,hy+60,'Poü°taü');
         OutTextXY (hx+gx-250,hy+80,'Poü°taü');
         OutTextXY (hx+gx-250,hy+100,'Poü°taü');
         OutTextXY (hx+gx-250,hy+120,'Poü°taü');
         OutTextXY (hx+gx-180,hy+120,'Poü°taüe proti lidem');
         SetColor (47);
         OutTextXY (hx+20,hy+160,'Parametry hry:');
         OutTextXY (hx+gx-200,hy+160,'Zbranÿ goril:');
         SetColor (255);
         OutTextXY (hx+20,hy+180,'Maxim†ln° v°tr');
         OutTextXY (hx+20,hy+200,'Gravitace                 %');
         OutTextXY (hx+20,hy+220,'Odolnost goril            %');
         OutTextXY (hx+20,hy+240,'Hory');
         OutTextXY (hx+20,hy+260,'Pozad°');
         OutTextXY (hx+gx-200,hy+180,'Dynamit');
         OutTextXY (hx+gx-200,hy+200,'VelkÏ ban†n');
         OutTextXY (hx+gx-200,hy+220,'"Snÿhov†" koule');
         send:=0;
         mcur.ResetCursor;
         mcur.RedrawCursor(true);
         repeat
           Cont.Callbacker;
           if chfile1 then begin
              PTextArea(Cont.GetArea('ttMnt'))^.text:=mrec.name;
              PTextArea(Cont.GetArea('ttMnt'))^.Redraw;
              chfile1:=false;
           end;
           if chfile2 then begin
              PTextArea(Cont.GetArea('ttBkg'))^.text:=brec.name;
              PTextArea(Cont.GetArea('ttBkg'))^.Redraw;
              chfile2:=false;
           end;
           if ((PTextArea(Cont.GetArea('ttNumPl'))^.intval<2) or (PTextArea(Cont.GetArea('ttNumPl'))^.intval>4)) then begin
              PTextArea(Cont.GetArea('ttNumPl'))^.text:='2';
              PTextArea(Cont.GetArea('ttNumPl'))^.Redraw;
           end;
           if keypressed then KeyStroke(key,flags);
           case key of
             283:send:=1;
             7181:send:=2;
           end;
           key:=0;
           mcur.RedrawCursor(false);
         until send<>0;
         with cfg do begin
           fallmnts:=PCheckButton(Cont.GetArea('chkFallMt'))^.checked;
           fallpls:=PCheckButton(Cont.GetArea('chkFallPl'))^.checked;
           drawpaths:=PCheckButton(Cont.GetArea('chkDrPth'))^.checked;
           plname1:=PTextArea(Cont.GetArea('ttPl1'))^.text;
           plname2:=PTextArea(Cont.GetArea('ttPl2'))^.text;
           plname3:=PTextArea(Cont.GetArea('ttPl3'))^.text;
           plname4:=PTextArea(Cont.GetArea('ttPl4'))^.text;
           plcomp1:=PCheckButton(Cont.GetArea('chkCPl1'))^.checked;
           plcomp2:=PCheckButton(Cont.GetArea('chkCPl2'))^.checked;
           plcomp3:=PCheckButton(Cont.GetArea('chkCPl3'))^.checked;
           plcomp4:=PCheckButton(Cont.GetArea('chkCPl4'))^.checked;
{           talking:=PCheckButton(Cont.GetArea('chkTalking'))^.checked;}
           comphum:=PCheckButton(Cont.GetArea('chkCompHum'))^.checked;
           gravity:=PTextArea(Cont.GetArea('ttGrav'))^.intval/100;
           maxwind:=PTextArea(Cont.GetArea('ttMaxWind'))^.intval/100;
           stamina:=PTextArea(Cont.GetArea('ttStam'))^.intval/100;
           mcur.CleanCursor;
           numofpl:=PTextArea(Cont.GetArea('ttNumPl'))^.intval;
           ndyn:=PTextArea(Cont.GetArea('ttDynam'))^.intval;
           nbban:=PTextArea(Cont.GetArea('ttBigB'))^.intval;
           nsbal:=PTextArea(Cont.GetArea('ttSnowB'))^.intval;
         end;
         alive:=0;
         Cont.Done;
         if send=2 then begin
            SaveCfg(false);
            ClearDevice;
            LoadAnimations;
            DrawGameScene('mnts\'+mrec.name,
                         'bkgs\'+brec.name);
            for i:=1 to 10 do Players[i]:=nil;
            InitPl (1,'images\gor1',pl1);
            InitPl (4,'images\gor2',pl2);
            pl1^.Fall;
            pl1^.color:=pl1Col;
            pl1^.Name:=cfg.plname1;
            pl1^.Computer:=cfg.plcomp1;
            pl2^.Fall;
            pl2^.Computer:=cfg.plcomp2;
            pl2^.color:=pl2Col;
            pl2^.Name:=cfg.plname2;
            if cfg.numofpl>2 then begin
               InitPl (2,'images\gor3',pl3);
               pl3^.Fall;
               pl3^.Computer:=cfg.plcomp3;
               pl3^.color:=pl3Col;
               pl3^.Name:=cfg.plname3;
            end;
            if cfg.numofpl>3 then begin
               InitPl (3,'images\gor4',pl4);
               pl4^.Fall;
               pl4^.Computer:=cfg.plcomp4;
               pl4^.color:=pl4Col;
               pl4^.Name:=cfg.plname4;
            end;
            humans:=0;
            for i:=1 to cfg.numofpl do begin
               Players[i]^.strength:=cfg.stamina;
               Players[i]^.AddWeapon (wBanana,0);
               if not Players[i]^.computer then Inc(humans);
               if Random(25)=1 then begin
                  Players[i]^.AddWeapon (wDHead,1);
                  PlaySound (100,100);
                  PlaySound (50,50);
                  PlaySound (40,200);
               end;
               if cfg.ndyn>0 then
                 Players[i]^.AddWeapon (wDynamite,cfg.ndyn);
               if cfg.nbban>0 then
                  Players[i]^.AddWeapon (wBBanana,cfg.nbban);
               if cfg.nsbal>0 then
                  Players[i]^.AddWeapon (wSBall,cfg.nsbal);
            end;
            actplayer:=1;
            mcur.ResetCursor;
            MainGameLoop;
            DisposeAnimations;
            EndGame;
         end;
       end;

       procedure DrawGameScene (mntfile,bckfile:string);
       var dx,dy:integer;
           i:integer;
       begin
         SetColor (15);
         Rectangle (0,26,GetMaxX,GetMaxY);
         Rectangle (2,28,GetMaxX-2,GetMaxY-2);
         Draw3DBox (0,0,GetMaxX,25);
         SetColor (15);
         Mountain.Init (mntfile,bckfile);
         StartPos.Players:=0;
       end;

       function IsMountain(c:word):boolean;
       begin
         if (c>=mntMin) and (c<=mntMax) then IsMountain:=true else IsMountain:=false;
       end;


       constructor TPlayer.Init;
       var i:integer;
       begin
         Health:=100;
         Power:=500;
         Direction:=45;
         Computer:=false;
         CurWeapon:=0;
         MaxWeapon:=0;
         Strength:=1;
         IsAlive:=true;
         Name:='';
         LastResult:=nil;
         for i:=0 to 20 do Weapons[i]:=nil;
       end;

       destructor TPlayer.Done;
       var i:integer;
       begin
         i:=0;
         if LastResult<>nil then Dispose(LastResult);
         DisposeBImage (imgPrev);
         DisposeAnim (anmNormal);
         DisposeAnim (anmThrowL);
         DisposeAnim (anmThrowR);
         DisposeAnim (anmDie);
         DisposeAnim (anmWon);
         for i:=0 to 20 do if Weapons[i]<>nil then Dispose(Weapons[i],Done2);
       end;

       procedure TPlayer.DrawNormal;
       begin
         if IsAlive then begin
            DrawFrame (x1+3,y1+29,anmNormal,TRANS_COPY_PUT,true);
            DrawHBar;
         end;
       end;

       procedure TPlayer.DrawWin;
       var i:integer;
       begin
         if IsAlive then begin
            for i:=1 to 5 do begin
               Clean;
               DrawFrame (x1+3,y1+29,anmWon,TRANS_COPY_PUT,true);
               PlaySound (100,50);
               delay (Round(slowdown*500));
            end;
         end;
       end;

       procedure TPlayer.DrawThrowL;
       begin
         if IsAlive then DrawFrame (x1+3,y1+29,anmThrowL,TRANS_COPY_PUT,true);
       end;

       procedure TPlayer.DrawThrowR;
       begin
         if IsAlive then DrawFrame (x1+3,y1+29,anmThrowR,TRANS_COPY_PUT,true);
       end;

       procedure TPlayer.DrawHBar;
       begin
         if not IsAlive then exit;
         SetColor (15);
         SetFillStyle (SolidFill,255);
         Bar (x1+5,y1+29,x1+22+5,y1+5+29);
         Rectangle (x1+5,y1+29,x1+22+5,y1+5+29);
         if Health>=80 then SetFillStyle (SolidFill,97);
         if Health<80 then SetFillStyle (SolidFill,195);
         if Health<50 then SetFillStyle (SolidFill,194);
         if Health<25 then SetFillStyle (SolidFill,147);
         Bar (x1+1+5,y1+1+29,x1+1+(Round(Health) div 10*2)+5,y1+4+29);
       end;

       procedure TPlayer.Talk(tlkfile,name2,name3:string);
       var f:text;
           i,count:byte;
           mes:string;
       begin
         Assign (f,tlkfile);
         Reset(f);
         readln (f,count);
         i:=1;
         While (not eof(f)) and (i<>count) do begin
           readln (f,mes);
           Inc(i);
         end;
         Close (f);

       end;

       procedure TPlayer.DrawTargeting;
       var hx,hy:integer;
           dir:word;
           li:LineSettingsType;
       begin
         if not IsAlive then exit;
         PlaySound (1000,1);
         hx:=((x1+x2) div 2)+3;
         hy:=((y1+y2) div 2)+29+2;
         SetFillStyle (SolidFill,7);
         Bar(10,5,100,24);
         Bar(130,5,630,21);
{        Bar(365,5,450,21);
         Bar(540,5,620,21);}
         SetColor(255);
         if Direction<0 then Direction:=359;
         if Direction>359 then Direction:=0;
         if Power>1000 then Power:=0;
         if Power<0 then Power:=1000;
         OutTextXY(10,3,'V°tr:');
         if (abs(wind)<=0.2) then SetFillStyle (SolidFill,101);
         if (abs(wind)>0.2) and (abs(wind)<=1.5) then SetFillStyle (SolidFill,194);
         if (abs(wind)>1.5) then SetFillStyle (SolidFill,147);
         Bar(50,17,50-Round(wind*10),23);
         line (50,15,50,25);
         OutTextXY(135,9,'ZbraÂ:');
         if (Weapons[curWeapon]^.Amount=0) and not Weapons[curWeapon]^.Unlimited then
                                               SetColor (12) else SetColor(255);
         if Weapons[curWeapon]^.Unlimited then
                OutTextXY(185,9, Weapons[curWeapon]^.Name+' (*)') else
                OutTextXY(185,9, Weapons[curWeapon]^.Name+' ('+SStr(Weapons[curWeapon]^.Amount)+')');
         SetColor (255);
         OutTextXY(305,9,'Smÿr:');
         OutTextXY(400,9,'S°la:');
         SetFillStyle (SolidFill,89);
         SetColor (89);
         PieSlice (hx,hy,0,360,9);
         if (Direction>=225) and (Direction<=315) then SetColor(147) else SetColor (142);
         OutTextXY(365,9,SStr(Direction));
         PieSlice (hx,hy,Direction,Direction+1,9);
         GetLineSettings (li);
         SetLineStyle(SolidLn,0,3);
         if (Power<200) then SetColor (147);
         if (Power>=200) and (Power<=800) then SetColor(101);
         if (Power>800) then SetColor(142);
         OutTextXY(460,9,SStr(Round(Power)));
         Arc (hx,hy,0,Round(0.36*Power),7);
         SetLineStyle(li.LineStyle, li.Pattern, li.Thickness);
         SetColor (color);
         Circle (hx,hy,9);
         OutTextXY(520,9,name);
         mcur.CleanCursor;
         mcur.ResetCursor;
         mcur.RedrawCursor(true);
       end;

      procedure TPlayer.AutoTarget;
        procedure SetDirection(dir:word);
        var i:integer;
            j:word;
        begin
          j:=Direction;
          i:=j;
          if dir>j then
             while i<dir do begin
               Direction:=i;
               if i<dir then DrawTargeting;
               Inc (i,10);
             end else
             while i>dir do begin
               Direction:=i;
               if i>dir then DrawTargeting;
               Dec (i,10);
             end;
         Direction:=dir;
         DrawTargeting;
        end;

        procedure SetPower(pow:real);
        var r:real;
            i:integer;
            j:word;
        begin
          j:=Round(Power);
          i:=j;
          if pow>j then
             while i<Round(pow) do begin
               Power:=i;
               if i<Round(pow) then DrawTargeting;
               Inc(i,10);
             end else
             while i>Round(pow) do begin
               Power:=i;
               if i>Round(pow) then DrawTargeting;
               Dec(i,10);
             end;
        end;

        procedure SetWeapon (num:byte);
        var b:byte;
        begin
          b:=num;
          repeat
           Inc (CurWeapon);
           if CurWeapon>=MaxWeapon then CurWeapon:=0;
           DrawTargeting;
          until (Weapons[CurWeapon]^.typ=b);
         end;

         procedure TestPath;
         var tx1,tx2,ty1,ty2:integer;
             time:real;
             lpl,pl:PPlayer;
           function IsHit:boolean;
           var gx,gy:integer;
               mx,my:integer;
               fx,fy:integer;
               ht:real;
               i:byte;
               c:word;
           begin
             gx:=(tx1+tx2) div 2;
             gy:=(ty1+ty2) div 2;
             IsHit:=false;
             if (tx1<0) or (tx1>(GetMaxX-3)) or (ty2>(GetMaxY-29)) then begin
               IsHit:=true;
               exit;
              end;
             i:=1;
             pl:=Players[i];
             while not((time<2.0) or (i>10) or (pl=nil)) do begin
               if ((pl^.x1<gx) and (gx<pl^.x2)) and ((pl^.y1<gy) and (gy<pl^.y2)) and (pl^.IsAlive) then begin
                 IsHit:=true;
                 exit;
               end;
               Inc(i);
               pl:=Players[i];
             end;
             if (ty1<0) then exit;
             gx:=tx1;
             gy:=ty1;
             repeat
               c:=GetPixel (gx+3,gy+29);
               Inc (gx);
               if gx>=tx2 then begin
                  Inc(gy);
                  gx:=tx1;
               end;
             until ((gy>ty2) or IsMountain(c));
             if IsMountain(c) then IsHit:=true else IsHit:=false;
         end;

      var koz,syn,deg:real;
          len:real;
          hx,hy:integer;
          fx,fy:integer;
          gx,gy:integer;
          i,j:integer;

      begin
        lpl:=LastResult^.pl;
        LastResult^.pl:=nil;
        if (LastResult^.weap=nil) or ((LastResult^.weap^.amount=0) and
                 not LastResult^.weap^.unlimited) then exit;
        fx:=((x1+x2) div 2);
        fy:=((y1+y2) div 2);
        time:=0;
        repeat
           time:=time+1;
           if LastResult^.Direction=0 then begin
              koz:=1;
              syn:=0;
           end else begin
             koz:=cos(-(Pi/180)*LastResult^.Direction);
             syn:=sin(-(Pi/180)*LastResult^.Direction);
           end;
           tx1:=fx+Round(((LastResult^.power/30)*time)*koz-0.05*wind*Sqr(time));
           ty1:=fy+Round(((LastResult^.power/30)*time)*syn+0.5*cfg.gravity*Sqr(time));
           tx2:=tx1+LastResult^.weap^.anmMove.dx+1;
           ty2:=ty1+LastResult^.weap^.anmMove.dy+1;
           {PutPixel (tx1+3,ty1+29,15);}
        until IsHit;
        i:=1;
        j:=0;
        pl:=Players[i];
        hx:=(tx1+tx2) div 2;
        hy:=(ty1+ty2) div 2;
        while (pl<>nil) do begin
          gx:=(pl^.x1+pl^.x2) div 2;
          gy:=(pl^.y1+pl^.y2) div 2;
          len:=Sqrt(Sqr(longint(abs(gx-hx)))+Sqr(longint(abs(gy-hy))));
          if len<=LastResult^.weap^.ERange then begin
              if pl=lpl then begin
                 LastResult^.Hit:=(LastResult^.weap^.Charge /
                  (LastResult^.weap^.ERange/(LastResult^.weap^.ERange-len)));
                 if gx<hx then LastResult^.dist:=len else LastResult^.dist:=-len;
              end;
              if (((pl^.computer) and (humans=0)) or (not cfg.comphum)) or (not pl^.computer)
                  and pl^.IsAlive then LastResult^.pl:=pl;
              Inc(j);
          end;
          Inc(i);
          pl:=Players[i];
        end;
      end;
      var  wp:byte;
           i,j,k:integer;
           mindir,maxdir:word;
           left:shortint;
           dir:integer;
           pow:real;
           r:real;
           pl:PPlayer;

      begin
        i:=1;
        pl:=Players[i];
        while not(((Players[i]<>nil) and (Players[i]^.IsAlive) and (Players[i]<>@self)) and
             (not cfg.comphum or ((not Players[i]^.computer) or (humans=0))))  do begin
          i:=Random(cfg.numofpl)+1;
          pl:=Players[i];
        end;
        if pl=nil then exit;
        if pl^.x1>x1 then begin
           left:=1;
           mindir:=0;
           maxdir:=90;
        end else begin
          left:=-1;
          mindir:=90;
          maxdir:=180;
        end;
        if LastResult=nil then begin
          New(LastResult);
          wp:=wBanana;
          LastResult^.weap:=Weapons[wp];
          LastResult^.Direction:=mindir+Random(maxdir-mindir);
          LastResult^.Power:=350+Random(650);
          LastResult^.pl:=pl;
          TestPath;
        end else
        if (LastResult^.pl<>@self) and (LastResult^.pl<>nil) then begin
           if (Weapons[wDynamite]<>nil) and (Weapons[wDynamite]^.amount>0) then wp:=wDynamite;
           if (Weapons[wBBanana]<>nil) and (Weapons[wBBanana]^.amount>0) then wp:=wBBanana;
           wp:=1+Random(4);
           LastResult^.weap:=Weapons[wp];
           TestPath;
        end;
        dir:=LastResult^.Direction;
        pow:=LastResult^.Power;
        i:=1;
        if alive>3 then j:=15;
        if alive>2 then j:=25;
        if alive>1 then j:=30;
        while ((LastResult^.pl=nil) or (LastResult^.pl=@self) or (not LastResult^.pl^.IsAlive)) and (i<j)
        do begin
           LastResult^.Direction:=mindir+Random(maxdir-mindir);
           LastResult^.Power:=350+Random(650);
           if LastResult^.Power>1000 then LastResult^.Power:=200;
           if LastResult^.Power<0 then LastResult^.Power:=1000;
           wp:=1+Random(5);
           LastResult^.weap:=Weapons[wp];
           LastResult^.pl:=pl;
           TestPath;
           Inc(i);
           if (LastResult^.pl=@self) and (LastResult^.Hit<(LastResult^.weap^.charge/3)) then begin
              LastResult^.pl:=nil;
           end;
           if (LastResult^.Hit<(LastResult^.weap^.charge/2)) then LastResult^.pl:=nil;
       end;
       if LastResult^.pl=@self then
         if (Weapons[wSBall]<>nil) and (Weapons[wSBall]^.amount>0) then wp:=wSBall else wp:=wBanana;
       if LastResult^.pl=nil then wp:=wBanana;
       dir:=LastResult^.direction;
       pow:=LastResult^.power;
       if humans>0 then begin
         SetDirection (dir);
         SetPower (pow);
       end else begin
         Direction:=dir;
         Power:=pow;
       end;
       repeat
         SetWeapon (wp);
         wp:=Random(5)+1;
       until (Weapons[CurWeapon]^.Amount>0) or (Weapons[CurWeapon]^.Unlimited);

      end;

      procedure TPlayer.AddWeapon (l:word;amt:byte);
      var wep:PWeapon;
          px,py:integer;
      begin
         New (wep,Init2(Animations[l].anmMove,Animations[l].anmExpl));
         case l of
            wBanana:begin
               with wep^ do begin
                  name:='MalÏ ban†n';
                  Health:=25;
                  Unlimited:=true;
                  Time:=0;
                  Charge:=30;
                  ERange:=30;
               end;
            end;
            wDynamite:begin
               with wep^ do begin
                  name:='Dynamit';
                  Health:=25;
                  Unlimited:=false;
                  Time:=0;
                  Charge:=60;
                  ERange:=50;
               end;
            end;
            wBBanana:begin
               with wep^ do begin
                  name:='VelkÏ ban†n';
                  Health:=25;
                  Unlimited:=false;
                  Time:=0;
                  Charge:=100;
                  ERange:=40;
               end;
            end;
            wSBall:begin
               with wep^ do begin
                  name:='"Snÿhov†" koule';
                  Health:=25;
                  Unlimited:=false;
                  Time:=0;
                  dirt:=true;
                  Charge:=5;
                  ERange:=50;
               end;
            end;
            wDHead:begin
               with wep^ do begin
                  name:='Smrú†kova lebka';
                  Health:=25;
                  Unlimited:=false;
                  Time:=0;
                  Charge:=200;
                  ERange:=80;
               end;
            end;
         end;
         wep^.amount:=amt;
         wep^.x1:=(x1+x2) div 2;
         wep^.y1:=(y1+y2) div 2;
         wep^.typ:=l;
         Weapons[MaxWeapon]:=wep;
         Inc (MaxWeapon);
      end;

      procedure TPlayer.Fire;
      begin
        Weapons[Curweapon]^.fx:=((x1+x2) div 2)-2;
        Weapons[Curweapon]^.fy:=((y1+y2) div 2)-2;
        Weapons[Curweapon]^.Direction:=Direction;
        Weapons[Curweapon]^.Speed:=Power;
        Weapons[Curweapon]^.Color:=color;
        Weapons[Curweapon]^.Move;
      end;

      constructor TWeapon.Init(movest,animst:string);
      begin
         Speed:=0;
         Name:='';
         Amount:=0;
         Unlimited:=false;
         dirt:=false;
         LoadAnim (movest,anmMove);
         LoadAnim (animst,anmExpl);
         x1:=0;
         x2:=x1+anmMove.dx;
         y1:=0;
         y2:=y1+anmMove.dy;
         NewBImage (imgPrev);
      end;

      constructor TWeapon.Init2(var aMove,aExpl:TAnim);
      begin
         Speed:=0;
         Name:='';
         Amount:=0;
         Unlimited:=false;
         dirt:=false;
         anmMove:=aMove;
         anmExpl:=aExpl;
         x1:=0;
         x2:=x1+anmMove.dx;
         y1:=0;
         y2:=y1+anmMove.dy;
         NewBImage (imgPrev);
      end;

      procedure TWeapon.Hit(amt:real);
      begin
         Health:=Health-amt;
         if Health<=0 then begin
            Explode;
         end;
      end;

      procedure TWeapon.Explode;
      var i,j:integer;
          gx,gy,hx,hy,mx,my:integer;
          len:real;
          pl:PPlayer;
      begin
        hx:=(x1+x2) div 2;
        hy:=(y1+y2) div 2;
        for i:=1 to 4 do begin
           for j:=1 to 25*Round(slowdown) do begin
              PlaySound (50+Random(20),1)
           end;
           DrawFrame (hx-(anmExpl.dx div 2)+3,hy-(anmExpl.dy div 2)+29,anmExpl,TRANS_COPY_PUT,true);
        end;
        for mx:=0 to anmExpl.dx do
          for my:=0 to anmExpl.dy do begin
             if (GetImagePixel(mx,my,anmExpl.imgEnd^.Image)<>0) and not dirt then
              PutPixel (hx-(anmExpl.dx div 2)+mx+3,
                        hy-(anmExpl.dy div 2)+my+29,GetBImPixel(hx-(anmExpl.dx div 2)+mx,
                        hy-(anmExpl.dy div 2)+my,Mountain.bckImg));
          end;
        Mountain.Fall(hx-(anmExpl.dx div 2),hx-(anmExpl.dx div 2)+anmExpl.dx+1);
        i:=1;
        pl:=Players[i];
        while pl<>nil do begin
          gx:=(pl^.x1+pl^.x2) div 2;
          gy:=(pl^.y1+pl^.y2) div 2;
          len:=Sqrt(Sqr(longint(abs(gx-hx)))+Sqr(longint(abs(gy-hy))));
          if len<=ERange then begin
             pl^.Hit (Charge / (ERange/(ERange-len)))
          end;
          if pl^.IsAlive then
            for mx:=0 to abs(pl^.x1-pl^.x2) do
               for my:=0 to abs(pl^.x1-pl^.x2) do
                  PutPixel (pl^.x1+mx+3,pl^.y1+my+29,GetBImPixel(pl^.x1+mx,pl^.y1+my,Mountain.bckImg));
          pl^.ResetPl;
          pl^.DrawNormal;
          pl^.Fall;
          Inc(i);
          pl:=Players[i];
        end;
        Draw3DBox (0,0,GetMaxX,25);
      end;

      procedure TWeapon.DrawMove;
      var px,py:integer;
      begin
         SetColor (255);
         Rectangle (1,27,GetMaxX-1,GetMaxY-1);
         SetColor (color);
         px:=(x1+x2) div 2;
         py:=(y1+y2) div 2;
         if (px>0) and (px<(GetMaxX-3)) then begin
            PutPixel (px+3,27,15);
            PutPixel (px+3,GetMaxY-1,15);
         end;
         if (py>0) and (py<(GetMaxY-29)) then begin
            PutPixel (1,py+27,15);
            PutPixel (GetMaxX-1,py+27,15);
         end;
         if not((x1<0) or (x2>(GetMaxX-3)) or (y1<0) or (y2>(GetMaxY-29))) then begin
            DrawFrame (x1+3,y1+29,anmMove,TRANS_COPY_PUT,true);
         end;
      end;

      procedure TWeapon.Move;

         function IsHit:boolean;
         var gx,gy:integer;
             mx,my:integer;
             pl:PPlayer;
             ht:real;
             i:byte;
             c:word;
         begin
           gx:=(x1+x2) div 2;
           gy:=(y1+y2) div 2;
           IsHit:=false;
           if not((x1<0) or (x2>(GetMaxX-3)) or (y1<0) or (y2>(GetMaxY-29))) and cfg.drawpaths
              then PutPixel (gx+3,gy+29,color);
           if (x1<0) or (x1>(GetMaxX-3)) or (y2>(GetMaxY-29)) then begin
             IsHit:=true;
             exit;
           end;
           i:=1;
           pl:=Players[i];
           while not((time<2.0) or (i>10) or (pl=nil)) do begin
             if ((pl^.x1<gx) and (gx<pl^.x2)) and ((pl^.y1<gy) and (gy<pl^.y2)) and (pl^.IsAlive) then begin
               IsHit:=true;
               exit;
             end;
             Inc(i);
             pl:=Players[i];
           end;
           if (y1<0) then exit;
           gx:=x1;
           gy:=y1;
           repeat
               c:=GetPixel (gx+3,gy+29);
               Inc (gx);
               if gx>=x2 then begin
                  Inc(gy);
                  gx:=x1;
               end;
           until ((gy>y2) or IsMountain(c));
           if IsMountain(c) then IsHit:=true else IsHit:=false;
         end;

      var koz,syn,deg:real;
          len:real;
      begin
         repeat
           time:=time+0.2;
           DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
           DisposeBImage (imgPrev);
           NewBImage (imgPrev);
           SetColor (15);
           if Direction=0 then begin
              koz:=1;
              syn:=0;
           end else begin
             koz:=cos(-(Pi/180)*Direction);
             syn:=sin(-(Pi/180)*Direction);
           end;
           x1:=fx+Round(((speed/30)*time)*koz-0.05*wind*Sqr(time));
           y1:=fy+Round(((speed/30)*time)*syn+0.5*cfg.gravity*Sqr(time));
           x2:=x1+anmMove.dx+1;
           y2:=y1+anmMove.dy+1;
           if IsHit then break;
           GetBImage (x1+3,y1+29,x2+3,y2+29,imgPrev);
           DrawMove;
           if humans>0 then delay (35*Round(slowdown)) else delay (10*Round(slowdown));
         until false;
         Explode;
         time:=0;
      end;

      destructor TWeapon.Done;
      begin
        DisposeAnim (anmMove);
        DisposeAnim (anmExpl);
        DisposeBImage(imgPrev);
      end;

      destructor TWeapon.Done2;
      begin
        DisposeBImage(imgPrev);
      end;


       procedure PlaySound (hz,dur:word); {Hraje PC Speakerovy zvuk}
       begin
         if cfg.sound then Sound (hz);
         Delay (dur);
         nosound;
       end;

       function MainGameLoop:boolean;
       var flags:byte;
           key:word;
           go,won,lost:boolean;
           hx,hy,dx,dy:integer;
           WeapArea,PowArea,DirArea:TArea;
           bOk:TButton;
           i:integer;

         function QuestEnd:byte;
         var img2:TImage;
             bYes,bNo:TButton;
             key:word;
             flags:byte;
         begin
           MCur.CleanCursor;
           NewBImage (img2);
           hx:=(GetMaxX-150) div 2;
           hy:=(GetMaxY-100) div 2;
           GetBImage (hx,hy,hx+150,hy+100,img2);
           Draw3DBox (hx,hy,hx+150,hy+100);
           SetColor (255);
           OutTextXY (hx+20,hy+20,'Chcete ukonüit hru ?');
           bYes.Init (hx+37,hy+45,'images\yes.gim','images\yes2.gim');
           bYes.Callback:=bYesCB;
           bNo.Init (hx+37,hy+70,'images\no.gim','images\no2.gim');
           bNo.Callback:=bNoCB;
           bend:=0;
           MCur.ResetCursor;
           MCur.RedrawCursor (true);
           repeat
             key:=0;
             bYes.CallBacker;
             bNo.CallBacker;
             MCur.RedrawCursor(false);
             if keypressed then Keystroke (key,flags);
             case key of
                 283,12654,12622:bend:=1;
                 7777,7745,283:bend:=2;
             end;
           until bend<>0;
           mcur.CleanCursor;
           bYes.Done;
           bNo.Done;
           QuestEnd:=bend;
           DrawBImage (hx,hy,img2,NormalPut);
           DisposeBImage(img2);
           mcur.ResetCursor;
           mcur.RedrawCursor(true);
         end;


       begin
         MCur.ResetCursor;
         MCur.RedrawCursor(true);
         MainGameLoop:=false;
         won:=false;
         lost:=false;
         WeapArea.Init (130,5,280,21);
         WeapArea.callback:=aWeapCB;
         DirArea.Init (290,5,350,21);
         Rectangle (290,5,350,21);
         DirArea.callback:=aDirCB;
         PowArea.Init (380,5,420,21);
         Rectangle (380,5,350,21);
         PowArea.callback:=aPowrCB;
         ppl:=Players[actplayer];
           ppl^.DrawTargeting;
           if random(1)=1 then wind:=-random(Round(cfg.maxwind*100))/100
                else wind:=random(Round(cfg.maxwind*100))/100;
           repeat
               key:=0;
               if alive=1 then won:=true;
               if alive=0 then lost:=true;
               if ppl^.Computer and not (won or lost) then begin
                  ppl^.AutoTarget;
                  key:=14624;
               end;
               if keypressed then Keystroke (key,flags);
               MCur.RedrawCursor(false);
               WeapArea.callbacker;
               PowArea.callbacker;
               DirArea.callbacker;
               case key of
                  19712:if (flags and kbRSHift)<>0 then ppl^.Direction:=ppl^.Direction-1
                                                  else ppl^.Direction:=ppl^.Direction-10; {lev† sipka}
                  18432:if (flags and kbRSHift)<>0 then ppl^.Power:=ppl^.Power+1
                                                  else ppl^.Power:=ppl^.Power+10; {sipka nahoru}
                  20480:if (flags and kbRSHift)<>0 then ppl^.Power:=ppl^.Power-1
                                                  else ppl^.Power:=ppl^.Power-10; {sipka dolu}
                  19200:if (flags and kbRSHift)<>0 then ppl^.Direction:=ppl^.Direction+1
                                                  else ppl^.Direction:=ppl^.Direction+10; {prava sipka}
                  3849:begin
                         Inc (ppl^.CurWeapon);
                         if ((ppl^.MaxWeapon)<=(ppl^.CurWeapon)) then ppl^.CurWeapon:=0;
                         ppl^.DrawTargeting;
                       end;
                  14624:begin
                          PlaySound (140,100);
                          for i:=1 to 7 do begin
                             if humans>0 then Delay(Round(slowdown)*50);
                             ppl^.Clean;
                             if (ppl^.Direction<270) and (ppl^.Direction>90) then ppl^.DrawThrowL else ppl^.DrawThrowR;
                          end;
                          ppl^.Clean;
                          ppl^.DrawNormal;
                          mcur.CleanCursor;
                          if (ppl^.Weapons[ppl^.curWeapon]^.Amount<>0) or ppl^.Weapons[ppl^.curWeapon]^.unlimited then begin
                             Dec (ppl^.Weapons[ppl^.curWeapon]^.Amount);
                             ppl^.Fire;
                          end;
                          SetColor (15);
                          Rectangle (0,26,GetMaxX,GetMaxY);
                          Rectangle (2,28,GetMaxX-2,GetMaxY-2);
                          SetColor (0);
                          Rectangle (1,27,GetMaxX-1,GetMaxY-1);
                          repeat
                             Inc (actplayer);
                             if (Players[actplayer]=nil) then actplayer:=1;
                          until (Players[actplayer]^.IsAlive) or (alive=0);
                          ppl:=Players[actplayer];
                          ppl^.Clean;
                          ppl^.ResetPl;
                          ppl^.DrawNormal;
                          if random(2)=1 then wind:=-random(Round(cfg.maxwind*100))/100
                              else wind:=random(Round(cfg.maxwind*100))/100;
                          mcur.ResetCursor;
                          ppl^.DrawTargeting;
                          ClearKeyboardBuffer;
                      end;
                  283:if QuestEnd=2 then lost:=true;
               end;
               if key>18000 then ppl^.DrawTargeting;
           until (won or lost);
         if won then MainGameLoop:=true;
         for i:=1 to 10 do if (Players[i]<>nil) and (Players[i]^.IsAlive) and (alive=1) then begin
           Players[i]^.DrawWin;
           hx:=(GetMaxX-200) div 2;
           hy:=(GetMaxY-100) div 2;
           MCur.CleanCursor;
           DrawGIM (hx,hy,'images\winbox.gnm',dx,dy,TRANS_COPY_PUT);
           SetColor (255);
           OutTextXY (hx+80,hy+20,'V°tÿz° !!');
           SetColor (Players[i]^.color);
           OutTextXY (((2*hx+dx) div 2)-(TextWidth(Players[i]^.name) div 2),hy+35,Players[i]^.name);
           SetColor (255);
           bOk.Init (hx+60,hy+dy-40,'images\ok.gim','images\ok2.gim');
           bOk.callback:=butOk1CB;
           send:=0;
           go:=false;
           MCur.ResetCursor;
           MCur.RedrawCursor(true);
           repeat
               MCur.RedrawCursor(false);
               bOk.callbacker;
               key:=0;
               if keypressed then Keystroke (key,flags);
               case key of
                  283,7181:go:=true;
               end;
           until go or (send=2);
           bOk.Done;
         end;
         WeapArea.Done;
         PowArea.Done;
         DirArea.Done;
       end;

       procedure TPlayer.DrawDie;
       var i,j:word;
       begin
         if not IsAlive then exit;

         for i:=1 to 50 do begin
           j:=random(200);
           PlaySound (2000+j-i,6);
         end;
         DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
         DrawFrame (x1+3,y1+29,anmDie,TRANS_COPY_PUT,true);
         delay (Round(slowdown*500));
         DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
         DrawFrame (x1+3,y1+29,anmDie,TRANS_COPY_PUT,true);
         for i:=1 to 50 do begin
           j:=random(200);
           PlaySound (1000+j-i,6);
         end;
         DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
         DrawFrame (x1+3,y1+29,anmDie,TRANS_COPY_PUT,true);
         delay (Round(slowdown*500));
         DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
         DrawFrame (x1+3,y1+29,anmDie,TRANS_COPY_PUT,true);
         ResetPl;
         Mountain.Fall (x1,x2);
       end;

       procedure TPlayer.Clean;
       begin
         if not IsAlive then exit;
         DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
       end;

       procedure TPlayer.ResetPl;
       begin
         DisposeBImage (imgPrev);
         NewBImage (imgPrev);
         GetBImage (x1+3,y1+29,x2+3,y2+29,imgPrev);
       end;

       procedure TPlayer.Move(x,y:integer);
       begin
         if not IsAlive then exit;
         DrawBImage (x1+3,y1+29,imgPrev,NormalPut);
         DisposeBImage (imgPrev);
         NewBImage (imgPrev);
         x1:=x;
         y1:=y;
         x2:=x+anmNormal.dx;
         y2:=y+anmNormal.dy;
         GetBImage (x1+3,y1+29,x2+3,y2+29,imgPrev);
       end;


       procedure TPlayer.Hit(amount:real);
       begin
         Health:=Health-(amount / Strength);
         DrawHBar;
         if IsAlive and (Health<=0) then begin
            DrawDie;
            if not computer then Dec(humans);
            IsALive:=false;
            Dec(alive);
         end;
       end;

       procedure TPlayer.Fall;
       var hx,hy:integer;
           c:word;
       begin
         if not (IsAlive and cfg.fallpls) then exit;
         hx:=x1+((x2-x1) div 2);
         hy:=y2+1;
         c:=GetPixel (hx+3,hy+29);
         while not IsMountain(c) do begin
           if hy<GetMaxY-30 then Move (x1,hy-(y2-y1)) else exit;
           DrawNormal;
           Hit (0.5);
           Inc (hy);
           c:=GetPixel (hx+3,hy+29);
         end;
       end;

       procedure AddPos (x,y:integer);
       begin
         if StartPos.Players=10 then exit else begin
           Inc(StartPos.Players);
           StartPos.Pos[StartPos.Players].x:=x;
           StartPos.Pos[StartPos.Players].y:=y;
         end;
       end;
       procedure EndGame;
       var i:word;
       begin
         for i:=1 to 10 do if Players[i]<>nil then Dispose (Players[i],Done);
         Mountain.Done;
       end;

       constructor TMountain.Init(mntfile,bckfile:string);
       var img:TImage;
           dx,dy:integer;
       begin
         NewBImage (bckImg);
         if not cfg.lowmem then begin
            LoadBImage(bckfile,bckImg);
            DrawBImage (3,29,bckImg,NormalPut);
         end;
         DrawGIM (3,29,mntfile,dx,dy,TRANS_COPY_PUT);
         Fall(0,633);
       end;

       destructor TMountain.Done;
       begin;
         DisposeBImage(bckImg);
       end;

       procedure TMountain.FallDown (x,y1,y2:integer;first:boolean);
       var yy1,yy2,yy4:integer;
           img:pointer;
           c,d:word;
       begin
           if y2<=y1 then exit;
           yy1:=y2-1;
           c:=GetPixel (x+3,yy1+29);
           while not (IsMountain(c) or (yy1=y1)) do begin
             if c=mntPos then begin
                AddPos (x,yy1);
                PutPixel (x+3,yy1+29,GetBImPixel(x,yy1,bckImg));
             end;
             Dec(yy1);
             c:=GetPixel (x+3,yy1+29);
           end;
           yy2:=yy1;
           c:=GetPixel (x+3,yy2+29);
           while not (not IsMountain(c) or (yy2=y1)) do begin
             Dec(yy2);
             c:=GetPixel (x+3,yy2+29);
           end;
           if (yy1<>yy2) then begin
              if (not first) and cfg.fallmnts then begin
                 GetMem (img,yy1-yy2+2+4);
                 GetImage (x+3,yy2-1+29,x+3,yy1+29,img^);
                 for yy4:=yy1 downto yy2 do PutPixel (x+3,yy4+29,GetBImPixel(x,yy4,bckImg));
                 PutImage (x+3,y2-(yy1-yy2)+29,img^,NormalPut);
                 FreeMem (img,yy1-yy2+2+4);
              end;
              FallDown (x,y1,y2-(yy1-yy2),false);
           end;
       end;

       procedure TMountain.Fall(x1,x2:integer);
       var vx,h:integer;
       begin
         for vx:=x1 to x2 do begin
           FallDown (vx,0,445,true);
         end;
       end;
begin
end.
