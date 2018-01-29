{*******************************************************}
{                                                       }
{       Kandiral Ruslan                                 }
{                                                       }
{       04.05.2012                                      }
{                                                       }
{       http://www.weblancer.net/users/Kandiral/        }
{       http://www.free-lance.ru/users/kandiral/        }
{       http://freelance.ru/users/kandiral/             }
{                                                       }
{*******************************************************}

unit plc_io;

interface

uses Classes, SysUtils, cmd, Forms, Dialogs;

type
  TPLC_ERROR = record
    code: integer;
    msg: String;
  end;

  TPLCDirSort = (dsNone, dsAscending, dsDescending);

const
  PLC_ERROR :array[0..9] of TPLC_ERROR = (
    (code: 100; msg: 'Произошла ошибка связи с ПЛК!'),
    (code: 110; msg: 'Не удалось открыть один из заданных файлов на ПК!'),
    (code: 111; msg: 'В параметрах указано слишком длинное имя файла!'),
    (code: 112; msg: 'Невозможно удалить файл на ПЛК!'),
    (code: 120; msg: 'Произошла единичная ошибка при чтении файла с ПЛК!'),
    (code: 121; msg: 'Произошли множественные ошибки при чтении файлов с ПЛК!'),
    (code: 130; msg: 'Произошла единичная ошибка при записи файла на ПЛК!'),
    (code: 131; msg: 'Произошли множественные ошибки при записи файлов на ПЛК!'),
    (code: 200; msg: 'Неправильно заданы параметры командной строки!'),
    (code: 201; msg: 'Внутренняя ошибка приложения!')
  );

type
  TPLCConnectType = (ctTCP, ctCOM);

  TPLCIO = class(TComponent)
  private
    FLError: String;
    FAddr: String;
    FPort: String;
    FCType: TPLCConnectType;
    sl1,sl2: TStringList;
    FPlc_io, FPlc_io_old, FPlc_con: String;
    FWaitingEnd: TNotifyEvent;
    FWaitingBegin: TNotifyEvent;
    procedure ParsPath(AFileName: String; out APath, AFile: String);
    procedure UpdateCType;
    procedure SetAddr(const Value: String);
    procedure SetCType(const Value: TPLCConnectType);
    procedure SetPort(const Value: String);
    function docmd(ACmd: String; ATOut: Cardinal):boolean;
  public
    constructor Create(AOwner: TComponent);override;
    destructor Destroy;override;
    property ConnectType: TPLCConnectType read FCType write SetCType;
    property Addr: String read FAddr write SetAddr;
    property Port: String read FPort write SetPort;
    property LastError: String read FLError;
    function CopyToPLC(AFileName: String): boolean;
    function CopyToPC(AFileName: String): boolean;
    function DelFromPLC(AFileName: String): boolean;
    function PLCInfo(AList: TStrings): boolean;
    function PLCDir(AList: TStrings; ASort: TPLCDirSort): boolean;
    property OnWaitingBegin: TNotifyEvent read FWaitingBegin write FWaitingBegin;
    property OnWaitingEnd: TNotifyEvent read FWaitingEnd write FWaitingEnd;
  end;

implementation


{ TPLCIO }

function TPLCIO.CopyToPC(AFileName: String): boolean;
var
  fl,pt: String;
begin
  ParsPath(AFileName,pt,fl);
  Result:=docmd(FPlc_io+FPlc_con+pt+' /get "'+fl+'"',120);
end;

function TPLCIO.CopyToPLC(AFileName: String): boolean;
var
  fl,pt: String;
begin
  ParsPath(AFileName,pt,fl);
  Result:=docmd(FPlc_io_old+FPlc_con+pt+' /up "'+fl+'"',120);
end;

constructor TPLCIO.Create(AOwner: TComponent);
begin
  inherited;
  sl1:=TStringList.Create;
  sl2:=TStringList.Create;
  FPlc_io:=ExtractFilePath(Application.ExeName)+'plc_io.exe';
  FPlc_io_old:=ExtractFilePath(Application.ExeName)+'plc_io_old.exe';
  FLError:='';
  FAddr:='10.0.6.10';
  FPort:='COM2';
  FCType:=ctTCP;
  UpdateCType;
end;

function TPLCIO.DelFromPLC(AFileName: String): boolean;
begin
  Result:=docmd(FPlc_io+FPlc_con+' /del "'+AFileName+'"',60);
end;

destructor TPLCIO.Destroy;
begin
  sl1.Free;
  sl2.Free;
  inherited;
end;

function TPLCIO.docmd(ACmd: String; ATOut: Cardinal): boolean;
var
  AEL: Cardinal;
  ASE,i : integer;
begin
  if Assigned(FWaitingBegin) then FWaitingBegin(Self);
  sl1.Clear;
  sl2.Clear;
  ASE:=__cmdAll(ACmd,ATOut,false,sl1,sl2,AEL);
  FLError:='';
  if ASE=-1 then FLError:='Превышен интервал ожидания!'
  else if ASE>0 then FLError:=SysErrorMessage(ASE)
  else if AEL<>0 then begin
    for i:=0 to Length(PLC_ERROR)-1 do
      if PLC_ERROR[i].code=AEL then begin
        FLError:=PLC_ERROR[i].msg;
        break;
      end;
    if FLError='' then FLError:='Неизвестная ошибка!';
  end;
  Result:=FLError='';
  if Assigned(FWaitingEnd) then FWaitingEnd(Self);
end;

procedure TPLCIO.ParsPath(AFileName: String; out APath, AFile: String);
begin
  APath:=ExtractFilePath(AFileName);
  APath:=Copy(APath,1,Length(APath)-1);
  APath:=' /FLDR"'+APath+'"';
  AFile:=ExtractFileName(AFileName);
end;

function TPLCIO.PLCDir(AList: TStrings; ASort: TPLCDirSort): boolean;
var
  i: integer;

  function CompareA(List: TStringList; Index1, Index2: Integer): Integer;
  begin
    Result := ANSICompareText(List[Index1], List[Index2]);
  end;

  function CompareD(List: TStringList; Index1, Index2: Integer): Integer;
  begin
    Result := ANSICompareText(List[Index2], List[Index1]);
  end;

begin
  Result:=docmd(FPlc_io+FPlc_con+' /dir',30);
  Alist.Clear;
  sl2.Clear;
  for i:=0 to sl1.Count-1 do if i/2=Trunc(i/2) then sl2.Add(sl1[i]);
  if ASort=dsAscending then sl2.CustomSort(@CompareA)
  else if ASort=dsDescending then sl2.CustomSort(@CompareD);
  AList.Assign(sl2);
end;

function TPLCIO.PLCInfo(AList: TStrings): boolean;
var
  i: integer;
begin
  Result:=docmd(FPlc_io+FPlc_con+' /info',30);
  Alist.Clear;
  for i:=0 to sl1.Count-1 do if i/2=Trunc(i/2) then Alist.Add(sl1[i]);
end;

procedure TPLCIO.SetAddr(const Value: String);
begin
  FAddr := Value;
  UpdateCType;
end;

procedure TPLCIO.SetCType(const Value: TPLCConnectType);
begin
  FCType := Value;
  UpdateCType;
end;

procedure TPLCIO.SetPort(const Value: String);
begin
  FPort := Value;
  UpdateCType;
end;

procedure TPLCIO.UpdateCType;
begin
  case FCType of
    ctTCP: FPlc_con:=' /TCP'+FAddr;
    ctCOM: FPlc_con:=' /'+FPort;
  end;
end;

end.
