unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, modbus, StdCtrls, ExtCtrls, ComCtrls, lgop, ScktComp;

type
  TForm1 = class(TForm)
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    Button1: TButton;
    ListBox2: TListBox;
    LabeledEdit3: TLabeledEdit;
    LabeledEdit4: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    Button3: TButton;
    StatusBar1: TStatusBar;
    ListBox1: TListBox;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit7: TLabeledEdit;
    Button2: TButton;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    mb: TModbus;
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
  modbus.lb:=ListBox1;
  mb:=TModbus.Create(self);
  mb.AddVar('X001',MBT_WORD,1000,0);
 { mb.AddVar('X002',MBT_DWORD,500,0);
  mb.AddVar('X003',MBT_WORD,2000,0);
  mb.AddVar('X004',MBT_DWORD,1000,0);
  mb.AddVar('X005',MBT_BYTE,1000,0);
  mb.AddVar('X006',MBT_BYTE,1000,0);
  mb.AddVar('X007',MBT_FLOAT,1000,0);   }

  mb.OnVarUpdated:=VarUpdate;
  mb.OnVarError:=VarError;
  mb.OnError:=Err;
  mb.OnConnected:=Conn;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  i: integer;
begin
  if mb.Active then begin
    mb.Active:=false;
    Button1.Caption:='Active';
    StatusBar1.Panels[0].Text:='State:  Deactivated';
  end else begin
    mb.Address:=LabeledEdit1.Text;
    mb.Port:=StrToInt(LabeledEdit2.Text);
    mb.DeviceAddr:=StrToInt(LabeledEdit3.Text);
    mb.Active:=true;
    StatusBar1.Panels[0].Text:='State:  ';
    Button1.Caption:='DeActive';
    ListBox2.Clear;
    if mb.Active then begin
      for i:=0 to mb.VarsCount-1 do
        ListBox2.Items.Add(UpdateList(i));
    end;
  end;
end;

procedure TForm1.VarUpdate(Sender: TObject; AVar: TMBVar);
begin
  ListBox2.Items[AVar.VarIndex]:=UpdateList(AVar.VarIndex);
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
  if Pos('Error!!!',ListBox2.Items[AVar.VarIndex])=0 then
    ListBox2.Items[AVar.VarIndex]:=ListBox2.Items[AVar.VarIndex]+'     Error!!!';
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  _var: TMBVar;
begin
  _var:=mb.GetVar(LabeledEdit4.Text);
  if _var<>nil then
    if _var.VarType=MBT_FLOAT
    then mb.SetVal(LabeledEdit4.Text,StrToFloat(LabeledEdit5.Text))
    else mb.SetVal(LabeledEdit4.Text,StrToInt(LabeledEdit5.Text))
end;

procedure TForm1.Conn(Sender: TObject);
begin
  StatusBar1.Panels[0].Text:='State:  Connected';
end;

procedure TForm1.Err(Sender: TObject; AErr: TErrorEvent);
begin
  StatusBar1.Panels[0].Text:='State:  Connect error!';
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  _var: TMBVar;
begin
  _var:=mb.GetVar(LabeledEdit4.Text);
  _var.Bits[StrToInt(LabeledEdit6.Text)]:=_is(StrToInt(LabeledEdit7.Text)=1,true,false);
end;

end.
