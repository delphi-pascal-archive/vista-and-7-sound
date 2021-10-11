// (c) Ter-Osipov Alex V. as known as Eraser on delphimaster.ru. 2009

unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, MMDeviceAPI, StdCtrls, ComObj, ActiveX, ComCtrls, MMSystem;

type
  TInputRecordThread = class(TThread)
  private
    FData: TMemoryStream;
    FLoopback: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;

    property Data: TMemoryStream read FData;
    property Loopback: Boolean read FLoopback write FLoopback;
  end;

  TfmMain = class(TForm)
    tbMaster: TTrackBar;
    gbRecordInput: TGroupBox;
    btnStartInput: TButton;
    btnStopInput: TButton;
    SaveDialog: TSaveDialog;
    lbMasterVolume: TLabel;
    gbRecordLoopback: TGroupBox;
    btnStartLoopback: TButton;
    btnStopLoopback: TButton;
    procedure tbMasterChange(Sender: TObject);
    procedure btnStartInputClick(Sender: TObject);
    procedure btnStopInputClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStartLoopbackClick(Sender: TObject);
    procedure btnStopLoopbackClick(Sender: TObject);
  private
    FInputRecordThread, FLoopbackRecordThread: TInputRecordThread;
    FMMDev: IMMDevice;
    FMMDevEnum: IMMDeviceEnumerator;
    FEndpoint: IAudioEndpointVolume;
    FVolumeUpdating: Boolean;

    procedure InitMasterVolume;
    procedure UpdateMasterVolume;
    procedure InputRecordTerminateHandler(Sender: TObject);
  public
    property VolumeUpdating: Boolean read FVolumeUpdating write FVolumeUpdating;
  end;

  TMyEndpointVolumeCallback = class(TInterfacedObject, IAudioEndpointVolumeCallback)
  public
    function OnNotify(pNotify: PAUDIO_VOLUME_NOTIFICATION_DATA): HRESULT; stdcall;
  end;

var
  fmMain: TfmMain;

implementation

uses WaveUtils;

{$R *.dfm}

procedure TfmMain.btnStartInputClick(Sender: TObject);
begin
  btnStartInput.Enabled := False;
  btnStopInput.Enabled := True;

  FInputRecordThread := TInputRecordThread.Create(True);
  FInputRecordThread.OnTerminate := InputRecordTerminateHandler;
  FInputRecordThread.Resume;
end;

procedure TfmMain.btnStartLoopbackClick(Sender: TObject);
begin
  btnStartLoopback.Enabled := False;
  btnStopLoopback.Enabled := True;

  FLoopbackRecordThread := TInputRecordThread.Create(True);
  FLoopbackRecordThread.Loopback := True;
  FLoopbackRecordThread.OnTerminate := InputRecordTerminateHandler;
  FLoopbackRecordThread.Resume;
end;

procedure TfmMain.btnStopInputClick(Sender: TObject);
begin
  FInputRecordThread.Terminate;
end;

procedure TfmMain.btnStopLoopbackClick(Sender: TObject);
begin
  FLoopbackRecordThread.Terminate;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  // Только для висты и выше.
  if (Win32Platform <> VER_PLATFORM_WIN32_NT) or (Win32MajorVersion < 6) then
  begin
    ShowMessage('For Vista and above only.');
    Application.Terminate;
    Exit;
  end;

  InitMasterVolume;
end;

procedure TfmMain.InitMasterVolume;
var
  PropVar: ^tag_inner_PROPVARIANT;
  MyEndpointVolumeCallback: IAudioEndpointVolumeCallback;
begin
  PropVar := nil;
  CoCreateInstance(CLASS_MMDeviceEnumerator, nil, CLSCTX_ALL, IID_IMMDeviceEnumerator,
    FMMDevEnum);

  FMMDevEnum.GetDefaultAudioEndpoint(eRender, eMultimedia, FMMDev);
  FMMDev.Activate(IID_IAudioEndpointVolume, CLSCTX_ALL, PropVar^, Pointer(FEndPoint));

  // Volume changes handler.
  MyEndpointVolumeCallback := TMyEndpointVolumeCallback.Create;
  FEndPoint.RegisterControlChangeNotify(MyEndpointVolumeCallback);

  UpdateMasterVolume;
