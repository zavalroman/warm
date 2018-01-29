object Form1: TForm1
  Left = 213
  Top = 148
  Width = 836
  Height = 504
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object LabeledEdit1: TLabeledEdit
    Left = 16
    Top = 24
    Width = 121
    Height = 21
    EditLabel.Width = 10
    EditLabel.Height = 13
    EditLabel.Caption = 'IP'
    TabOrder = 0
    Text = '10.0.6.10'
  end
  object LabeledEdit2: TLabeledEdit
    Left = 16
    Top = 72
    Width = 121
    Height = 21
    EditLabel.Width = 19
    EditLabel.Height = 13
    EditLabel.Caption = 'Port'
    TabOrder = 1
    Text = '502'
  end
  object Button1: TButton
    Left = 16
    Top = 160
    Width = 75
    Height = 25
    Caption = 'Active'
    TabOrder = 2
    OnClick = Button1Click
  end
  object ListBox2: TListBox
    Left = 604
    Top = 0
    Width = 224
    Height = 323
    Align = alRight
    ItemHeight = 13
    TabOrder = 3
  end
  object LabeledEdit3: TLabeledEdit
    Left = 16
    Top = 120
    Width = 121
    Height = 21
    EditLabel.Width = 56
    EditLabel.Height = 13
    EditLabel.Caption = 'DeviceAddr'
    TabOrder = 4
    Text = '1'
  end
  object LabeledEdit4: TLabeledEdit
    Left = 152
    Top = 24
    Width = 121
    Height = 21
    EditLabel.Width = 38
    EditLabel.Height = 13
    EditLabel.Caption = 'Variable'
    TabOrder = 5
    Text = 'X001'
  end
  object LabeledEdit5: TLabeledEdit
    Left = 152
    Top = 72
    Width = 121
    Height = 21
    EditLabel.Width = 27
    EditLabel.Height = 13
    EditLabel.Caption = 'Value'
    TabOrder = 6
    Text = '1'
  end
  object Button3: TButton
    Left = 152
    Top = 112
    Width = 75
    Height = 25
    Caption = 'Set'
    TabOrder = 7
    OnClick = Button3Click
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 458
    Width = 828
    Height = 19
    Panels = <
      item
        Text = 'State:  Deactivated'
        Width = 50
      end>
  end
  object ListBox1: TListBox
    Left = 0
    Top = 323
    Width = 828
    Height = 135
    Align = alBottom
    ItemHeight = 13
    TabOrder = 9
  end
  object LabeledEdit6: TLabeledEdit
    Left = 288
    Top = 24
    Width = 121
    Height = 21
    EditLabel.Width = 12
    EditLabel.Height = 13
    EditLabel.Caption = 'Bit'
    TabOrder = 10
    Text = '0'
  end
  object LabeledEdit7: TLabeledEdit
    Left = 288
    Top = 72
    Width = 121
    Height = 21
    EditLabel.Width = 27
    EditLabel.Height = 13
    EditLabel.Caption = 'Value'
    TabOrder = 11
    Text = '1'
  end
  object Button2: TButton
    Left = 288
    Top = 112
    Width = 75
    Height = 25
    Caption = 'Set Bit'
    TabOrder = 12
    OnClick = Button2Click
  end
end
