program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  avutil in '../../../ffmpeg-delphi/Include/libavutil/avutil.pas',
  avcodec in '../../../ffmpeg-delphi/Include/libavcodec/avcodec.pas',
  avformat in '../../../ffmpeg-delphi/Include/libavformat/avformat.pas',
  avfilter in '../../../ffmpeg-delphi/Include/libavfilter/avfilter.pas',
  swresample in '../../../ffmpeg-delphi/Include/libswresample/swresample.pas',
  postprocess in '../../../ffmpeg-delphi/Include/libpostproc/postprocess.pas',
  avdevice in '../../../ffmpeg-delphi/Include/libavdevice/avdevice.pas',
  swscale in '../../../ffmpeg-delphi/Include/libswscale/swscale.pas',
  Xml.VerySimple in '../../../../svn/uses/trunk/verysimplexml-2.0.1/Source/Xml.VerySimple.pas',
  FH.CARBONAPI in '../../Include/FH.CARBONAPI.pas',
  FH.CARBONAPI.PROFILE in '../../Include/FH.CARBONAPI.PROFILE.pas',

  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
