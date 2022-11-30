(*  Dom Kill System "DKSYS.PAS" 獅堂　光  ver1.24B  *)

unit dksys;

{----------------------------------------------------------------------------}
interface

uses bbsheadr,io,mailsys,{$IFDEF IBMPC}mchedeibm{$ELSE}mchde98b{$ENDIF};

function  dk_chk : boolean;
procedure EditUserData;
procedure dkuser(newuser:integer);
procedure dk_open;
procedure dkdlchk_inc;
procedure time_str;

{----------------------------------------------------------------------------}
implementation

type
	dksystem  = record
		dkdate		: integer;
		dkmonth		: integer;
		dkyear		: integer;
		dkdlchk		: longint;
	end;

const	dkfname	  = 'dksys.dat';
	dksysver  = 'Dom Kill System Ver1.24B (c) 1996-1997 獅堂 光☆ﾐ';
	dkmess1	  = '貴方のＤownＬoad可能ファイル数は ';
	dkmess2	  = ' 個です';

	dlchk	  = 50;
	tuserdl	  = 10;
	userdl    = 0;

var
	dkfile		: file of dksystem;
	dkdata		: dksystem;
	dklock		: boolean;

{----------------------------------------------------------------------------}


procedure writeX(n:longint); (* --- seek と write ------------------------- *)

begin
	{$I-}
	seek(dkfile,n-1);
	write(dkfile,dkdata);
	{$I+}
	transfernext;
end;


procedure readX(n:longint); (* --- seek と read ---------------------------- *)

begin
	{$I-}
	seek(dkfile,n-1);
	read(dkfile,dkdata);
	{$I+}
	transfernext;
end;


procedure accessX; (* --- assign と reset ---------------------------------- *)

begin
	while dklock do transfernext;
	dklock:=true;
	{$I-}
	assign(dkfile, dkfname);
	reset(dkfile);
	{$I+}
end;


procedure closeX; (* --- close --------------------------------------------- *)

begin
	{$I-}
	close(dkfile);
	{$I+}
	dklock:=false;
	transfernext;
end;


procedure GetUserData(work:integer); (* ------- 会員のデータを読み出す------ *)

begin
	if not cts then exit;
	if _^.usernum=0 then exit;
	accessX;
	readX(work);
	closeX;
end;


procedure dkuser(newuser:integer); (* ----------- 新規ユーザー登録 --------- *)

begin
	if _^.usernum=0 then exit;
	if not cts then exit;
	accessX;
	with dkdata do begin
		dkdate := 32;	dkmonth:= 13;
		dkyear := 1797; dkdlchk:= 0;
	end;
	writeX(newuser+1);
	closeX;
end;


function  dk_dlchk : word; (* -------------- 残りＤＬ回数を計算 -------------*)

var	def_dl	: integer;

begin
	if not cts then exit;
	if _^.usernum=0 then exit;
	def_dl:=dlchk;
	case _^.access of
		3	: def_dl:=tuserdl;
		2	: def_dl:=userdl;
	end;
	getuserdata(_^.usernum);
	dk_dlchk:=def_dl-dkdata.dkdlchk;
end;


procedure EditUserData;	(* ------------- ユーザーデータのエディト ---------- *)

var	number	:	integer;
	y_n	: 	char;

begin
	if not cts then exit;
	if (_^.usernum=0)or(_^.access<>sysop) then exit;
	lineout('');
	_^.prompt := 'ユーザーのＩＤは？ (?:ﾕｰｻﾞｰﾘｽﾄ [RET]:end)>';
	number := getid;
	if number < 1 then begin
		lineout('ＩＤエラーです。');
		exit;
	end;
	accessX;
	readX(number);
	closeX;
	lineout('');
	inbuffer[cn] := '';
	_^.prompt:='初期化してよろしいですか？(Y/[N])>';
	y_n:=getcap;
	if y_n='Y' then begin
		accessX;
		dkdata.dkdlchk := 0;
		writeX(number);
		closeX;
	end else lineout('処理を中止しました。');
end;


function  dk_chk : boolean; (* -------- ファイルボード規制チェック ----------*)

var	def_dl		: word;

