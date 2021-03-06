unit FileToExcel;

interface

uses SysUtils, ComObj, Variants;

procedure ExcelCreateApplication(FirstSheetName: string; SheetCount: Integer;  ExcelVisible: Boolean);
procedure ExtractAndWrite(FileName: string);


var

  Excel, Sheet : Variant;

implementation

procedure ExcelCreateApplication(FirstSheetName: string;  SheetCount: Integer;  ExcelVisible: Boolean);
begin
  try
    Excel := CreateOleObject('Excel.Application');
    Excel.Application.EnableEvents := False;
    Excel.DisplayAlerts := False;
    Excel.SheetsInNewWorkbook := SheetCount;
    Excel.Visible := ExcelVisible;
    Excel.WorkBooks.Add;
    Sheet := Excel.WorkBooks[1].Sheets[1];
    Sheet.Name := FirstSheetName;
  except
    Exception.Create('Error.');
    Excel := UnAssigned;
  end;

end;

procedure ExtractAndWrite(FileName: string);
var
  i : integer;
  F : TextFile;
  S, t1, t2, p : string;
begin

  ExcelCreateApplication('����� ���', 1, True);

  Excel.Cells[1,1] := '����';
  Excel.Cells[1,2] := '�����';
  Excel.Cells[1,3] := '���';
  Excel.Cells[1,4] := '���������';
  Excel.Cells[1,5] := '��������';

  AssignFile(F, Filename);
  Reset(F);

  i := 2;
  while not Eof(F) do
    begin
      Readln(F, S);
      if S='' then break;
      t1 := IntToStr(StrToInt('$'+Copy(S, 26, 4)));
      t2 := IntToStr(StrToInt('$'+Copy(S, 36, 4)));
      p := IntToStr(StrToInt('$'+Copy(S, 46, 8)));

      Excel.Cells[i,1] := Copy(S, 1, 10);
      Excel.Cells[i,2] := Copy(S, 12, 8);
      Excel.Cells[i,3] := StrToFloat(Copy(t1, 1, 2) + ',' + Copy(t1, 3, 1));
      Excel.Cells[i,4] := StrToFloat(Copy(t2, 1, 2) + ',' + Copy(t2, 3, 1));
      Excel.Cells[i,5] := StrToFloat(Copy(p, 1, 1) + ',' + Copy(p, 2, 3));
      Inc(i);
    end;
   
  CloseFile(F);
end;

end.

{
procedure CuteBlocks(Line: string);
var
  i, j, n : integer;
  mol : string;
begin
  n := Length(Line);
  j := 0;
  mol := '';

  for i := 0 to n-1 do
    begin
      Inc(j);
      mol := mol + Line[i];
      case j of
        10 :  begin
                Archive[Index].Date := mol;
                mol := '';
                Inc(j);
              end;
        19 :  begin
                Archive[Index].Time := mol;
                mol := '';
                j := j + 6;
              end;
        29 :  begin
                Archive[Index].Trm1 := mol;
                mol := '';
                j := j + 6;
              end;
        39 :  begin
                Archive[Index].Trm2 := mol;
                mol := '';
                j := j + 6;
              end;
        53 :  begin
                Archive[Index].Press := mol;
                mol := '';
                j := 0;
              end;
      end;

    end;

//2(1)0(2)1(3)4(4).(5)1(6)1(7).(8)1(9)1(10) (11)1(12)1(13):(14)1(15)1(16):(17)4(18)6(19) (20)#(21)0(22)0(23)0(24)=(25)0(26)2(27)1(28)2(29) (30)#(31)0(32)0(33)1(34)=(35)0(36)1(37)f(38)a(39) (40)#(41)0(42)0(43)2(44)=(45)0(46)0(47)0(48)0(49)1(50)3(51)8(52)9(53)
 }