end;

procedure TfmMain.InputRecordTerminateHandler(Sender: TObject);
begin
  if TInputRecordThread(Sender).Loopback then
  begin
    btnStartLoopback.Enabled := True;
    btnStopLoopback.Enabled := False;
  end
  else
  begin
    btnStartInput.Enabled := True;
    btnStopInput.Enabled := False;
  end;

  if SaveDialog.Execute then
  begin
    TInputRecordThread(Sender).Data.Position := 0;
    TInputRecordThread(Sender).Data.SaveToFile(SaveDialog.FileName);
  end;
end;

procedure TfmMain.tbMasterChange(Sender: TObject);
begin
  if FVolumeUpdating then
    Exit;

  FEndPoint.SetMasterVolumeLevelScalar(tbMaster.Position / 100, nil);
end;

procedure TfmMain.UpdateMasterVolume;
var
  VolLevel: Single;
begin
  FEndPoint.GetMasterVolumeLevelScalar(VolLevel);
  tbMaster.Position := Round(VolLevel * 100);
end;

{ TMyEndpointVolumeCallback }

function TMyEndpointVolumeCallback.OnNotify(
  pNotify: PAUDIO_VOLUME_NOTIFICATION_DATA): HRESULT;
begin
  Result := S_OK;

  fmMain.VolumeUpdating := True;
  try
    fmMain.tbMaster.Position := Round(pNotify.fMasterVolume * 100);
  finally
    fmMain.VolumeUpdating := False;
  end;
end;

{ TInputRecordThread }

constructor TInputRecordThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);

  FData := TMemoryStream.Create;
end;

destructor TInputRecordThread.Destroy;
begin
  FData.Free;

  inherited;
end;

// http://msdn.microsoft.com/en-us/library/ms678709(VS.85).aspx
procedure TInputRecordThread.Execute;
const
  REFTIMES_PER_SEC = 10000000;
  REFTIMES_PER_MILLISEC = 10000;
var
  MMDev: IMMDevice;
  MMDevEnum: IMMDeviceEnumerator;
  AudioClient: IAudioClient;
  CaptureClient: IAudioCaptureClient;
  PropVar: ^tag_inner_PROPVARIANT;
  hnsRequestedDuration, hnsActualDuration: Int64;
  pWfx, pCloseWfx: PWaveFormatEx;
  BufferFrameCount, NumFramesAvailable, Flags, StreamFlags, PacketLength, FrameSize: Cardinal;
  pData: PByte;
  uDummy: UInt64;
  Returned: HRESULT;
  Wave: TWaveImage;
  Empty: array of byte;
  pEx: PWaveFormatExtensible;
