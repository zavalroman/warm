unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, FileCtrl, StrUtils, plc_io;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    DriveComboBox1: TDriveComboBox;
    DirectoryListBox1: TDirectoryListBox;
    FileListBox1: TFileListBox;
    Label1: TLabel;
    Panel5: TPanel;
    ListBox1: TListBox;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    ComboBox2: TComboBox;
    Button4: TButton;
    Button5: TButton;
    procedure FormResize(Sender: TObject);
    procedure DriveComboBox1Change(Sender: TObject);
    procedure DirectoryListBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FileListBox1Enter(Sender: TObject);
    procedure ListBox1Enter(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    plcio: TPLCIO;
    filelist: boolean;
    ispc: boolean;
    isplc: boolean;
    wtext: string;
    procedure wb(Sender: TObject);
    procedure we(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Unit2, Unit3;

function StartsStr(const APrefix : String; const ASource : String)
   : Boolean;
begin
   StartsStr := (CompareStr(APrefix, Copy(ASource, 0, Length(APrefix))) = 0);
end;

function GetNextSubstring(aBuf: string; var aStartPos: integer): string;
var
  vLastPos: integer;
begin
  if (aStartPos < 1) then
    begin
      raise ERangeError.Create('aStartPos должен быть больше 0');
    end;
 
  if (aStartPos > Length(aBuf) ) then
    begin
      Result := '';
      Exit;
    end;
 
  vLastPos := PosEx(#0, aBuf, aStartPos);
  Result := Copy(aBuf, aStartPos, vLastPos - aStartPos);
  aStartPos := aStartPos + (vLastPos - aStartPos) + 1;
end;
 
//Заполняет список aList наденными в системе COM портами
procedure GetComPorts(aList: TStrings; aNameStart: string);
var
  vBuf: string;
  vRes: integer;
  vErr: Integer;
  vBufSize: Integer;
  vNameStartPos: Integer;
  vName: string;
begin
  vBufSize := 1024 * 5;
  vRes := 0;
 
  while vRes = 0 do
    begin
      setlength(vBuf, vBufSize) ;
      SetLastError(ERROR_SUCCESS);
      vRes := QueryDosDevice(nil, @vBuf[1], vBufSize) ;
      vErr := GetLastError();
 
      //Вариант для двухтонки
      if (vRes <> 0) and (vErr = ERROR_INSUFFICIENT_BUFFER) then
        begin
          vBufSize := vRes;
          vRes := 0;
        end;
 
      if (vRes = 0) and (vErr = ERROR_INSUFFICIENT_BUFFER) then
        begin
          vBufSize := vBufSize + 1024;
        end;
 
      if (vErr <> ERROR_SUCCESS) and (vErr <> ERROR_INSUFFICIENT_BUFFER) then
        begin
          raise Exception.Create(SysErrorMessage(vErr) );
        end
    end;
  setlength(vBuf, vRes) ;
 
  vNameStartPos := 1;
  vName := GetNextSubstring(vBuf, vNameStartPos);
 
  aList.BeginUpdate();
  try
    aList.Clear();
    while vName <> '' do
      begin
        if StartsStr(aNameStart, vName) then
          aList.Add(vName);
        vName := GetNextSubstring(vBuf, vNameStartPos);
      end;
  finally
    aList.EndUpdate();
  end;
end;

 function GetDiskSize(drive: Char; var free_size, total_size: Int64): Boolean;
 var
   RootPath: array[0..4] of Char;
   RootPtr: PChar;
   current_dir: string;
 begin
   RootPath[0] := Drive;
   RootPath[1] := ':';
   RootPath[2] := '\';
   RootPath[3] := #0;
   RootPtr := RootPath;
   current_dir := GetCurrentDir;
   if SetCurrentDir(drive + ':\') then
   begin
     GetDiskFreeSpaceEx(RootPtr, Free_size, Total_size, nil);
     // this to turn back to original dir 
    SetCurrentDir(current_dir);
     Result := True;
   end
   else
   begin
     Result := False;
     Free_size  := -1;
     Total_size := -1;
   end;
 end;
 
procedure TForm1.FormResize(Sender: TObject);
begin
  Panel2.Width:=Round(Self.ClientWidth/2);
end;

procedure TForm1.DriveComboBox1Change(Sender: TObject);
var
   free_size, total_size: Int64;
   fs, ts: Extended;
begin
  if GetDiskSize(DriveComboBox1.Drive, free_size, total_size) then begin
    fs:=Round(free_size/1024/1024*100)/100;
    ts:=Round(total_size/1024/1024*100)/100;
    Label1.Caption:='свободно '+Format('%n',[fs])+'Мб из '+Format('%n',[ts])+'Мб';
    DirectoryListBox1.Drive:=DriveComboBox1.Drive;
   end else begin
     Label1.Caption:='нет диска';
     DirectoryListBox1.Clear;
     FileListBox1.Clear;
   end;
end;

procedure TForm1.DirectoryListBox1Change(Sender: TObject);
begin
  FileListBox1.Directory:=DirectoryListBox1.Directory;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ComboBox2.Hide;
  ispc:=false;
  isplc:=false;
  plcio:=TPLCIO.Create(self);
  plcio.OnWaitingBegin:=wb;
  plcio.OnWaitingEnd:=we;
  wtext:='';
  plcio.ConnectType:=ctTCP;
  plcio.Addr:=Edit1.Text;
  Button3Click(nil);
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  if ComboBox1.ItemIndex=0 then begin
    ComboBox2.Visible:=false;
    Edit1.Visible:=true;
  end else begin
    ComboBox2.Visible:=true;;
    Edit1.Visible:=false;
    GetComPorts(ComboBox2.Items, 'COM');
  end;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  if ComboBox1.ItemIndex=0 then begin
    plcio.ConnectType:=ctTCP;
    plcio.Addr:=Edit1.Text;
  end else begin
    plcio.ConnectType:=ctCOM;
    plcio.Port:=ComboBox2.Text;
  end;
  Button3Click(nil);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if not plcio.PLCDir(ListBox1.Items,dsAscending) then begin
    MessageDlg(plcio.LastError ,mtError ,mbOKCancel,0);
    filelist:=false;
  end else filelist:=true;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if not plcio.PLCInfo(Unit2.Form2.ListBox1.Items) then
    MessageDlg(plcio.LastError ,mtError ,mbOKCancel,0)
  else Unit2.Form2.ShowModal;
end;

procedure TForm1.Button2Click(Sender: TObject);

  function fileExistsInPLC(AFileName: String): boolean;
  var i: integer;
  begin
    Result:=false;
    for i:=0 to ListBox1.Count-1 do
      if ListBox1.Items[i]=AFileName then begin
        Result:=true;
        Break;
      end;
  end;
  
begin
  if filelist then begin
    if(ispc)and(FileListBox1.ItemIndex>-1)then begin
      if MessageDlg('Копировать файла "'+FileListBox1.FileName+
        '" в контроллер?' ,mtConfirmation ,mbYesNoCancel, 0)=mrYes then begin
        if fileExistsInPLC(ExtractFileName(FileListBox1.FileName)) then
          if MessageDlg('Файл "'+ExtractFileName(FileListBox1.FileName)+'" уже есть в контроллере. Перезаписать его?'
            ,mtConfirmation ,mbYesNoCancel, 0)<>mrYes then exit;
        wtext:='Подождите. Идет копирование…';
        if not plcio.CopyToPLC(FileListBox1.FileName) then
          MessageDlg(plcio.LastError ,mtError ,mbOKCancel,0)
        else Button3Click(nil);
      end;
    end else if(isplc)and(ListBox1.ItemIndex>-1)then begin
      if MessageDlg('Копировать файла "'+ListBox1.Items[ListBox1.ItemIndex]+
        '" в папку "'+DirectoryListBox1.Directory+'"?' ,mtConfirmation ,mbYesNoCancel, 0)=mrYes then begin
        if FileExists(DirectoryListBox1.Directory+'\'+ListBox1.Items[ListBox1.ItemIndex]) then
          if MessageDlg('Файл "'+DirectoryListBox1.Directory+'\'+ListBox1.Items[ListBox1.ItemIndex]+'" уже существует. Перезаписать его?'
            ,mtConfirmation ,mbYesNoCancel, 0)<>mrYes then exit;
        wtext:='Подождите. Идет копирование…';
        if not plcio.CopyToPC(DirectoryListBox1.Directory+'\'+ListBox1.Items[ListBox1.ItemIndex]) then
          MessageDlg(plcio.LastError ,mtError ,mbOKCancel,0)
        else FileListBox1.Update;
      end;
    end else MessageDlg('Файл не выбран!' ,mtInformation ,mbOKCancel, 0);
  end;
end;

procedure TForm1.FileListBox1Enter(Sender: TObject);
begin
  ispc:=true;
  isplc:=false;
  ListBox1.ItemIndex:=-1;
end;

procedure TForm1.ListBox1Enter(Sender: TObject);
begin
  ispc:=false;
  isplc:=true;
  FileListBox1.ItemIndex:=-1;
end;

procedure TForm1.wb(Sender: TObject);
begin
  if wtext<>'' then begin
    Unit3.Form3.Label1.Caption:=wtext;
    Self.Enabled:=false;
    Unit3.Form3.Show;
  end;
end;

procedure TForm1.we(Sender: TObject);
begin
  if(Assigned(Unit3.Form3))and(Unit3.Form3.Showing) then begin
    Unit3.Form3.Hide;
    Self.Enabled:=true;
    wtext:='';
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if(filelist)and(isplc)and(ListBox1.ItemIndex>-1)then begin
      if MessageDlg('Удалить файла "'+ListBox1.Items[ListBox1.ItemIndex]+
        '"?' ,mtConfirmation ,mbYesNoCancel, 0)=mrYes then begin
        wtext:='Подождите. Идет удаление…';
        if not plcio.DelFromPLC(ListBox1.Items[ListBox1.ItemIndex]) then
          MessageDlg(plcio.LastError ,mtError ,mbOKCancel,0)
        else Button3Click(nil);
      end;
  end else MessageDlg('Файл не выбран!' ,mtInformation ,mbOKCancel, 0);
end;

end.
