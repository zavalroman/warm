{*******************************************************}
{                                                       }
{       Kandiral Ruslan                                 }
{                                                       }
{       23.04.2012                                      }
{                                                       }
{       http://www.weblancer.net/users/Kandiral/        }
{       http://www.free-lance.ru/users/kandiral/        }
{       http://freelance.ru/users/kandiral/             }
{                                                       }
{*******************************************************}

unit cmd;

interface

uses Windows, Messages, SysUtils, Classes, Forms;

const
  timeoutErrorMsg = 'Превышен интервал ожидания.';

type
  TCMD = class(TComponent)
  public
    function __cmd(cmdLine: String): Integer;overload;
    function __cmd(cmdLine: String; _timeOut: Cardinal): Integer;overload;
    function __cmd(cmdLine: String; _timeOut: Cardinal; var ErrorLevel: Cardinal): Integer;overload;
    function __cmd(cmdLine: String; _timeOut: Cardinal; isCP866: boolean; Output, Errors: TStrings; var ErrorLevel: Cardinal): Integer;overload;
    function ErrorMsg(ACode: integer): String;
  end;

  function __cmd(cmdLine: String): Integer;
  function __cmdT(cmdLine: String; _timeOut: Cardinal): Integer;
  function __cmdEL(cmdLine: String; _timeOut: Cardinal; var ErrorLevel: Cardinal): Integer;
  function __cmdALL(cmdLine: String; _timeOut: Cardinal; isCP866: boolean; Output, Errors: TStrings; var ErrorLevel: Cardinal): Integer;
  function __cmdErrMsg(ACode: integer): String;

implementation

function __cmd(cmdLine: String): Integer;
begin
  Result:=__cmdT(cmdLine,INFINITE);
end;

function __cmdT(cmdLine: String; _timeOut: Cardinal): Integer;
var
  si: TSTARTUPINFO;
  pi: TPROCESSINFORMATION;
  Res: Boolean;
  env: array[0..100] of Char;

  env_pos, i: integer;

  procedure addEnv(s: String);
  var i: integer;
  begin
    for i:=1 to Length(s) do begin
      env[env_pos]:=s[i];
      inc(env_pos);
    end;
    inc(env_pos);
  end;

begin
  Result:=0;

  ZeroMemory(@env, SizeOf(env));
  env_pos:=0;
  addEnv('SystemRoot=c:\windows');
  ZeroMemory(@si, SizeOf(si));
  ZeroMemory(@pi, SizeOf(pi));
  si.cb := SizeOf(si);
  si.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  si.wShowWindow := SW_HIDE;
  si.hStdInput := 0;

  Res := CreateProcess(nil, pchar(cmdLine), nil, nil, true,
    CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, @env, nil, si, pi);

  if not Res then
  begin
    Result:=GetLastError();
    Exit;
  end;

  i:=0;
  while WaitforSingleObject(pi.hProcess, 100) = WAIT_TIMEOUT do begin
    if Assigned(Application) then Application.ProcessMessages else Sleep(100);
    inc(i,100);
    if (_timeOut>0)and(i>_timeOut*1000) then begin
      TerminateProcess(pi.hProcess, 1 );
      Result:=-1;
      Break;
    end;
  end;

  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
end;

function __cmdEL(cmdLine: String; _timeOut: Cardinal; var ErrorLevel: Cardinal): Integer;
var
  si: TSTARTUPINFO;
  pi: TPROCESSINFORMATION;
  Res: Boolean;
  env: array[0..100] of Char;

  env_pos, i: integer;

  procedure addEnv(s: String);
  var i: integer;
  begin
    for i:=1 to Length(s) do begin
      env[env_pos]:=s[i];
      inc(env_pos);
    end;
    inc(env_pos);
  end;

begin
  Result:=0;

  ZeroMemory(@env, SizeOf(env));
  env_pos:=0;
  addEnv('SystemRoot=c:\windows');
  ZeroMemory(@si, SizeOf(si));
  ZeroMemory(@pi, SizeOf(pi));
  si.cb := SizeOf(si);
  si.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  si.wShowWindow := SW_HIDE;
  si.hStdInput := 0;

  Res := CreateProcess(nil, pchar(cmdLine), nil, nil, true,
    CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, @env, nil, si, pi);

  if not Res then
  begin
    Result:=GetLastError();
    Exit;
  end;

  i:=0;
  while WaitforSingleObject(pi.hProcess, 100) = WAIT_TIMEOUT do begin
    if Assigned(Application) then Application.ProcessMessages else Sleep(100);
    inc(i,100);
    if (_timeOut>0)and(i>_timeOut*1000) then begin
      TerminateProcess(pi.hProcess, 1 );
      Result:=-1;
      Break;
    end;
  end;

  GetExitCodeProcess(pi.hProcess, ErrorLevel);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
end;

function __cmdAll(cmdLine: String; _timeOut: Cardinal; isCP866: boolean; Output, Errors: TStrings;
    var ErrorLevel: Cardinal): Integer;
var
  sa: TSECURITYATTRIBUTES;
  si: TSTARTUPINFO;
  pi: TPROCESSINFORMATION;
  hPipeOutputRead: THANDLE;
  hPipeOutputWrite: THANDLE;
  hPipeErrorsRead: THANDLE;
  hPipeErrorsWrite: THANDLE;
  Res, bTest: Boolean;
  env: array[0..100] of Char;
  szBuffer: array[0..256] of Char;
  dwNumberOfBytesRead: DWORD;
  Stream: TMemoryStream;

  env_pos: integer;
  s0,s1: String;
  I: integer;

  procedure addEnv(s: String);
  var i: integer;
  begin
    for i:=1 to Length(s) do begin
      env[env_pos]:=s[i];
      inc(env_pos);
    end;
    inc(env_pos);
  end;

begin
  Result:=0;

  sa.nLength := sizeof(sa);
  sa.bInheritHandle := true;
  sa.lpSecurityDescriptor := nil;
  CreatePipe(hPipeOutputRead, hPipeOutputWrite, @sa, 0);
  CreatePipe(hPipeErrorsRead, hPipeErrorsWrite, @sa, 0);
  ZeroMemory(@env, SizeOf(env));
  env_pos:=0;
  addEnv('SystemRoot=c:\windows');
  ZeroMemory(@si, SizeOf(si));
  ZeroMemory(@pi, SizeOf(pi));
  si.cb := SizeOf(si);
  si.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
  si.wShowWindow := SW_HIDE;
  si.hStdInput := 0;
  si.hStdOutput := hPipeOutputWrite;
  si.hStdError := hPipeErrorsWrite;

  Res := CreateProcess(nil, pchar(cmdLine), nil, nil, true,
    CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, @env, nil, si, pi);

  if not Res then
  begin
    CloseHandle(hPipeOutputRead);
    CloseHandle(hPipeOutputWrite);
    CloseHandle(hPipeErrorsRead);
    CloseHandle(hPipeErrorsWrite);
    Result:=GetLastError();
    Exit;
  end;
  CloseHandle(hPipeOutputWrite);
  CloseHandle(hPipeErrorsWrite);

  i:=0;
  while WaitforSingleObject(pi.hProcess, 100) = WAIT_TIMEOUT do begin
    if Assigned(Application) then Application.ProcessMessages else Sleep(100);
    inc(i,100);
    if (_timeOut>0)and(i>_timeOut*1000) then begin
      TerminateProcess(pi.hProcess, 1 );
      Result:=-1;
      Break;
    end;
  end;

  Stream := TMemoryStream.Create;
  try
    while true do
    begin
      bTest := ReadFile(hPipeOutputRead, szBuffer, 256, dwNumberOfBytesRead,
        nil);
      if not bTest then
      begin
        break;
      end;
      Stream.Write(szBuffer, dwNumberOfBytesRead);
    end;
    Stream.Position := 0;
    Output.LoadFromStream(Stream);

    if isCP866 then
      for I:=0 to Output.Count-1 do begin
        s0:=Output[i];
        if s0<>'' then begin
          SetLength(s1,Length(s0));
          OemToChar(PChar(s0),PChar(s1));
          Output[i]:=s1;
        end;
      end;
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    while true do
    begin
      bTest := ReadFile(hPipeErrorsRead, szBuffer, 256, dwNumberOfBytesRead,
        nil);
      if not bTest then
      begin
        break;
      end;
      Stream.Write(szBuffer, dwNumberOfBytesRead);
    end;
    Stream.Position := 0;
    Errors.LoadFromStream(Stream);

    if isCP866 then
      for I:=0 to Errors.Count-1 do begin
        s0:= Errors[i];
        SetLength(s1,Length(s0));
        OemToChar(PChar(s0),PChar(s1));
        Errors[i]:=s1;
      end;
  finally
    Stream.Free;
  end;

  GetExitCodeProcess(pi.hProcess, ErrorLevel);
  CloseHandle(pi.hProcess);
  CloseHandle(pi.hThread);
  CloseHandle(hPipeOutputRead);
  CloseHandle(hPipeErrorsRead);
end;

function __cmdErrMsg(ACode: integer): String;
begin
  if ACode=-1 then Result:=timeoutErrorMsg
  else Result:=SysErrorMessage(ACode);
end;

{ TCMD }

function TCMD.__cmd(cmdLine: String; _timeOut: Cardinal): Integer;
begin
  Result:=__cmdT(cmdLine, _timeOut);
end;

function TCMD.__cmd(cmdLine: String): Integer;
begin
  Result:=Self.__cmd(cmdLine, INFINITE);
end;

function TCMD.__cmd(cmdLine: String; _timeOut: Cardinal;
  var ErrorLevel: Cardinal): Integer;
begin
  Result:=__cmdEL(cmdLine, _timeOut, ErrorLevel);
end;

function TCMD.__cmd(cmdLine: String; _timeOut: Cardinal; isCP866: boolean;
  Output, Errors: TStrings; var ErrorLevel: Cardinal): Integer;
begin
  Result:=__cmdAll(cmdLine, _timeOut, isCP866, Output, Errors, ErrorLevel);
end;

function TCMD.ErrorMsg(ACode: integer): String;
begin

end;

end.