begin
  FreeOnTerminate := True;
  pCloseWfx := nil;
  uDummy := 0;
  PropVar := nil;

  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  CoCreateInstance(CLASS_MMDeviceEnumerator,
    nil,
    CLSCTX_ALL,
    IID_IMMDeviceEnumerator,
    MMDevEnum);

  if FLoopback then
    Returned := MMDevEnum.GetDefaultAudioEndpoint(eRender, eConsole, MMDev)
  else
    Returned := MMDevEnum.GetDefaultAudioEndpoint(eCapture, eConsole, MMDev);

  if Returned <> S_OK then
  begin
    OleCheck(Returned);
    Exit;
  end;

  Returned := MMDev.Activate(IID_IAudioClient, CLSCTX_ALL, PropVar^, Pointer(AudioClient));
  if Returned <> S_OK then
  begin
    OleCheck(Returned);
    Exit;
  end;

  AudioClient.GetMixFormat(pWfx);

  // http://www.ambisonic.net/mulchaud.html
  case pWfx.wFormatTag of
    WAVE_FORMAT_IEEE_FLOAT:
      begin
        pWfx.wFormatTag := WAVE_FORMAT_PCM;
        pWfx.wBitsPerSample := 16;
        pWfx.nBlockAlign := pWfx.nChannels * pWfx.wBitsPerSample div 8;
        pWfx.nAvgBytesPerSec := pWfx.nBlockAlign * pWfx.nSamplesPerSec;
      end;
    WAVE_FORMAT_EXTENSIBLE:
      begin
        pEx := PWaveFormatExtensible(pWfx);
        if not IsEqualGUID(KSDATAFORMAT_SUBTYPE_IEEE_FLOAT, pEx.SubFormat) then
        begin
          Exit;
        end;

        pEx.SubFormat := KSDATAFORMAT_SUBTYPE_PCM;
        pEx.ValidBitsPerSample := 16;
        pWfx.wBitsPerSample := 16;
        pWfx.nBlockAlign := pWfx.nChannels * pWfx.wBitsPerSample div 8;
        pWfx.nAvgBytesPerSec := pWfx.nBlockAlign * pWfx.nSamplesPerSec;
      end;
    else Exit;
  end;

  if AudioClient.IsFormatSupported(AUDCLNT_SHAREMODE_SHARED, pWfx, pCloseWfx) <> S_OK then
  begin
    Exit;
  end;

  // Размер фрэйма.
  FrameSize := pWfx.wBitsPerSample * pWfx.nChannels div 8;

  hnsRequestedDuration := REFTIMES_PER_SEC;
  if FLoopback then
    StreamFlags := AUDCLNT_STREAMFLAGS_LOOPBACK
  else
    StreamFlags := 0;
  Returned := AudioClient.Initialize(AUDCLNT_SHAREMODE_SHARED,
    StreamFlags,
    hnsRequestedDuration,
    0,
    pWfx,
    nil);
  if Returned <> S_OK then
  begin
    Exit;
  end;

  AudioClient.GetBufferSize(BufferFrameCount);

  Returned := AudioClient.GetService(IID_IAudioCaptureClient, Pointer(CaptureClient));
  if Returned <> S_OK then
  begin
    Exit;
  end;

  // Calculate the actual duration of the allocated buffer.
  hnsActualDuration := REFTIMES_PER_SEC * BufferFrameCount div pWfx.nSamplesPerSec;

  // Start recording.
  AudioClient.Start();

  Wave := TWaveImage.Create(FData);
  try
    Wave.InitHeader(pWfx^);

    // Each loop fills about half of the shared buffer.
    while not Terminated do
    begin
      // Sleep for half the buffer duration.
      Sleep(hnsActualDuration div REFTIMES_PER_MILLISEC div 2);

      CaptureClient.GetNextPacketSize(PacketLength);

      while PacketLength <> 0 do
      begin
        // Get the available data in the shared buffer.
        pData := nil;
        Returned := CaptureClient.GetBuffer(pData,
          NumFramesAvailable,
          Flags,
          uDummy,
          uDummy);

        if Returned <> S_OK then
        begin
          Exit;
        end;

        if (Flags or Cardinal(AUDCLNT_BUFFERFLAGS_SILENT)) = Flags then
        begin
          pData := nil;  // Tell CopyData to write silence.
        end;

        if pData = nil then
        begin
          SetLength(Empty, NumFramesAvailable * FrameSize);
          FillChar(Empty[0], Length(Empty), 0);
          FData.Write(Empty[0], Length(Empty));
        end
        else
        begin
          // Сохраняем данные.
          FData.Write(pData^, NumFramesAvailable * FrameSize);
        end;

        CaptureClient.ReleaseBuffer(NumFramesAvailable);
        CaptureClient.GetNextPacketSize(PacketLength);
      end;
    end;

    // Останавливаем запись.
    AudioClient.Stop();

    // Откорретируем заголовок.
    Wave.CorretHeader;
    FData.Position := 0;
  finally
    Wave.Free;

    if pWfx <> nil then
      CoTaskMemFree(pWfx);
  end;
end;

end.
