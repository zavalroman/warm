{*******************************************************}
{                                                       }
{       Kandiral Ruslan                                 }
{                                                       }
{       21.05.2012                                      }
{                                                       }
{       http://www.weblancer.net/users/Kandiral/        }
{       http://www.free-lance.ru/users/kandiral/        }
{       http://freelance.ru/users/kandiral/             }
{                                                       }
{*******************************************************}

unit modbus;

interface

uses Classes, Variants, ExtCtrls, ScktComp, SysUtils, StdCtrls, Types, lgop;

type
  TMBType = (MBT_BYTE, MBT_WORD, MBT_DWORD, MBT_FLOAT);

  TMBStack = class
  private
    _cmd: array[0..255] of byte;
    _val: array[0..255] of Variant;
    _index: array[0..255] of byte;
    _start, _end: byte;
    FCount: byte;
    FOverflow: TNotifyEvent;
  public
    constructor Create;
    procedure Put(ACmd, AVarIndex: byte; AVal: Variant);
    procedure Get(Out ACmd, AVarIndex: byte; Out AVal: Variant);
    function CurFunc: byte;
    procedure Clear;
    property Count: byte read FCount;
    property OnOverflow: TNotifyEvent read FOverflow write FOverflow;
  end;

  TModbus = class;

  TMBVar = class(TPersistent)
  private
    FError: TNotifyEvent;
    _index, _len: Byte;
    _timer: TTimer;
    _modbus: TModbus;
    _sval: Variant;
    FInterval: integer;
    FVarIndex: integer;
    FName: String;
    FType: TMBType;
    FVal: Variant;
    FUpdated: TNotifyEvent;
    procedure SetInterval(const Value: integer);
    procedure SetVal(const Value: Variant);
    procedure _timerEx(Sender: TObject);
    function GetBits(Index: integer): boolean;
    procedure SetBits(Index: integer; const Value: boolean);
  public
    constructor Create(AModbus: TModbus; AName: String; AType: TMBType; AInterval: integer;
        defVal: Variant; var AIndex: byte);
    procedure Update;
    property VarType: TMBType read FType;
    property VarIndex: integer read FVarIndex;
    property Value: Variant read FVal write SetVal;
    property Bits[Index: integer]: boolean read GetBits write SetBits;
    property Interval: integer read FInterval write SetInterval;
    property Name: String read FName write FName;
    property OnUpdated: TNotifyEvent read FUpdated write FUpdated;
    property OnError: TNotifyEvent read FError write FError;
  end;

  TVarUpdated = procedure (Sender: TObject; AVar: TMBVar) of object;
  TSockError = procedure (Sender: TObject; AErr: TErrorEvent) of object;

  TModbus = class(TComponent)
  private
    _vars: array of TMBVar;
    _timer: TTimer;
    _tmout: byte;
    _index: byte;
    _byte: byte;
    _pk_cr: array[0..11] of char;
    _pk_r: array[0..11] of char;
    _pk_cw: array[0..13] of char;
    _pk_w: array[0..16] of char;
    _stack: TMBStack;
    _err: byte;
    _sclient: TClientSocket;
    FVarsCount: integer;
    FDevAddr: byte;
    FOverflow: TNotifyEvent;
    FVarUpdated: TVarUpdated;
    FVarError: TVarUpdated;
    FError: TSockError;
    FConn: TNotifyEvent;
    procedure mbread(n: byte);
    procedure mbwrite(n: byte; val: Variant);
    procedure mbsetbit(n, b: byte; val: Boolean); 
    procedure DoMB;
    function _GetVar(Index: integer): TMBVar;
    procedure SetDevAddr(const Value: byte);
    procedure StackOverflow(Sender: TObject);
    function GetAddr: String;
    function GetPort: Word;
    procedure SetActive(const Value: boolean);
    procedure SetAddr(const Value: String);
    procedure SetPort(const Value: Word);
    function GetActive: boolean;
    procedure _timerEx(Sender: TObject);
    procedure _sclientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure _sclientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
  public
    constructor Create(AOwner: TComponent);override;
    property Active: boolean read GetActive write SetActive;
    property Address: String read GetAddr write SetAddr;
    property Port: Word read GetPort write SetPort;
    function AddVar(AName: String; AType: TMBType; AInterval: integer; defVal: Variant): integer;
    property VarsCount: integer read FVarsCount;
    property Vars[Index: integer]:TMBVar read _GetVar;
    property DeviceAddr: byte read FDevAddr write SetDevAddr;
    function GetVal(Index: integer): Variant; overload;
    function GetVal(AName: String): Variant; overload;
    function GetVar(AName: String): TMBVar;
    procedure SetVal(Index: integer; AVal: Variant); overload;
    procedure SetVal(AName: String; AVal: Variant); overload;
    property OnStackOverflow: TNotifyEvent read FOverflow write FOverflow;
    property OnVarUpdated: TVarUpdated read FVarUpdated write FVarUpdated;
    property OnVarError: TVarUpdated read FVarError write FVarError;
    property OnError: TSockError read FError write FError;
    property OnConnected: TNotifyEvent read FConn write FConn;
  end;

var
  lb: TListBox;

implementation

function sourceToHex(buf: PChar; len: integer): String;
var i: integer;
begin
  result:='';
  for i:=0 to len-1 do result:=result+IntToHex(Ord(buf[i]),2)+' ';
end;

procedure addLog(Text: String);
begin
  lb.Items.Add(DateTimeToStr(now)+'     '+Text);
  lb.ItemIndex:=lb.Count-1;
end;

{ TModbus }

function TModbus.AddVar(AName: String; AType: TMBType; AInterval: integer; defVal: Variant): integer;
begin
  Inc(FVarsCount);
  SetLength(_vars,FVarsCount);
  _vars[FVarsCount-1]:=TMBVar.Create(self, AName, AType, AInterval, defVal, _index);
  Result:=FVarsCount;
end;

constructor TModbus.Create(AOwner: TComponent);
begin
  inherited;
  FDevAddr:=1;
  _pk_cr[0]:=#0;_pk_cr[1]:=#0;_pk_cr[2]:=#0;_pk_cr[3]:=#0;
  _pk_cr[4]:=#0;_pk_cr[5]:=#6;_pk_cr[6]:=#1;_pk_cr[7]:=#1;
  _pk_cr[8]:=#0;_pk_cr[9]:=#0;_pk_cr[10]:=#0;_pk_cr[11]:=#0;

  _pk_r[0]:=#0;_pk_r[1]:=#0;_pk_r[2]:=#0;_pk_r[3]:=#0;
  _pk_r[4]:=#0;_pk_r[5]:=#6;_pk_r[6]:=#1;_pk_r[7]:=#3;
  _pk_r[8]:=#0;_pk_r[9]:=#0;_pk_r[10]:=#0;_pk_r[11]:=#0;

  _pk_cw[0]:=#0;_pk_cw[1]:=#0;_pk_cw[2]:=#0;_pk_cw[3]:=#0;
  _pk_cw[4]:=#0;_pk_cw[5]:=#8;_pk_cw[6]:=#1;_pk_cw[7]:=#15;
  _pk_cw[8]:=#0;_pk_cw[9]:=#0;_pk_cw[10]:=#0;_pk_cw[11]:=#0;
  _pk_cw[12]:=#1;_pk_cw[13]:=#0;

  _pk_w[0]:=#0;_pk_w[1]:=#0;_pk_w[2]:=#0;_pk_w[3]:=#0;
  _pk_w[4]:=#0;_pk_w[5]:=#11;_pk_w[6]:=#1;_pk_w[7]:=#16;
  _pk_w[8]:=#0;_pk_w[9]:=#0;_pk_w[10]:=#0;_pk_w[11]:=#0;
  _pk_w[12]:=#0;_pk_w[13]:=#0;_pk_w[14]:=#0;_pk_w[15]:=#0;
  _pk_w[16]:=#0;


  _stack:=TMBStack.Create;
  _stack.OnOverflow:=StackOverflow;

  _sclient:=TClientSocket.Create(nil);
  _sclient.OnRead:=_sclientRead;
  _sclient.OnError:=_sclientError;

  _timer:=TTimer.Create(nil);
  _timer.OnTimer:=_timerEx;
  _timer.Interval:=20;
  _timer.Enabled:=false;
  _tmout:=0;

  SetLength(_vars,0);
  FVarsCount:=0;
  _index:=0;
  _byte:=0;
  _err:=0;
end;

function TModbus._GetVar(Index: integer): TMBVar;
begin
  Result:=_vars[Index];
end;

procedure TModbus.mbread(n: byte);
begin
  if Active then
    if _vars[n].VarType=MBT_BYTE then  _stack.Put(1,n,0)
    else _stack.Put(3,n,0);
end;

procedure TModbus.mbwrite(n: byte; val: Variant);
begin
  if Active then
    if _vars[n].VarType=MBT_BYTE then _stack.Put(15,n,val)
    else _stack.Put(16,n,val);
end;

function TModbus.GetVal(Index: integer): Variant;
begin
  Result:=_vars[Index].Value;
end;

function TModbus.GetVal(AName: String): Variant;
var
  i: integer;
begin
  Result:=0;
  for i:=0 to FVarsCount-1 do
    if _vars[i].Name=AName then begin
      Result:=_vars[i].Value;
      break;
    end;
end;

procedure TModbus.SetVal(Index: integer; AVal: Variant);
begin
  _vars[Index].Value:=AVal;
end;

procedure TModbus.SetVal(AName: String; AVal: Variant);
var
  i: integer;
begin
  for i:=0 to FVarsCount-1 do
    if _vars[i].Name=AName then begin
      _vars[i].Value:=AVal;
      break;
    end;
end;

procedure TModbus.SetDevAddr(const Value: byte);
begin
  FDevAddr := Value;
  _pk_cr[6]:=Chr(FDevAddr);
  _pk_r[6]:=Chr(FDevAddr);
  _pk_cw[6]:=Chr(FDevAddr);
  _pk_w[6]:=Chr(FDevAddr);
end;

procedure TModbus.StackOverflow(Sender: TObject);
begin
  if Assigned(FOverflow) then FOverflow(self);
end;

function TModbus.GetAddr: String;
begin
  Result:=_sclient.Address;
end;

function TModbus.GetPort: Word;
begin
  Result:=_sclient.Port;
end;

procedure TModbus.SetActive(const Value: boolean);
begin
  if _timer.Enabled<>Value then begin
    _timer.Enabled := Value;
    _sclient.Active:=false;
    _err:=0;
    if not _timer.Enabled then _stack.Clear;
  end;
end;

procedure TModbus.SetAddr(const Value: String);
begin
  _sclient.Address:=Value;
end;

procedure TModbus.SetPort(const Value: Word);
begin
  _sclient.Port:=Value;
end;

function TModbus.GetActive: boolean;
begin
  Result:=_timer.Enabled;
end;

procedure TModbus._timerEx(Sender: TObject);
begin
  if _tmout>0 then Dec(_tmout);
  if(_stack.Count=0)or(_tmout>0)then exit;
  DoMB;
  _tmout:=20;
end;

procedure TModbus.DoMB;
var
  _cmd, _n, len: byte;
  _val: Variant;
  fl: Single;
  p: Pointer;
  dw: DWord;
begin
  if not _sclient.Active then begin
    _sclient.Active:=true;
    _pk_r[1]:=Chr(255);
    _pk_r[9]:=#0;
    _pk_r[11]:=#1;
    _sclient.Socket.SendBuf(_pk_r,12);
    exit;
  end;

  _stack.Get(_cmd,_n,_val);

  case _cmd of
    $01: begin
      _pk_cr[1]:=Chr(_n);
      _pk_cr[8]:=Chr(_vars[_n]._index shr 8);
      _pk_cr[9]:=Chr(_vars[_n]._index and 255);
      _pk_cr[11]:=Chr(_vars[_n]._len);
//addLog(sourceToHex(_pk_cr,12));
      _sclient.Socket.SendBuf(_pk_cr,12);
    end;
    $03: begin
      _pk_r[1]:=Chr(_n);
      _pk_r[9]:=Chr(_vars[_n]._index);
      _pk_r[11]:=Chr(_vars[_n]._len);
//addLog(sourceToHex(_pk_r,12));
      _sclient.Socket.SendBuf(_pk_r,12);
    end;
    $0F: begin
      _pk_cw[1]:=Chr(_n);
      _pk_cw[8]:=Chr(_vars[_n]._index shr 8);
      _pk_cw[9]:=Chr(Byte(_vars[_n]._index));
      _pk_cw[11]:=Chr(_vars[_n]._len);
      _pk_cw[13]:=Chr(Byte(_val));
      _vars[_n]._sval:=_val;
      _sclient.Socket.SendBuf(_pk_cw,14);
    end;
    $10: begin
      _pk_w[1]:=Chr(_n);
      _pk_w[9]:=Chr(_vars[_n]._index);
      _pk_w[11]:=Chr(_vars[_n]._len);
      case _vars[_n].VarType of
        MBT_WORD: begin
          _pk_w[5]:=#9;
          _pk_w[12]:=#2;
          _pk_w[13]:=Chr(word(_val) shr 8);
          _pk_w[14]:=Chr(Byte(_val));
          len:=15;
        end;
        MBT_DWORD: begin
          _pk_w[5]:=#11;
          _pk_w[12]:=#4;
          _pk_w[15]:=Chr(DWORD(_val) shr 24);
          _pk_w[16]:=Chr(Byte(DWORD(_val) shr 16));
          _pk_w[13]:=Chr(Byte(DWORD(_val) shr 8));
          _pk_w[14]:=Chr(Byte(_val));
          len:=17;
        end;
        MBT_FLOAT: begin
          _pk_w[5]:=#11;
          _pk_w[12]:=#4;
          fl:=Single(_val);
          p:=@fl;
          dw:=DWORD(p^);
          _pk_w[15]:=Chr(DWORD(dw) shr 24);
          _pk_w[16]:=Chr(Byte(DWORD(dw) shr 16));
          _pk_w[13]:=Chr(Byte(DWORD(dw) shr 8));
          _pk_w[14]:=Chr(Byte(dw));
          len:=17;
        end
        else exit;
      end;
      _vars[_n]._sval:=_val;
      _sclient.Socket.SendBuf(_pk_w,len);
    end;
  end;


end;

procedure TModbus._sclientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  Len: Integer;
  Buffer: PChar;
  id: byte;
  fl: Single;
  p: Pointer;
  dw: DWord;
begin
  Len:=Socket.ReceiveLength;
  Buffer:=GetMemory(Len);
  Socket.ReceiveBuf(Buffer^, Len);

  id:=Ord(Buffer[1]);
  if id=255 then exit;

//addLog(sourceToHex(Buffer,Len));

  case Ord(Buffer[7]) of
    $01: begin
      _vars[id].FVal:=Ord(Buffer[9]);
      if Assigned(FVarUpdated) then FVarUpdated(Self,_vars[id]);
      if Assigned(_vars[id].FUpdated) then _vars[id].FUpdated(TObject(_vars[id]));
    end;
    $81: begin
      if Assigned(FVarError) then FVarError(Self,_vars[id]);
      if Assigned(_vars[id].FError) then _vars[id].FError(TObject(_vars[id]));
    end;
    $03: begin
      case _vars[id].FType of
        MBT_WORD: begin
          _vars[id].FVal:=Ord(Buffer[10]) or (Ord(Buffer[9]) shl 8);
        end;
        MBT_DWORD: begin
          _vars[id].FVal:=Word(Ord(Buffer[12]) or (Ord(Buffer[11]) shl 8));
          _vars[id].FVal:=DWord((_vars[id].Value shl 16) or (Ord(Buffer[10]) or (Ord(Buffer[9]) shl 8)));
        end;
        MBT_FLOAT: begin
          dw:=Word(Ord(Buffer[12]) or (Ord(Buffer[11]) shl 8));
          dw:=DWord((dw shl 16) or (Ord(Buffer[10]) or (Ord(Buffer[9]) shl 8)));
          p:=@dw;
          fl:=Single(p^);
          _vars[id].FVal:=fl;
        end;
      end;
      if Assigned(FVarUpdated) then FVarUpdated(Self,_vars[id]);
      if Assigned(_vars[id].FUpdated) then _vars[id].FUpdated(TObject(_vars[id]));
    end;
    $83: begin
      if Assigned(FVarError) then FVarError(Self,_vars[id]);
      if Assigned(_vars[id].FError) then _vars[id].FError(TObject(_vars[id]));
    end;
    $0F: begin
      _vars[id].FVal:=_vars[id]._sval;
      if Assigned(FVarUpdated) then FVarUpdated(Self,_vars[id]);
      if Assigned(_vars[id].FUpdated) then _vars[id].FUpdated(TObject(_vars[id]));
    end;
    $8F: begin
      if Assigned(FVarError) then FVarError(Self,_vars[id]);
      if Assigned(_vars[id].FError) then _vars[id].FError(TObject(_vars[id]));
    end;
    $10: begin
      _vars[id].FVal:=_vars[id]._sval;
      if Assigned(FVarUpdated) then FVarUpdated(Self,_vars[id]);
      if Assigned(_vars[id].FUpdated) then _vars[id].FUpdated(TObject(_vars[id]));
    end;
    $90: begin
      if Assigned(FVarError) then FVarError(Self,_vars[id]);
      if Assigned(_vars[id].FError) then _vars[id].FError(TObject(_vars[id]));
    end;
  end;

  if _err<>2 then begin
    _err:=2;
    if Assigned(FConn) then FConn(self);
  end;
  _tmout:=0;
end;

procedure TModbus._sclientError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  if _err<>1 then begin
    _err:=1;
    if Assigned(FError) then FError(Self, ErrorEvent);
  end;
  ErrorCode:=0;
end;

function TModbus.GetVar(AName: String): TMBVar;
var
  i: integer;
begin
  Result:=nil;
  for i:=0 to FVarsCount-1 do
    if _vars[i].Name=AName then begin
      Result:=_vars[i];
      break;
    end;
end;

procedure TModbus.mbsetbit(n, b: byte; val: Boolean);
var
  dw: DWord;
begin
  dw:=_vars[n].FVal;
//addLog('dw='+IntToStr(dw));
  dw:=SetBitTo(dw,b,val);
//addLog('dw='+IntToStr(dw));
  mbwrite(n,dw);
end;

{ TMBVar }

constructor TMBVar.Create(AModbus: TModbus; AName: String; AType: TMBType;
  AInterval: integer; defVal: Variant; var AIndex: Byte);
begin
  _modbus:=AModbus;
  FVarIndex:=_modbus.FVarsCount-1;
  FName:=AName;
  FType:=AType;
  _timer:=TTimer.Create(nil);
  _timer.OnTimer:=_timerEx;
  Interval:=AInterval;
  FVal:=defVal;
  case FType of
    MBT_BYTE: begin
      if _modbus._byte=AIndex-1 then begin
        _index:=_modbus._byte;
        _modbus._byte:=0;
        _index:=_index*16+8;
      end else begin
        _index:=AIndex;
        Inc(AIndex);
        _modbus._byte:=_index;
        _index:=_index*16;
      end;
      _len:=8;
    end;
    MBT_WORD: begin
      _index:=AIndex;
      Inc(AIndex);
      _len:=1;
    end;
    MBT_DWORD: begin
      _index:=AIndex;
      if _index/2>Trunc(_index/2) then Inc(_index);
      AIndex:=_index+2;
      _len:=2;
    end;
    MBT_FLOAT: begin
      _index:=AIndex;
      if _index/2>Trunc(_index/2) then Inc(_index);
      AIndex:=_index+2;
      _len:=2;
    end;
  end;
end;

procedure TMBVar.SetInterval(const Value: integer);
begin
  FInterval := Value;
  if FInterval>0 then begin
    _timer.Interval:=FInterval;
    _timer.Enabled:=true;
  end else _timer.Enabled:=false;
end;

procedure TMBVar.SetVal(const Value: Variant);
begin
  _modbus.mbwrite(FVarIndex,Value);
end;

procedure TMBVar._timerEx(Sender: TObject);
begin
  Update;
end;

procedure TMBVar.Update;
begin
  _modbus.mbread(FVarIndex);
end;

function TMBVar.GetBits(Index: integer): boolean;
begin
  Result:=GetBit(FVal,Index);
end;

procedure TMBVar.SetBits(Index: integer; const Value: boolean);
begin
  _modbus.mbsetbit(FVarIndex,Index,Value);
end;

{ TMBStack }

procedure TMBStack.Clear;
begin
  _start:=0;
  _end:=0;
  FCount:=0;
end;

constructor TMBStack.Create;
begin
  Clear;
end;

function TMBStack.CurFunc: byte;
begin
  Result:=0;
  if FCount=0 then exit;
  Result:=_cmd[_end];
end;

procedure TMBStack.Get(out ACmd, AVarIndex: byte; out AVal: Variant);
begin
  if FCount=0 then exit;
  ACmd:=_cmd[_end];
  AVal:=_val[_end];
  AVarIndex:=_index[_end];
  if(_end<255)then Inc(_end) else _end:=0;
  Dec(FCount);
end;

procedure TMBStack.Put(ACmd, AVarIndex: byte; AVal: Variant);
begin
  _cmd[_start]:=ACmd;
  _index[_start]:=AVarIndex;
  _val[_start]:=AVal;
  if(_start<255)then Inc(_start) else _start:=0;
  if(FCount<255) then Inc(FCount) else
    if Assigned(FOverflow) then FOverflow(self);
end;

end.
