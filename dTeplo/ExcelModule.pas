unit ExcelModule;

interface

uses ComObj, QDialogs, SysUtils, Variants, DB;

//** �������� Excel
procedure ExcelCreateApplication(FirstSheetName: string; //����-� 1��� �����
  SheetCount: Integer; //���-�� ������
  ExcelVisible: Boolean); //����������� �����

//** ������� ������ ������� � �����, ����. 1='A',2='B',..,28='AB'
//** ������ �������� �� 'ZZ'
function ExcelChar(Num: Integer): string;

//** ���������� ���������� ��������� ���������
procedure ExcelRangeBorders(RangeBorders: Variant; //��������
  BOutSideSize: Byte; //������� �������
  BInsideSize: Byte; //������� ������
  BOutSideVerticalLeft: Boolean;
  BOutSideVerticalRight: Boolean;
  BInSideVertical: Boolean;
  BOutSideHorizUp: Boolean;
  BOutSideHorizDown: Boolean;
  BInSideHoriz: Boolean);

  //** �������������� ��������� (�����, ������)
procedure ExcelFormatRange(RangeFormat: Variant;
  Font: string;
  Size: Byte;
  AutoFit: Boolean);

//** ����� DataSet
procedure ExcelGetDataSet(DataSet: TDataSet;
  SheetNumber: Integer; // ����� �����
  FirstRow: Integer; // ������ ������
  FirstCol: Integer; // ������ �������
  ShowCaptions: Boolean; // ����� ���������� DataSet
  ShowNumbers: Boolean; // ����� ������� (N ��)
  FirstNumber: Integer; // ������ �����
  ShowBorders: Boolean; // ����� �������
  StepCol: Byte; // ��� �������: 0-������,
  // 1-����� ���� � ��
  StepRow: Byte); // ��� �����


var
  Excel, Sheet, Range, Columns: Variant;

implementation


procedure ExcelCreateApplication(FirstSheetName: string;
  SheetCount: Integer;
  ExcelVisible: Boolean);
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


function ExcelChar(Num: Integer): string;
var
  S: string;
  I: Integer;
begin
  I := Trunc(Num / 26);
  if Num > 26 then
    S := Chr(I + 64) + Chr(Num - (I * 26) + 64)
  else
    S := Chr(Num + 64);
  Result := S;
end;


procedure ExcelRangeBorders(RangeBorders: Variant;
  BOutSideSize: Byte;
  BInsideSize: Byte;
  BOutSideVerticalLeft: Boolean;
  BOutSideVerticalRight: Boolean;
  BInSideVertical: Boolean;
  BOutSideHorizUp: Boolean;
  BOutSideHorizDown: Boolean;
  BInSideHoriz: Boolean);
begin
  if BOutSideVerticalLeft then
  begin
    RangeBorders.Borders[7].LineStyle := 1;
    RangeBorders.Borders[7].Weight := BOutSideSize;
    RangeBorders.Borders[7].ColorIndex := -4105;
  end;
  if BOutSideHorizUp then
  begin
    RangeBorders.Borders[8].LineStyle := 1;
    RangeBorders.Borders[8].Weight := BOutSideSize;
    RangeBorders.Borders[8].ColorIndex := -4105;
  end;
  if BOutSideHorizDown then
  begin
    RangeBorders.Borders[9].LineStyle := 1;
    RangeBorders.Borders[9].Weight := BOutSideSize;
    RangeBorders.Borders[9].ColorIndex := -4105;
  end;
  if BOutSideVerticalRight then
  begin
    RangeBorders.Borders[10].LineStyle := 1;
    RangeBorders.Borders[10].Weight := BOutSideSize;
    RangeBorders.Borders[10].ColorIndex := -4105;
  end;
  if BInSideVertical then
  begin
    RangeBorders.Borders[11].LineStyle := 1;
    RangeBorders.Borders[11].Weight := BInSideSize;
    RangeBorders.Borders[11].ColorIndex := -4105;
  end;
  if BInsideHoriz then
  begin
    RangeBorders.Borders[12].LineStyle := 1;
    RangeBorders.Borders[12].Weight := BInSideSize;
    RangeBorders.Borders[12].ColorIndex := -4105;
  end;
end;


procedure ExcelFormatRange(RangeFormat: Variant;
  Font: string;
  Size: Byte;
  AutoFit: Boolean);
begin
  RangeFormat.Font.Name := 'Arial';
  RangeFormat.Font.Size := 7;
  if AutoFit then
    RangeFormat.Columns.AutoFit;
end;


procedure ExcelGetDataSet(DataSet: TDataSet;
  SheetNumber: Integer;
  FirstRow: Integer;
  FirstCol: Integer;
  ShowCaptions: Boolean;
  ShowNumbers: Boolean;
  FirstNumber: Integer;
  ShowBorders: Boolean;
  StepCol: Byte;
  StepRow: Byte);
var
  Column: Integer;
  Row: Integer;
  I: Integer;
begin
  if (ShowCaptions) and (FirstRow < 2) then
    FirstRow := 2;
  if (ShowNumbers) and (FirstCol < 2) then
    FirstCol := 2;

  try
    Sheet := Excel.WorkBooks[1].Sheets[SheetNumber];
  except
    Exception.Create('Error.');
    Exit;
  end;

  try
    with DataSet do
    try
      DisableControls;

      if ShowCaptions then
      begin
        Row := FirstRow - 1;
        Column := FirstCol;
        for i := 0 to FieldCount - 1 do
          if Fields[i].Visible then
          begin
            Sheet.Cells[Row, Column] := Fields[i].DisplayName;
            Inc(Column);
          end;
        Sheet.Rows[Row].Font.Bold := True;
      end;

      Row := FirstRow;
      First;
      while not EOF do
      begin
        Column := FirstCol;
        if ShowNumbers then
          Sheet.Cells[Row, FirstCol - 1] := FirstNumber;

        for i := 0 to FieldCount - 1 do
        begin
          if Fields[i].Visible then
          begin
            if Fields[i].DataType <> ftfloat then
              Sheet.Cells[Row, Column] := Trim(Fields[i].DisplayText)
            else
              Sheet.Cells[Row, Column] := Fields[i].Value;
            Inc(Column, StepCol);
          end;
        end;
        Inc(Row, StepRow);
        Inc(FirstNumber);
        Next;
      end;

      if ShowBorders then
      begin
        if ShowCaptions then
          Dec(FirstRow);
        if ShowNumbers then
          FirstCol := FirstCol - 1;
        Range := Sheet.Range[ExcelChar(FirstCol) + IntToStr(FirstRow) +
          ':' + ExcelChar(Column - 1) + IntToStr(Row - 1)];
        if (Row - FirstRow) < 2 then
          ExcelRangeBorders(Range, 3, 2, True, True,
            True, True, True, False)
        else
          ExcelRangeBorders(Range, 3, 2, True, True,
            True, True, True, True);
        ExcelFormatRange(Range, 'Arial', 7, True);
      end;

    finally
      EnableControls;
    end;
  finally
  end;
end;

end.
 