unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, modbus, ComCtrls, ScktComp, plc_io, FileToExcel;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    GroupBox3: TGroupBox;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    LabeledEdit4: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    LabeledEdit6: TLabeledEdit;
    Button1: TButton;
    StatusBar1: TStatusBar;
    Label4: TLabel;
    Button2: TButton;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    mb: TModbus;
    plcio: TPLCIO;
    procedure VarUpdate(Sender: TObject; AVar: TMBVar);
    procedure VarError(Sender: TObject; AVar: TMBVar);
    function UpdateList(i: Integer): String;
    procedure Conn(Sender: TObject);
    procedure Err(Sender: TObject; AErr: TErrorEvent);

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormShow(Sender: TObject);
begin
 // modbus.lb:=ListBox1;
 
  mb:=TModbus.Create(self);
  mb.AddVar('T1',MBT_WORD,3000,0);
  mb.AddVar('sT1',MBT_WORD,3000,0);
  mb.AddVar('State1',MBT_WORD,3000,0);
  mb.AddVar('T2',MBT_WORD,3000,0);
  mb.AddVar('sT2',MBT_WORD,3000,0);
  mb.AddVar('State2',MBT_WORD,3000,0);
  mb.AddVar('Volt',MBT_WORD,30000,0);
  mb.AddVar('Freq',MBT_WORD,3000,0);

  mb.AddVar('set',MBT_DWORD,6000,0);
  mb.AddVar('pow',MBT_DWORD,6000,0);
  mb.AddVar('curr',MBT_DWORD,6000,0);
  mb.AddVar('press',MBT_DWORD,6000,0);

  {  mb.AddVar('X005',MBT_BYTE,1000,0);
  mb.AddVar('X006',MBT_BYTE,1000,0);
  mb.AddVar('X007',MBT_FLOAT,1000,0);
                                    }
  mb.OnVarUpdated:=VarUpdate;
  mb.OnVarError:=VarError;
  mb.OnError:=Err;
  mb.OnConnected:=Conn;
  //Form1.Button1.Click;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  i : integer;
begin
  if mb.Active then begin
    mb.Active:=false;
    Button1.Caption:='���������';
    StatusBar1.Panels[0].Text:='���������:  ���������';
  end else begin
    mb.Address:= '10.10.120.118';
    mb.Port:=502;
    mb.DeviceAddr:=1;
    mb.Active:=true;
    StatusBar1.Panels[0].Text:='���������:  ';
    Button1.Caption:='�����������';
    {
    ListBox2.Clear;
    if mb.Active then begin
      for i:=0 to mb.VarsCount-1 do
        ListBox2.Items.Add(UpdateList(i));
    end;
    }
  end;


end;

procedure TForm1.VarUpdate(Sender: TObject; AVar: TMBVar);
var
  n : integer;
  s : string;
begin
  //ListBox2.Items[AVar.VarIndex]:=UpdateList(AVar.VarIndex);




//�����������
s := IntToStr(mb.Vars[0].Value);
n := Length(s);
Edit1.Text := Copy(s, 1, n-1) + ',' + Copy(s, n, 1);

s := IntToStr(mb.Vars[3].Value);
n := Length(s);
Edit2.Text := Copy(s, 1, n-1) + ',' + Copy(s, n, 1);


//��������
if mb.Vars[2].Value=1000 then
  Edit5.Text := '�������' else Edit5.Text := '�������';

if mb.Vars[5].Value then
  Edit6.Text := '�������' else Edit6.Text := '�������';


//�������
s := IntToStr(mb.Vars[1].Value);
n := Length(s);
Edit3.Text := Copy(s, 1, n-1) + ',' + Copy(s, n, 1);

s := IntToStr(mb.Vars[4].Value);
n := Length(s);
Edit4.Text := Copy(s, 1, n-1) + ',' + Copy(s, n, 1);


//--------------------��
//�������
s := IntToStr(mb.Vars[7].Value);
n := Length(s);
LabeledEdit1.Text := Copy(s, 1, n-1) + ',' + Copy(s, n, 1);

//��������
s := IntToStr(mb.Vars[9].Value);
n := Length(s);
LabeledEdit2.Text := Copy(s, 1, n-2) + ',' + Copy(s, n-1, 2);

//���
s := IntToStr(mb.Vars[10].Value);
n := Length(s);
LabeledEdit3.Text := Copy(s, 1, n-2) + ',' + Copy(s, n-1, 2);

//����������
s := IntToStr(mb.Vars[6].Value);
n := Length(s);
LabeledEdit4.Text := Copy(s, 1, n-1) + ',' + Copy(s, n, 1);

//��������
s := IntToStr(mb.Vars[11].Value);
n := Length(s);
LabeledEdit5.Text := Copy(s, 1, n-3) + ',' + Copy(s, n-2, 3);

s := IntToStr(mb.Vars[8].Value);
n := Length(s);
LabeledEdit6.Text := Copy(s, 1, n-3) + ',' + Copy(s, n-2, 3);

end;

function TForm1.UpdateList(i: Integer): String;
var
  t, v, it: String;
begin
  case mb.Vars[i].VarType of
    MBT_BYTE: begin
      t:='BYTE';
      v:=IntToStr(mb.Vars[i].Value);
    end;
    MBT_WORD: begin
      t:='WORD';
      v:=IntToStr(mb.Vars[i].Value);
    end;
    MBT_DWORD: begin
      t:='DWORD';
      v:=IntToStr(mb.Vars[i].Value);
    end;
    MBT_FLOAT: begin
      t:='FLOAT';
      v:=FloatToStr(mb.Vars[i].Value);
    end;
  end;
  if mb.Vars[i].Interval=0 then it:='none' else it:=FormatFloat('0.###',mb.Vars[i].Interval/1000)+' s';
  Result:=mb.Vars[i].Name+'['+it+'] '+t+' : '+v;
end;

procedure TForm1.VarError(Sender: TObject; AVar: TMBVar);
begin
 { if Pos('������!!!',ListBox2.Items[AVar.VarIndex])=0 then
    ListBox2.Items[AVar.VarIndex]:=ListBox2.Items[AVar.VarIndex]+'     ������!!!';
 }
end;

procedure TForm1.Conn(Sender: TObject);
begin
  StatusBar1.Panels[0].Text:='���������:  ���������';
end;


procedure TForm1.Err(Sender: TObject; AErr: TErrorEvent);
begin
  StatusBar1.Panels[0].Text:='���������:  ������ ����������!';
end;




procedure TForm1.Button2Click(Sender: TObject);
begin

  plcio.ConnectType:=ctTCP;
  plcio.Addr:='10.10.120.118';

  if not plcio.CopyToPC(ExtractFilePath(application.ExeName) + 'CTP.log') then
          MessageDlg(plcio.LastError ,mtError ,mbOKCancel,0);

  ExtractAndWrite('CTP.log');

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
plcio:=TPLCIO.Create(self);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
try
Excel.Quit;
Excel := Unassigned; except

end;
end;

end.






{        try

  dOPCServer1.OPCGroups[1].OPCItems[0].WriteSync(1);

  if  dOPCServer1.OPCGroups[1].OPCItems[0].Value=2 then begin
    Label4.Caption := '���� �������';
    Label4.Font.Color := clGreen;  end else begin
    //Label4.Caption := '����� ���';
    //Label4.Font.Color := clRed;

    end
  except


    Label4.Caption := '����� ���';
    Label4.Font.Color := clRed;

  end;  }