begin
	if not cts then exit;
	if _^.usernum=0 then begin
		dk_chk:=false;
		exit;
	end;
	def_dl:=dlchk;
	case _^.access of
		3	: def_dl:=tuserdl;
		2	: def_dl:=userdl;
	end;
	getuserdata(_^.usernum);
	if (dkdata.dkdlchk>=def_dl) then dk_chk:=true
	else dk_chk:=false;
end;


procedure dk_open; (* ------------- ＤＫファイル更新処理-------------------- *)

var	def_dl	: integer;

begin
	if _^.usernum=0 then exit;
	accessX;
	readX(_^.usernum);
	def_dl:=dlchk;				(* DL規制−DL回数が＝０以下 *)
	case _^.access of			(* だったらﾃﾞｰﾀ修正(^^:)    *)
		3	: def_dl:=tuserdl;
		2	: def_dl:=userdl;
	end;
	if def_dl-dkdata.dkdlchk<0 then begin
		dkdata.dkdlchk := def_dl;
		writeX(_^.usernum);
	end;
	if (dkdata.dkdate<>_^.ondate)or(dkdata.dkmonth<>_^.onmonth)or(dkdata.dkyear<>_^.onyear) then begin
		dkdata.dkdate:=_^.ondate;
		dkdata.dkmonth:=_^.onmonth;
		dkdata.dkyear:=_^.onyear;
		dkdata.dkdlchk:=0;
		writeX(_^.usernum);
	end;
	closeX;
end;


procedure dkdlchk_inc; (* ------------------ ＤＬ回数の追加 ---------------- *)

var	def_dl	: integer;

begin
	if not cts then exit;
	if _^.usernum=0 then exit;
	accessX;
	readX(_^.usernum);
	def_dl:=dlchk;
	case _^.access of
		3	: def_dl:=tuserdl;
		2	: def_dl:=userdl;
	end;
	if def_dl-dkdata.dkdlchk>0 then inc(dkdata.dkdlchk,1);
	writeX(_^.usernum);
	closeX;
end;


procedure time_str; (* ------------------- 各種データ表示 ------------------ *)

var	def_dl	: integer;

begin
	if not cts then exit;
	if _^.usernum=0 then exit;
	accessX;
	readX(_^.usernum);
	def_dl:=dlchk;
	case _^.access of
		3	: def_dl:=tuserdl;
		2	: def_dl:=userdl;
	end;
	if def_dl-dkdata.dkdlchk<0 then begin
		dkdata.dkdlchk := def_dl;
		writeX(_^.usernum);
	end;
	if (dkdata.dkdate<>_^.ondate)or(dkdata.dkmonth<>_^.onmonth)or(dkdata.dkyear<>_^.onyear) then begin
		dkdata.dkdate:=_^.ondate;
		dkdata.dkmonth:=_^.onmonth;
		dkdata.dkyear:=_^.onyear;
		dkdata.dkdlchk:=0;
		writeX(_^.usernum);
	end;
	closeX;
	lineout('');
	lineout(dkmess1+_str(dk_dlchk,3)+dkmess2);
end;


{----------------------------------------------------------------------------}

var	ids	: file of sysid;
	int	: integer;

begin
	assign(dkfile,dkfname);
	{$I-}reset(dkfile);{$I+}
	if ioresult <> 0 then begin
		writeln(' ＤomＫillＳystem  ＤataＦileを制作しますね(^^/ ');
		{$I-}rewrite(dkfile);{$I+}
		assign(ids,mesdir+'ids.bbs');
		{$I-}reset(ids);{$I+}
		if ioresult <> 0 then begin
			writeln(' IDS.BBS がないﾐﾀｲﾅ(^^/');
			with dkdata do begin
				dkdate:=32;   dkmonth:=13;
				dkyear:=1797; dkdlchk:=0;
			end;
			for int:=0 to 3 do begin
				{$I-}
				seek(dkfile,int);
				write(dkfile,dkdata);
				{$I+}
			end;
		end else
		begin
			with dkdata do begin
				dkdate:=32;   dkmonth:=13;
				dkyear:=1797; dkdlchk:=0;
			end;
			for int:=0 to filesize(ids)+2 do begin
				{$I-}
				seek(dkfile,int);
				write(dkfile,dkdata);
				{$I+}
			end;
		end;
		{$I-}
		close(ids);
		close(dkfile);
		{$I+}
	end;
	dklock:=false;
end.

