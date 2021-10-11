// (c) Ter-Osipov Alex V. as known as Eraser on delphimaster.ru. 2009

unit WaveUtils;

interface

uses
  SysUtils, Windows, Classes, MMSystem;

const
  WAVE_FORMAT_EXTENSIBLE = $FFFE;
  WAVE_FORMAT_IEEE_FLOAT = $0003;
  KSDATAFORMAT_SUBTYPE_PCM: TGuid = '{00000001-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_IEEE_FLOAT: TGuid = '{00000003-0000-0010-8000-00aa00389b71}';

type
  PWaveFormatExtensible = ^TWaveFormatExtensible;
  TWaveFormatExtensible = packed record
    Format : TWaveFormatEx;
    case Byte of
      0: (ValidBitsPerSample : Word;   // bits of precision
          ChannelMask        : LongWord;  // which channels are present in stream
          SubFormat          : TGUID);
      1: (SamplesPerBlock    : Word);  // valid if wBitsPerSample = 0
      2: (Reserved           : Word);  // If neither applies, set to zero.
  end;

  TWaveImage = class
  private
    FData: TStream;
    FTotalSizeOffset, FDataOffset: Cardinal;
  public
    constructor Create(ADataStream: TStream);

    procedure InitHeader(Wfx: TWaveFormatEx);
    procedure CorretHeader;
  end;

implementation

{ TWaveImage }

procedure TWaveImage.CorretHeader;
var
  cBuffer: Cardinal;
begin
  // ������������ ����� ������.
  if FData.Size > FTotalSizeOffset + SizeOf(FTotalSizeOffset) then
  begin
    FData.Position := FTotalSizeOffset;
    cBuffer := FData.Size - 8;
    FData.Write(cBuffer, SizeOf(Cardinal));
  end;

  // ������������ ������ ����� ������.
  if FData.Size > FDataOffset + SizeOf(FDataOffset) then
  begin
    FData.Position := FDataOffset;
    cBuffer := FData.Size - FDataOffset - SizeOf(Cardinal);
    FData.Write(cBuffer, SizeOf(Cardinal));
  end;
end;

constructor TWaveImage.Create(ADataStream: TStream);
begin
  inherited Create();

  FData := ADataStream;
end;

procedure TWaveImage.InitHeader(Wfx: TWaveFormatEx);
var
  FOURCC: array[0..3] of AnsiChar;
  cBuffer: Cardinal;
begin
  Wfx.wFormatTag := WAVE_FORMAT_PCM;

  FData.Position := 0;
  FData.Size := 0;

  // ������� FOURCC ��� wav-�����.
  FOURCC := 'RIFF';
  FData.Write(FOURCC, Length(FOURCC));

  // ����� ������ - ��������� (8 ����).
  FTotalSizeOffset := FData.Position;
  cBuffer := 0;
  FData.Write(cBuffer, SizeOf(Cardinal));

  // ������� FOURCC WAVE.
  FOURCC := 'WAVE';
  FData.Write(FOURCC, Length(FOURCC));

  // ������� FOURCC fmt.
  FOURCC := 'fmt ';
  FData.Write(FOURCC, Length(FOURCC));

  // ������ TWaveFormatEx.
  cBuffer := SizeOf(TWaveFormatEx);
  FData.Write(cBuffer, SizeOf(Cardinal));

  // ������� ������ ������ TWaveFormatEx.
  FData.Write(Wfx, SizeOf(TWaveFormatEx));

  // ������� FOURCC ������ ����� ������.
  FOURCC := 'data';
  FData.Write(FOURCC, Length(FOURCC));

  // ������ ����� ������.
  FDataOffset := FData.Position;
  cBuffer := 0;
  FData.Write(cBuffer, SizeOf(Cardinal));
end;

end.
