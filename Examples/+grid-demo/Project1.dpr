program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  avutil in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libavutil/avutil.pas',
  avcodec in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libavcodec/avcodec.pas',
  avformat in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libavformat/avformat.pas',
  avfilter in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libavfilter/avfilter.pas',
  swresample in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libswresample/swresample.pas',
  postprocess in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libpostproc/postprocess.pas',
  avdevice in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9./libavdevice/avdevice.pas',
  swscale in '../../../svn/ffmpeg/trunk/ffmpeg-20140810-git-e18d9d9/libswscale/swscale.pas',
  Xml.VerySimple in '../../../svn/uses/trunk/verysimplexml-2.0.1/Source/Xml.VerySimple.pas',
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
