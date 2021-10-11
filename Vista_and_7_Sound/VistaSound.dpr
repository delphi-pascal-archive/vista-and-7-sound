// (c) Ter-Osipov Alex V. as known as Eraser on delphimaster.ru. 2009

program VistaSound;

uses
  Forms,
  MainForm in 'MainForm.pas' {fmMain},
  MMDeviceAPI in 'MMDeviceAPI.pas',
  WaveUtils in 'WaveUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
