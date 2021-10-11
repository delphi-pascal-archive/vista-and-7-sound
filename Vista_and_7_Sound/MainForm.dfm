object fmMain: TfmMain
  Left = 236
  Top = 131
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Vista and 7 Sound'
  ClientHeight = 210
  ClientWidth = 273
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  Icon.Data = {
    0000010001002020040000000000E80200001600000028000000200000004000
    0000010004000000000000020000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00CCC0
    000CCCC0000000000CCCC8888CCCCCCC0000CCCC00000000CCCC8888CCCCCCCC
    C0000CCCCCCCCCCCCCC8888CCCCC0CCCCC0000CCCCCCCCCCCC8888CCCCC800CC
    C00CCCC0000000000CCCC88CCC88000C0000CCCC00000000CCCC8888C8880000
    00000CCCC000000CCCC888888888C000C00000CCCC0000CCCC88888C888CCC00
    CC00000CCCCCCCCCC88888CC88CCCCC0CCC000CCCCC00CCCCC888CCC8CCCCCCC
    CCCC0CCCCCCCCCCCCCC8CCCCCCCCCCCC0CCCCCCCCCCCCCCCCCCCCCC8CCC80CCC
    00CCCCCCCC0CC0CCCCCCCC88CC8800CC000CCCCCC000000CCCCCC888CC8800CC
    0000CCCC00000000CCCC8888CC8800CC0000C0CCC000000CCC8C8888CC8800CC
    0000C0CCC000000CCC8C8888CC8800CC0000CCCC00000000CCCC8888CC8800CC
    000CCCCCC000000CCCCCC888CC8800CC00CCCCCCCC0CC0CCCCCCCC88CC880CCC
    0CCCCCCCCCCCCCCCCCCCCCC8CCC8CCCCCCCC0CCCCCCCCCCCCCC8CCCCCCCCCCC0
    CCC000CCCCC00CCCCC888CCC8CCCCC00CC00000CCCCCCCCCC88888CC88CCC000
    C00000CCCC0000CCCC88888C888C000000000CCCC000000CCCC888888888000C
    0000CCCC00000000CCCC8888C88800CCC00CCCC0000000000CCCC88CCC880CCC
    CC0000CCCCCCCCCCCC8888CCCCC8CCCCC0000CCCCCCCCCCCCCC8888CCCCCCCCC
    0000CCCC00000000CCCC8888CCCCCCC0000CCCC0000000000CCCC8888CCC0000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 17
  object lbMasterVolume: TLabel
    Left = 8
    Top = 8
    Width = 89
    Height = 17
    Caption = 'Master volume'
  end
  object tbMaster: TTrackBar
    Left = 8
    Top = 32
    Width = 257
    Height = 25
    Max = 100
    TabOrder = 0
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = tbMasterChange
  end
  object gbRecordInput: TGroupBox
    Left = 8
    Top = 64
    Width = 257
    Height = 65
    Caption = ' Record input '
    TabOrder = 1
    object btnStartInput: TButton
      Left = 8
      Top = 24
      Width = 121
      Height = 25
      Caption = 'Start'
      TabOrder = 0
      OnClick = btnStartInputClick
    end
    object btnStopInput: TButton
      Left = 136
      Top = 24
      Width = 113
      Height = 25
      Caption = 'Stop'
      Enabled = False
      TabOrder = 1
      OnClick = btnStopInputClick
    end
  end
  object gbRecordLoopback: TGroupBox
    Left = 8
    Top = 136
    Width = 257
    Height = 65
    Caption = ' Record loopback '
    TabOrder = 2
    object btnStartLoopback: TButton
      Left = 8
      Top = 24
      Width = 121
      Height = 25
      Caption = 'Start'
      TabOrder = 0
      OnClick = btnStartLoopbackClick
    end
    object btnStopLoopback: TButton
      Left = 136
      Top = 24
      Width = 113
      Height = 25
      Caption = 'Stop'
      Enabled = False
      TabOrder = 1
      OnClick = btnStopLoopbackClick
    end
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'wav'
    Filter = 'Wave (*.wav)|*.wav'
    Left = 160
  end
end
