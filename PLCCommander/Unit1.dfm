object Form1: TForm1
  Left = 164
  Top = 101
  Width = 758
  Height = 480
  Caption = 'Form1'
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 758
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 405
    Width = 750
    Height = 41
    Align = alBottom
    TabOrder = 0
    object Button1: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Del'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 96
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Copy'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 184
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Dir'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 272
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Info'
      TabOrder = 3
      OnClick = Button4Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 375
    Height = 405
    Align = alLeft
    TabOrder = 1
    object Panel4: TPanel
      Left = 1
      Top = 1
      Width = 373
      Height = 28
      Align = alTop
      TabOrder = 0
      object Label1: TLabel
        Left = 159
        Top = 6
        Width = 3
        Height = 14
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DriveComboBox1: TDriveComboBox
        Left = 5
        Top = 4
        Width = 145
        Height = 19
        TabOrder = 0
        OnChange = DriveComboBox1Change
      end
    end
    object DirectoryListBox1: TDirectoryListBox
      Left = 1
      Top = 29
      Width = 168
      Height = 375
      Align = alLeft
      ItemHeight = 16
      TabOrder = 1
      OnChange = DirectoryListBox1Change
    end
    object FileListBox1: TFileListBox
      Left = 169
      Top = 29
      Width = 205
      Height = 375
      Align = alClient
      ItemHeight = 13
      TabOrder = 2
      OnEnter = FileListBox1Enter
    end
  end
  object Panel3: TPanel
    Left = 375
    Top = 0
    Width = 375
    Height = 405
    Align = alClient
    TabOrder = 2
    object Panel5: TPanel
      Left = 1
      Top = 1
      Width = 373
      Height = 28
      Align = alTop
      TabOrder = 0
      object ComboBox1: TComboBox
        Left = 6
        Top = 2
        Width = 67
        Height = 21
        ItemHeight = 13
        ItemIndex = 0
        TabOrder = 0
        Text = 'TCP'
        OnChange = ComboBox1Change
        Items.Strings = (
          'TCP'
          'COM')
      end
      object Edit1: TEdit
        Left = 80
        Top = 2
        Width = 97
        Height = 21
        TabOrder = 1
        Text = '10.0.6.10'
      end
      object ComboBox2: TComboBox
        Left = 80
        Top = 2
        Width = 97
        Height = 21
        ItemHeight = 13
        TabOrder = 2
      end
      object Button5: TButton
        Left = 184
        Top = 2
        Width = 75
        Height = 21
        Caption = 'Set'
        TabOrder = 3
        OnClick = Button5Click
      end
    end
    object ListBox1: TListBox
      Left = 1
      Top = 29
      Width = 373
      Height = 375
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
      OnEnter = ListBox1Enter
    end
  end
end
