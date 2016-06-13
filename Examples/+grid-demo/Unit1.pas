unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.threading,
  IdBaseComponent, IdComponent, IdTCPConnection,  FMX.StdCtrls, System.Math, System.Rtti,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Menus, FMX.Edit, System.IOUtils,
  FMX.Layouts, FMX.ExtCtrls, FMX.Objects, System.Generics.Collections, FMX.ListBox,
  FMX.Edit.Autocomplete, System.SyncObjs, FMX.TabControl, FMX.Ani, FMX.ComboEdit,
  avutil,
  avcodec,
  avformat,
  avfilter,
  swresample,
  postprocess,
  avdevice,
  swscale,
  Xml.VerySimple,
  FH.CARBONAPI,
  FH.CARBONAPI.PROFILE;

const
  cCarbonRational : TAVRational = (num : 1; den : 27000);

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    ListBox1: TListBox;
    TabItem2: TTabItem;
    GroupBox3: TGroupBox;
    DropTarget1: TDropTarget;
    Edit4: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Edit5: TEdit;
    Button5: TButton;
    TabItem3: TTabItem;
    Memo1: TMemo;
    TabItem4: TTabItem;
    DebugMemo: TMemo;
    Splitter1: TSplitter;
    Memo3: TMemo;
    Panel1: TPanel;
    GroupBox2: TGroupBox;
    Button2: TButton;
    Edit1: TEdit;
    Button12: TButton;
    ListBoxHeader1: TListBoxHeader;
    Edit2: TEdit;
    Edit3: TEdit;
    Button3: TButton;
    StyleBook1: TStyleBook;
    Layout1: TLayout;
    GroupBox1: TGroupBox;
    GroupBox4: TGroupBox;
    Edit7: TEdit;
    Edit8: TEdit;
    GroupBox5: TGroupBox;
    Button8: TButton;
    Button1: TButton;
    ComboEdit1: TComboEdit;
    Button4: TButton;
    ListBox2: TListBox;
    AniIndicator1: TAniIndicator;
    LoockPanel: TPanel;
    GroupBox6: TGroupBox;
    Button6: TButton;
    ProgressBar1: TProgressBar;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure DropTarget1Dropped(Sender: TObject; const [Ref] Data: TDragObject;
      const [Ref] Point: TPointF);
    procedure Button5Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DoItemConnectClick(Sender: TObject);
    procedure DoPresetChange(Sender: TObject);
    procedure DoPresentationNameChoosing(Sender: TObject; var PresenterName: string);
    procedure Button1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    procedure OpenSource(var fmt_ctx: PAVFormatContext; FileName: string);
    procedure JoinMedia(SourceFiles : TArray<string>; TargetFile: string; OnFinish: TProc; OnProgress: TProc<int64>; OnError: TProc<string>);
    procedure GetKeyFrame(const FileName: string; var KeyFrames  : TArray<int64>;
                                                  var FirstFrame : Int64;
                                                  var LastFrame : Int64;
                                                  var FrameCount: int64);
    procedure GetCarbonVersion(const Host: string; const Port: word; var Version: string);
    procedure GetCarbonSlots(const Host: string; const Port: word; var Slots: string);
    procedure GetCarbonPresetList(const Host: string; const Port: word; var PresetList: TArray<ICarbonProfile>);
    procedure TaskCallbackCreate(TaskGuid: string; TaskItem: TListBoxItem);
  public
    FKeyFrames      : TArray<int64>;
    FSourceNbFrames : int64;
    FChunk          : TArray<TPair<int64,int64>>;
  end;

var
  Form1: TForm1;


implementation

{$R *.fmx}

(* ------------------------------------------------------------------------- *)
procedure TForm1.DropTarget1Dropped(Sender: TObject;
  const [Ref] Data: TDragObject; const [Ref] Point: TPointF);
begin
  if Listbox1.Items.Count = 0 then
  begin
    showmessage('Add carbon servers');
    exit;
  end;
  Edit4.Text := Data.Files[0];
  Edit5.Text := System.IOUtils.TPath.GetDirectoryName(Edit4.Text) + '\';

  TThread.CreateAnonymousThread(procedure
  const
      frameSize = 1080000;
  var
      ItemInChunk   : integer;
      LTaskItem     : TListBoxItem;
      i             : integer;
      temp_arr      : TArray<int64>;
      LFirstFrame   : int64;
      LLastFrame    : int64;
  begin

    TThread.Synchronize(nil, procedure
    begin
      LoockPanel.Visible := true;
      ListBox2.Items.Clear;
      FSourceNbFrames := 0;
      SetLength(FKeyFrames, 0);
    end);
    try

      LFirstFrame := -1;
      LLastFrame := -1;
      GetKeyFrame(edit4.Text, FKeyFrames, LFirstFrame, LLastFrame, FSourceNbFrames);
      TThread.Synchronize(nil, procedure
      begin
        debugMemo.Lines.Add(format('source %s, Number Key Frames: %d, Total Frames: %d',[edit4.Text, length(FKeyFrames), FSourceNbFrames]));
        debugMemo.Lines.Add(format('source %s, FirstFrame: %d, LastFrame: %d',[edit4.Text, LFirstFrame, LLastFrame]));
      end);
      SetLength(FChunk, 0);
      ItemInChunk := Length(FKeyFrames) div listbox1.Items.Count;

      SetLength(temp_arr, listbox1.Items.Count);
      for I := 0 to listbox1.Items.Count - 1 do
      begin
        temp_arr[i] := FKeyFrames[i * ItemInChunk];
      end;

      SetLength(FChunk, listbox1.Items.Count);
      for I := 0 to listbox1.Items.Count - 1 do
      begin
        if i >= listbox1.Items.Count-1 then
        begin
          FChunk[i] := TPair<int64,int64>.Create(temp_arr[i], -1{LLastFrame}{FKeyFrames[high(FKeyFrames)]});
        end else
        if i = 0 then
        begin
          FChunk[i] := TPair<int64,int64>.Create(temp_arr[i] {-1}, temp_arr[i+1]);
        end else
          FChunk[i] := TPair<int64,int64>.Create(temp_arr[i], temp_arr[i+1]);
      end;

      TThread.Synchronize(nil, procedure
      var
        i : integer;
        LPreset       : TEdit;
        LPresetGUID   : string;
        LCarbonItem   : TListBoxItem;
      begin
        ListBox2.Items.Clear;
        for I := 0 to listbox1.Items.Count - 1 do
        begin
          LTaskItem  := TListBoxItem.Create(ListBox2);
          try
            LCarbonItem := listbox1.ItemByIndex(I);
            LPreset := (LCarbonItem.FindStyleResource('preset') as TEdit);
            LTaskItem.Height := 40;
            LTaskItem.StylesData['title.Text'] := format('ChunkID: %d', [i]);
            LTaskItem.StylesData['detail.Text'] := Format('Duration: %s sec',[string(av_ts2timestr((FChunk[i].Value div 1000) - (FChunk[i].Key div 1000), @cCarbonRational))]);
            LTaskItem.StylesData['preset_guid.Text'] := LPreset.TagString;
            LTaskItem.StylesData['preset_name.Text'] := LPreset.Text;
            LTaskItem.StylesData['carbon_host.Text'] := LCarbonItem.StylesData['host.Text'];
            LTaskItem.StylesData['carbon_port.Text'] := LCarbonItem.StylesData['port.Text'];
            LTaskItem.StylesData['inpoint.Text'] := IntToStr(FChunk[i].Key);
            LTaskItem.StylesData['outpoint.Text'] := IntToStr(FChunk[i].Value);
            LTaskItem.StyleLookup := '::freehand::chunkitem';
          finally
            ListBox2.AddObject(LTaskItem);
          end;
          DebugMemo.Lines.Add(format('inpoint: %d,  outpoint: %d', [FChunk[i].Key, FChunk[i].Value]));
        end;
      end);
    finally
      TThread.Synchronize(nil, procedure
      begin
        LoockPanel.Visible := false;
        if ListBox2.Items.Count > 0 then
          Form1.Button5.Enabled := true;
      end);
    end;
  end).Start;

end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  i, j : integer;
  LPresetList : TComboBox;
begin
  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    Listbox1.ItemByIndex(i).Data := nil;
  {
    LPresetList := (Listbox1.ItemByIndex(i).FindStyleResource('presets') as TCombobox);
    for J := 0 to LPresetList.Count - 1 do
    begin
      if LPresetList.Items.Objects[J] <> nil then
      begin
        IInterface(Pointer(LPresetList.Items.Objects[J]))._Release;
        LPresetList.Items.Objects[J] := nil;
      end;
    end;  }

  end;

end;

procedure TForm1.Button12Click(Sender: TObject);
var
  LCommand : string;
begin
  LCommand := memo1.Text;
  TCarbonClient.Create(edit7.Text).SetASync(false).Command(LCommand).Complete(
    procedure(bstrReturn: string)
    begin
      Form1.memo3.Text := bstrReturn;
    end).Error(
    procedure(errorMessage: string)
    begin
      Form1.memo3.Text := errorMessage;
    end
  ).Execute;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  LCommand : string;
begin
  LCommand := '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'+
              '<cnpsXML CarbonAPIVer="1.2" TaskType="JobList" />';

  TCarbonClient.Create(edit7.Text).Command(LCommand).Complete(
    procedure(bstrReturn: string)
    begin
      Form1.memo3.Text := bstrReturn;
    end).Error(
    procedure(errorMessage: string)
    begin
      Form1.memo3.Text := errorMessage;
    end
  ).Execute;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  LCommand : string;
begin
  LCommand := Format('<?xml version="1.0" encoding="UTF-8"?>'+
                      '<cnpsXML CarbonAPIVer="1.2" TaskType="JobCommand">'+
                      '<JobCommand Command="QueryInfo" GUID="%s"/>'+
                      '</cnpsXML>', [edit1.Text]);

  TCarbonClient.Create(edit7.Text).Command(LCommand).Complete(
    procedure(bstrReturn: string)
    begin
      Form1.memo3.Text := bstrReturn;
    end).Error(
    procedure(errorMessage: string)
    begin
      Form1.memo3.Text := errorMessage;
    end
  ).Execute;
end;

procedure TForm1.DoItemConnectClick(Sender: TObject);
  function FindItemParent(Obj: TFmxObject; ParentClass: TClass): TFmxObject;
    begin
      Result := nil;
      if Assigned(Obj.Parent) then
        if Obj.Parent.ClassType = ParentClass then
          Result := Obj.Parent
        else
          Result := FindItemParent(Obj.Parent, ParentClass);
    end;
var
  Item : TListBoxItem;
  O: TFMXObject;
  LCarbonClient : TCarbonClient;
begin
  Item := TListBoxItem(FindItemParent(Sender as TFmxObject,TListBoxItem));

  O := Item.FindStyleResource('host');

  O := Item.FindStyleResource('port');


    (Item.FindStyleResource('presets') as TCombobox).Items.Clear;
    Item.StylesData['version.Text'] := '-';
    (Sender as TButton).Text := 'Connect';

end;

procedure TForm1.DoPresetChange(Sender: TObject);
  function FindItemParent(Obj: TFmxObject; ParentClass: TClass): TFmxObject;
    begin
      Result := nil;
      if Assigned(Obj.Parent) then
        if Obj.Parent.ClassType = ParentClass then
          Result := Obj.Parent
        else
          Result := FindItemParent(Obj.Parent, ParentClass);
    end;
var
  LItem         : TListBoxItem;
  LPresetList   : TComboBox;
  LCarbonPreset : ICarbonProfile;

  Intf: IInterface;
begin
  LCarbonPreset := nil;
  LItem := TListBoxItem(FindItemParent(Sender as TFmxObject,TListBoxItem));
  LPresetList := (LItem.FindStyleResource('presets') as TCombobox);

  LCarbonPreset := ICarbonProfile(Pointer(LPresetList.Items.Objects[LPresetList.ItemIndex]));
  showmessage(LCarbonPreset.GUID);
  {
  Intf := IInterface(Pointer(LPresetList.Items.Objects[LPresetList.ItemIndex]));
  if Supports(Intf, ICarbonProfile, LCarbonPreset) then
  //LCarbonPreset := ICarbonProfile(Pointer(LPresetList.Items.Objects[LPresetList.ItemIndex]));
    showmessage(LCarbonPreset.GUID);  }
end;


procedure TForm1.GetCarbonVersion(const Host: string; const Port: word; var Version: string);
var
  LError    : string;
  LVersion  : string;
begin
  TCarbonClient.Create(Host).SetPort(Port).SetASync(false).ServerVersion.Complete(
  procedure(bstrReturn: string)
  var
    LReplySuccess         : string;
    LXmlDoc               : TXmlVerySimple;
    LReplyNode            : TXmlNode;
    i                     : integer;
  begin
    LXmlDoc := TXmlVerySimple.Create;
    try
      LXmlDoc.Text := bstrReturn;
      LReplyNode :=  LXmlDoc.ChildNodes.Find('Reply');
      LReplySuccess := LReplyNode.Attributes['Success'];
      if SameText(LReplySuccess, 'FALSE') then
        LError := LReplyNode.Attributes['Error'];
      LVersion := LReplyNode.Attributes['Version'];
    finally
      LXmlDoc.Free;
    end;
  end).Error(
  procedure(errorMessage: string)
  begin
    LError := errorMessage;
  end
  ).Execute;

  if not LError.IsEmpty then
    raise Exception.Create(LError);
    
  Version := LVersion;
end;

procedure TForm1.GetCarbonSlots(const Host: string; const Port: word; var Slots: string);
var
  LError        : string;
  LSlots        : string;
  LReplySuccess : string;
begin
  TCarbonClient.Create(Host).SetPort(Port).SetASync(false).GetNodeStatus.Complete(
  procedure(bstrReturn: string)
  var
    LReplySuccess         : string;
    LXmlDoc               : TXmlVerySimple;
    LReplyNode            : TXmlNode;
    LStatusNode           : TXmlNode;
    i                     : integer;
  begin
    LXmlDoc := TXmlVerySimple.Create;
    try
      LXmlDoc.Text := bstrReturn;
      LReplyNode :=  LXmlDoc.ChildNodes.Find('Reply');
      LReplySuccess := LReplyNode.Attributes['Success'];
      if SameText(LReplySuccess, 'FALSE') then
        LError := LReplyNode.Attributes['Error'];
      LStatusNode := LXmlDoc.DocumentElement.Find('NodeStatus');
      LSlots := LStatusNode.Attributes['Slots.DWD'];
    finally
      LXmlDoc.Free;
    end;
  end).Error(
  procedure(errorMessage: string)
  begin
    LError := errorMessage;
  end
  ).Execute;

  if not LError.IsEmpty then
    raise Exception.Create(LError);

  Slots := LSlots;
end;


procedure TForm1.GetCarbonPresetList(const Host: string; const Port: word; var PresetList: TArray<ICarbonProfile>);
var
  LError        : string;
  LSlots        : string;
  LReplySuccess : string;
  LPresetList   : TArray<ICarbonProfile>;
  I: Integer;
begin
  TCarbonClient.Create(Host).SetPort(Port).SetASync(false).ProfileList.Complete(
  procedure(bstrReturn: string)
  var
    LCarbonProfile        : ICarbonProfile;
    LReplySuccess         : string;
    NrOfProfiles          : string;
    LXmlDoc               : TXmlVerySimple;
    LReplyNode            : TXmlNode;
    LProfileList          : TXmlNodeList;
    LProfileNode          : TXmlNode;
    i                     : integer;
  begin
    LXmlDoc := TXmlVerySimple.Create;
    try
      LXmlDoc.Text := bstrReturn;
      LReplyNode :=  LXmlDoc.ChildNodes.Find('Reply');
      LReplySuccess := LReplyNode.Attributes['Success'];
      if SameText(LReplySuccess, 'FALSE') then
        LError := LReplyNode.Attributes['Error'];

      NrOfProfiles := LXmlDoc.DocumentElement.Find('ProfileList').Attributes['NrOfProfiles.DWD'];
      LProfileList := LXmlDoc.DocumentElement.Find('ProfileList').ChildNodes;
      for LProfileNode in LProfileList do
      begin
          LCarbonProfile := TCarbonProfile.Create;
          LCarbonProfile.Name := LProfileNode.Attributes['Name'];
          LCarbonProfile.Description := LProfileNode.Attributes['Description'];
          LCarbonProfile.Category := LProfileNode.Attributes['Category'];
          LCarbonProfile.GUID := LProfileNode.Attributes['GUID'];
          LCarbonProfile._AddRef;
          SetLength(LPresetList, Length(LPresetList)+1);
          LPresetList[High(LPresetList)] := LCarbonProfile;
      end;
    finally
      LXmlDoc.Free;
    end;
  end).Error(
  procedure(errorMessage: string)
  begin
              LError := errorMessage;
  end
  ).Execute;


  PresetList := LPresetList;

  if not LError.IsEmpty then
    raise Exception.Create(LError);
end;

procedure TForm1.DoPresentationNameChoosing(Sender: TObject; var PresenterName: string);
begin
  PresenterName := 'AutocompleteEdit-style';
end;

procedure TForm1.Button3Click(Sender: TObject);
begin

  TThread.CreateAnonymousThread(procedure
  var
    LCarbonItem         : TListBoxItem;
    i                   : integer;
    LVersion            : string;
    LSlots              : string;
    LError              : string;
    LProfiles           : TArray<ICarbonProfile>;
    LHost               : string;
    LPort               : string;
  begin
    LCarbonItem := nil;
    TThread.Synchronize(nil, procedure
    begin
      Button3.Enabled := false;
      LHost := edit2.Text;
      LPort := edit3.Text;
    end);
    try
      try
        // GET SERVER VERSION
        GetCarbonVersion(LHost, StrToInt(LPort), LVersion);
        // GET SERVER SLOTS
        GetCarbonSlots(LHost, StrToInt(LPort), LSlots);

        TThread.Synchronize(nil, procedure
          var
            i : integer;
          begin
            LCarbonItem  := TListBoxItem.Create(Form1.ListBox1);
            try
              LCarbonItem.Enabled := false;
              LCarbonItem.StylesData['version.Text'] := LVersion;
              LCarbonItem.StylesData['host.Text'] := LHost;
              LCarbonItem.StylesData['port.Text'] := LPort;
              LCarbonItem.StylesData['slots.Text'] := Format('server slots: %s',[LSlots]);
              LCarbonItem.StylesData['ConnectButton.OnClick'] := TValue.From<TNotifyEvent>(DoItemConnectClick);
              LCarbonItem.StylesData['presets.OnChange'] := TValue.From<TNotifyEvent>(DoPresetChange);
              LCarbonItem.StylesData['preset.OnPresentationNameChoosing'] := TValue.From<TPresenterNameChoosingEvent>(DoPresentationNameChoosing);

              LCarbonItem.Height := 0;
              LCarbonItem.Opacity := 0;
              LCarbonItem.StyleLookup := '::freehand::listboxitems';
            finally
              Form1.ListBox1.AddObject(LCarbonItem);
            end;
            index := max(0, ListBox1.ItemIndex);
            for I := Form1.ListBox1.Items.Count - 1 downto index + 1  do
            begin
              ListBox1.Exchange(Listbox1.ItemByIndex(i), Listbox1.ItemByIndex(i-1));
            end;
            Form1.ListBox1.ItemIndex := Index;
            LCarbonItem.AnimateFloat('Height', 50, 0.3);
            LCarbonItem.AnimateFloat('Opacity', 1, 0.5);
        end);


        // LOAD PRESETS
        GetCarbonPresetList(LHost, StrToInt(LPort), LProfiles);
      except
        on E:Exception do
        begin
          TThread.Synchronize(nil, procedure
          begin
            showmessage(E.Message);
          end);
        end;
      end;
    finally
      TThread.Synchronize(nil, procedure
      var
        LPresetEdit  : TEdit;
      begin
        if assigned(LCarbonItem) then
        begin
          LPresetEdit := (LCarbonItem.FindStyleResource('preset') as TEdit);
          LPresetEdit.LoadPresentation;
          LPresetEdit.Model.Data['suggestion_list'] := TValue.From<TArray<ICarbonProfile>>(LProfiles);
          LCarbonItem.Enabled := true;
        end;
        Button3.Enabled := true;
      end);
    end;
  end).Start;
end;


procedure TForm1.OpenSource(var fmt_ctx: PAVFormatContext; FileName: string);
var
  ret          : Integer;
begin
  if assigned(fmt_ctx) then
  begin
    avformat_close_input(fmt_ctx);
    fmt_ctx := nil;
  end;

  ret := avformat_open_input(fmt_ctx, PAnsiChar(ansistring(FileName)), nil, nil);
  if ret < 0 then
  begin
    raise Exception.Create(Format('Could not open input file ''%s''', [FileName]));
  end;

  ret := avformat_find_stream_info(fmt_ctx, nil);
  if ret < 0 then
  begin
    raise Exception.Create('Failed to retrieve input stream information');
  end;

  av_dump_format(fmt_ctx, 0, PAnsiChar(ansistring(FileName)), 0);
end;

procedure TForm1.JoinMedia(SourceFiles : TArray<string>; TargetFile: string; OnFinish: TProc; OnProgress: TProc<int64>; OnError: TProc<string>);
function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;
begin
  Inc(P, I);
  Result := P^;
end;
var
  i               : integer;
  ofmt            : PAVOutputFormat;
  ifmt_ctx        : PAVFormatContext;
  ofmt_ctx        : PAVFormatContext;
  in_stream       : PAVStream;
  out_stream      : PAVStream;
  pkt             : TAVPacket;
  offset_dts      : int64;
  offset_pts      : int64;
  new_chunk       : boolean;
begin
  ofmt := nil;
  ifmt_ctx := nil;
  ofmt_ctx := nil;
  try
    av_register_all();
    av_log_set_level(AV_LOG_DEBUG);

    if length(SourceFiles) < 0 then
      raise Exception.Create('Not Source files');

    if System.SysUtils.FileExists(TargetFile) then
      DeleteFile(TargetFile);

    for I := 0 to Length(SourceFiles) - 1 do
      if not System.SysUtils.FileExists(SourceFiles[i]) then
        raise Exception.Create(Format('Source file not exists',[SourceFiles[i]]));

    OpenSource(ifmt_ctx, SourceFiles[0]);

    avformat_alloc_output_context2(ofmt_ctx, nil, nil, PAnsiChar(ansistring(TargetFile)));
    if not Assigned(ofmt_ctx) then
      raise Exception.Create('Could not create output contex');
    try

      ofmt := ofmt_ctx.oformat;
      for i := 0 to ifmt_ctx.nb_streams - 1 do
      begin
          in_stream := PPtrIdx(ifmt_ctx.streams, i);
          if in_stream.codec.codec_type = AVMEDIA_TYPE_VIDEO then
          begin
            out_stream := nil;
            out_stream := avformat_new_stream(ofmt_ctx, in_stream.codec.codec);
            if not Assigned(out_stream) then
              raise Exception.Create('Failed allocating output stream');

            if avcodec_copy_context(out_stream.codec, in_stream.codec) < 0 then
              raise Exception.Create('Failed to copy context from input to output stream codec context');

            out_stream.codec.codec_tag := 0;
            if (ofmt_ctx.oformat.flags and AVFMT_GLOBALHEADER) <> 0 then
              out_stream.codec.flags := out_stream.codec.flags or CODEC_FLAG_GLOBAL_HEADER;
          end;
      end;
      av_dump_format(ofmt_ctx, 0, PAnsiChar(ansistring(TargetFile)), 1);

      if (ofmt.flags and AVFMT_NOFILE) = 0 then
      begin
        if  avio_open(ofmt_ctx.pb, PAnsiChar(ansistring(TargetFile)), AVIO_FLAG_WRITE) < 0 then
          raise Exception.Create(Format('Could not open output file %s', [TargetFile]));
      end;

      if avformat_write_header(ofmt_ctx, nil) < 0 then
        raise Exception.Create('Error occurred when opening output file');
      try
        for I := 0 to Length(SourceFiles) - 1 do
        begin
          OpenSource(ifmt_ctx, SourceFiles[i]);

          new_chunk := true;

          while av_read_frame(ifmt_ctx, @pkt) >= 0 do
          begin
            in_stream := nil;
            out_stream := nil;
            in_stream  := PPtrIdx(ifmt_ctx.streams, pkt.stream_index);
            //log_packet(ifmt_ctx, @pkt, 'in');

            (* copy video packet *)
            if in_stream.codec.codec_type = AVMEDIA_TYPE_VIDEO then
            begin
              out_stream := PPtrIdx(ofmt_ctx.streams, pkt.stream_index);
              if new_chunk then
              begin
                offset_dts := out_stream.cur_dts;
                offset_pts := av_stream_get_end_pts(out_stream);
                if offset_pts = AV_NOPTS_VALUE then offset_pts := 0;
                if offset_dts = AV_NOPTS_VALUE then offset_dts := 0;
                offset_dts := av_rescale_q_rnd(offset_dts, out_stream.time_base, in_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
                offset_pts := av_rescale_q_rnd(offset_pts, out_stream.time_base, in_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
                offset_dts := offset_dts + pkt.duration;
                offset_pts := offset_pts + pkt.duration;
                new_chunk := false;
              end;
              pkt.dts := av_rescale_q_rnd(offset_dts + pkt.dts, in_stream.time_base, out_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
              pkt.pts := av_rescale_q_rnd(offset_pts + pkt.pts, in_stream.time_base, out_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
              pkt.duration := av_rescale_q_rnd(pkt.duration, in_stream.time_base, out_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
              pkt.pos := -1;
              //log_packet(ofmt_ctx, @pkt, 'out');

              if av_interleaved_write_frame(ofmt_ctx, @pkt) < 0 then
                raise Exception.Create('Error muxing packet');

              if assigned(OnProgress) then
                OnProgress(out_stream.nb_frames);
            end;
            av_free_packet(@pkt);
          end;
        end;
      finally
        av_write_trailer(ofmt_ctx);
      end;
      if assigned(OnFinish) then
        OnFinish();
    finally
      if assigned(ifmt_ctx) then
        avformat_close_input(ifmt_ctx);
      (* close output *)
      if Assigned(ofmt_ctx) and ((ofmt.flags and AVFMT_NOFILE) = 0) then
        avio_closep(@ofmt_ctx.pb);
      avformat_free_context(ofmt_ctx);
    end;
  except
    on E:Exception do
    begin
      if assigned(OnError) then
        OnError(E.Message);
    end;
  end;
end;


procedure TForm1.GetKeyFrame(const FileName: string;  var KeyFrames  : TArray<int64>;
                                                      var FirstFrame : Int64;
                                                      var LastFrame : Int64;
                                                      var FrameCount: int64);

function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;
begin
  Inc(P, I);
  Result := P^;
end;

const
  OneFrameTime = 1080;
var
  ret     : integer;
  fmt_ctx : PAVFormatContext;
  pkt     : TAVPacket;
  LStream         : PAVStream;
  i               : integer;
  LFrameCount     : int64;
  LFrameTime      : int64;
  LFirstFrame     : int64;
  LLastFrame      : int64;
begin
  SetLength(KeyFrames, 0);
  LFrameCount := 0;
  LFirstFrame := -1;
  LLastFrame := -1;

  fmt_ctx := nil;
  av_register_all();

  ret := avformat_open_input(fmt_ctx, PAnsiChar(ansistring(FileName)), nil, nil);
  if ret < 0 then
  begin
    raise Exception.Create('Error Message');
  end;

  ret := avformat_find_stream_info(fmt_ctx, nil);
  if ret < 0 then
  begin
    raise Exception.Create('Failed to retrieve input stream information');
  end;

  av_dump_format(fmt_ctx, 0, PAnsiChar(ansistring(FileName)), 0);

  av_init_packet(@pkt);
  pkt.data:=nil;
  pkt.size:=0;

  while av_read_frame(fmt_ctx, @pkt) >= 0 do
  begin
    LStream := nil;
    LStream := PPtrIdx(fmt_ctx^.streams, pkt.stream_index);

    if LStream.codec.codec_type = AVMEDIA_TYPE_VIDEO then
    begin
      inc(LFrameCount);
      if LFirstFrame = -1 then
      begin
        if pkt.pts <> AV_NOPTS_VALUE then
          LFrameTime := av_rescale_q(pkt.pts, LStream^.time_base, cCarbonRational)
        else LFrameTime := av_rescale_q(pkt.dts, LStream^.time_base, cCarbonRational);
        LFirstFrame := LFrameTime * 1000;
        LFrameTime := max(LFrameTime, -1);
      end;
      if (pkt.flags and AV_PKT_FLAG_KEY) > 0 then
      begin
        if pkt.pts <> AV_NOPTS_VALUE then
          LFrameTime := av_rescale_q(pkt.pts, LStream^.time_base, cCarbonRational)
        else LFrameTime := av_rescale_q(pkt.dts, LStream^.time_base, cCarbonRational);
        LFrameTime := LFrameTime * 1000;
        LFrameTime := max(LFrameTime, -1);
        setLength(KeyFrames, Length(KeyFrames)+1);
        KeyFrames[High(KeyFrames)]:=  LFrameTime;
        {DebugMemo.Lines.Add(format('FRAME IS KEY: pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d, %d, - %d',
              [string(av_ts2str(pkt.pts)), string(av_ts2timestr(pkt.pts, @LStream^.time_base)),
              string(av_ts2str(pkt.dts)), string(av_ts2timestr(pkt.dts, @LStream^.time_base)),
              string(av_ts2str(pkt.duration)), string(av_ts2timestr(pkt.duration, @LStream^.time_base)),
              pkt.stream_index, LFrameTime , LFrameTime - OneFrameTime])); }

      end else
      begin
        ;
      end;
      if pkt.pts <> AV_NOPTS_VALUE then
        LFrameTime := av_rescale_q(pkt.pts, LStream^.time_base, cCarbonRational)
      else LFrameTime := av_rescale_q(pkt.dts, LStream^.time_base, cCarbonRational);
      LLastFrame := LFrameTime * 1000;
      LFrameTime := max(LFrameTime, -1);
    end;
    av_free_packet(@pkt);
  end;
  avformat_close_input(fmt_ctx);
  FrameCount := LFrameCount;
  LastFrame := LLastFrame;
  FirstFrame := LFirstFrame;
end;


procedure TForm1.TaskCallbackCreate(TaskGuid: string; TaskItem: TListBoxItem);
var
  LHost   : string;
  LPort   : string;

begin
  LHost := TaskItem.StylesData['carbon_host.Text'].AsString;
  LPort := TaskItem.StylesData['carbon_port.Text'].AsString;

  TThread.CreateAnonymousThread(procedure
  var
    LProgressDWD          : integer;
    LStatus               : string;
    LError                : string;
  begin
    TThread.NameThreadForDebugging('TaskCallbackCreate',  TThread.CurrentThread.ThreadID);
    LProgressDWD := 0;
    LStatus := '';
    while not SameText(LStatus, 'COMPLETED') do
    begin
      TCarbonClient.Create(LHost).SetPort(StrToInt(LPort)).SetASync(false).JobQueryInfo(TaskGuid).Complete(
        procedure(bstrReturn: string)
          var
            LReplySuccess         : string;
            LXmlDoc               : TXmlVerySimple;
            LReplyNode            : TXmlNode;
            i                     : integer;
          begin

            try
              LXmlDoc := TXmlVerySimple.Create;
              try
                LXmlDoc.Text := bstrReturn;
                LReplyNode :=  LXmlDoc.ChildNodes.Find('Reply');
                LReplySuccess := LReplyNode.Attributes['Success'];
                if SameText(LReplySuccess, 'FALSE') then
                begin
                  LError := LReplyNode.Attributes['Error'];
                  exit;
                end;

                try
                  LProgressDWD := StrToInt(LXmlDoc.DocumentElement.Find('JobInfo').Attributes['Progress.DWD']);
                except    end;

                //Preparing, Queued, Starting, Started, Stopping, Stopped, Pausing, Paused, Resuming, Completed, Error, Invalid
                LStatus := LXmlDoc.DocumentElement.Find('JobInfo').Attributes['Status'];
              finally
                LXmlDoc.Free;
              end;
            except
              LError := 'Internal error in complete procedure'
            end;
        end).Error(
        procedure(errorMessage: string)
        begin
          LError := format('Internal error %s', [errorMessage]);
        end
      ).Execute;

      TThread.Synchronize(nil, procedure
      begin
        TaskItem.StylesData['task_status.Text'] := LStatus;
        TaskItem.StylesData['task_error.Text'] := LError;
        TaskItem.StylesData['status.Hint'] := LStatus;
      end);

      if {SameText(LError, 'Job not found')} not LError.IsEmpty then
      begin
        TThread.Synchronize(nil, procedure
        begin
          TaskItem.StylesData['progress.Visible'] := false;
          TaskItem.StylesData['status.Fill.Color'] := TAlphaColor($FFFF0000);
          TaskItem.StylesData['status.Visible'] := true;
          DebugMemo.Lines.Add(format('TASK: %s - %s', [TaskGuid, LError]));
        end);
        exit;
      end;

      TThread.Synchronize(nil, procedure
      begin
        TaskItem.StylesData['progress.Value'] := LProgressDWD;
      end);

      if sameText(LStatus, 'Preparing') or sameText(LStatus, 'Queued') then
      begin
        TThread.Synchronize(nil, procedure
        begin
          if TaskItem.StylesData['progress.Visible'].AsBoolean then
            TaskItem.StylesData['progress.Visible'] := false;
          if TaskItem.StylesData['status.Fill.Color'].AsInteger <> TAlphaColor($FF333333) then
            TaskItem.StylesData['status.Fill.Color'] := TAlphaColor($FF333333);
          if not TaskItem.StylesData['status.Visible'].AsBoolean then
            TaskItem.StylesData['status.Visible'] := true;
        end);
      end else
      if sameText(LStatus, 'Started') then
      begin
        TThread.Synchronize(nil, procedure
        begin
          if not TaskItem.StylesData['progress.Visible'].AsBoolean then
            TaskItem.StylesData['progress.Visible'] := true;
          if TaskItem.StylesData['status.Visible'].AsBoolean then
            TaskItem.StylesData['status.Visible'] := false;
        end);
      end else
      if sameText(LStatus, 'Paused') then
      begin

      end else
      if sameText(LStatus, 'Error') or sameText(LStatus, 'Invalid')  or sameText(LStatus, 'STOPPED') then
      begin
        TThread.Synchronize(nil, procedure
        begin
          TaskItem.StylesData['progress.Visible'] := false;
          TaskItem.StylesData['status.Fill.Color'] := TAlphaColor($FFFF0000);
          TaskItem.StylesData['status.Visible'] := true;
        end);
        exit;
      end else
      if sameText(LStatus, 'Completed') then
      begin
        TThread.Synchronize(nil, procedure
        var
          i : integer;
          allTaskFinish : boolean;
        begin
          TaskItem.StylesData['progress.Visible'] := false;
          TaskItem.StylesData['status.Fill.Color'] := TAlphaColor($FFEEAC5C);
          TaskItem.StylesData['status.Visible'] := true;

          allTaskFinish := true;
          for I := 0 to Listbox2.Items.Count - 1 do
          begin
            if not sameText(Listbox2.ItemByIndex(i).StylesData['status.Hint'].AsString, 'Completed') then
            begin
              allTaskFinish := false;
              break;
            end;
          end;
          if allTaskFinish then
            Form1.Button6.Enabled := true;

        end);
        exit;
      end;

      TThread.Sleep(1000);
    end;
  end).Start;
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  LTaskItem       : TListBoxItem;
  LCommand        : string;
  LHost           : string;
  LPort           : string;
  LOut            : string;
  LIn             : string;
  LPreset         : string;
  LJobName        : string;
  LJobDescrip     : string;
  LChunkName      : string;
  I               : Integer;
begin
  DropTarget1.Enabled := false;
  Button5.Enabled := false;
  for I := 0 to ListBox2.Items.Count - 1 do
  begin
    LTaskItem := ListBox2.ItemByIndex(I);
    LChunkName := format('%s_%d', [System.IOUtils.TPath.GetFileNameWithoutExtension(edit4.Text), i, System.IOUtils.TPath.GetExtension(edit4.Text)]);
    LJobName := format('GridJob: %s', [LChunkName]);
    LJobDescrip := format('Source: %s', [edit4.Text]);
    LHost := LTaskItem.StylesData['carbon_host.Text'].AsString;
    LPort := LTaskItem.StylesData['carbon_port.Text'].AsString;
    LPreset := LTaskItem.StylesData['preset_guid.Text'].AsString;
    LIn := LTaskItem.StylesData['inpoint.Text'].AsString;
    LOut := LTaskItem.StylesData['outpoint.Text'].AsString;
    LCommand := Format('<?xml version="1.0" encoding="utf-8" ?>'+
                        '<cnpsXML CarbonAPIVer="1.2" TaskType="JobQueue" JobName="%s" Description="%s" User="FREEHAND">'+
                        '<ProjectSettings Stitching.DWD="1" Priority.DWD="255"/>'+
                        '<Sources>'+
                        '<Module_0 Filename="%s">'+
                        '<InOutPoints Inpoint_0.QWD="%s" Outpoint_0.QWD="%s"/>'+
                        '</Module_0>'+
                        '</Sources>'+
                        '<Destinations>'+
                        '<Module_0 PresetGUID="%s">'+
                        '<ModuleData CML_P_BaseFileName="%s" CML_P_Path="%s"/>'+
                        '</Module_0>'+
                        '</Destinations>'+
                        '</cnpsXML>',
                        [LJobName, LJobDescrip, edit4.Text, LIn, LOut, LPreset, LChunkName, edit5.Text]);


    DebugMemo.Lines.Add(LCommand);

    TCarbonClient.Create(LHost).SetPort(StrToInt(LPort)).SetASync(false).Command(LCommand).Complete(
      procedure(bstrReturn: string)
      var
        LReplySuccess         : string;
        LXmlDoc               : TXmlVerySimple;
        LReplyNode            : TXmlNode;
        i                     : integer;
        LError                : string;
        LTaskGuid             : string;
      begin
        DebugMemo.Lines.BeginUpdate;
        try
          DebugMemo.Lines.Add(bstrReturn);
        finally
          DebugMemo.Lines.EndUpdate;
        end;
        LXmlDoc := TXmlVerySimple.Create;
        try
          LXmlDoc.Text := bstrReturn;
          LReplyNode :=  LXmlDoc.ChildNodes.Find('Reply');
          LReplySuccess := LReplyNode.Attributes['Success'];
          if SameText(LReplySuccess, 'FALSE') then
            LError := LReplyNode.Attributes['Error'];
          LTaskGuid := LReplyNode.Attributes['GUID'];
          LTaskItem.StylesData['task_guid.Text'] := LTaskGuid;
          TaskCallbackCreate(LTaskGuid, LTaskItem);
        finally
          LXmlDoc.Free;
        end;
      end).Error(
      procedure(errorMessage: string)
      begin
        DebugMemo.Lines.BeginUpdate;
        try
          DebugMemo.Lines.Add(errorMessage);
        finally
          DebugMemo.Lines.EndUpdate;
        end;
      end
    ).Execute;
  end;

end;

procedure TForm1.Button6Click(Sender: TObject);
var
  i, j          : integer;
  LTaskItem     : TListBoxItem;
  LChunkName    : string;
  allTaskFinish : boolean;
  LFileChunks   : TArray<string>;
  LTargetFile   : string;
begin

  allTaskFinish := true;
  for I := 0 to Listbox2.Items.Count - 1 do
  begin
    if not sameText(Listbox2.ItemByIndex(i).StylesData['status.Hint'].AsString, 'Completed') then
    begin
      allTaskFinish := false;
      break;
    end;
  end;
  if not allTaskFinish then
    exit;

  SetLength(LFileChunks, Listbox2.Items.Count);
  for I := 0 to Listbox2.Items.Count - 1 do
  begin
    LTaskItem := Listbox2.ItemByIndex(i);
    LChunkName := format('%s_%d', [System.IOUtils.TPath.GetFileNameWithoutExtension(edit4.Text), i, System.IOUtils.TPath.GetExtension(edit4.Text)]);
    LFileChunks[i] := edit5.Text +'\'+ LChunkName + '.mp4';
  end;

  Button6.Enabled := false;
  ProgressBar1.Max := FSourceNbFrames;
  LTargetFile := edit5.Text +'\'+ System.IOUtils.TPath.GetFileNameWithoutExtension(edit4.Text) +'_out.mp4';
  debugMemo.Lines.Add(LTargetFile);
  debugMemo.Lines.Add(string.Join(';', LFileChunks));

  TThread.CreateAnonymousThread(
    procedure
    begin
      JoinMedia(LFileChunks,
          LTargetFile,
          procedure()
          begin
            TThread.Synchronize(nil, procedure
            begin
              DropTarget1.Enabled := true;
              Form1.ProgressBar1.Value := 0;
              Form1.Edit4.Text := '';
              Form1.Edit5.Text := '';
              ListBox2.Clear;
              showmessage('FINISH');
            end);
          end,
          procedure(AProgress : int64)
          begin
            TThread.Synchronize(nil, procedure
            begin
              ProgressBar1.Value := min(AProgress, ProgressBar1.Max);
            end);
          end,
          procedure(AMessage: string)
          begin
            TThread.Synchronize(nil, procedure
            begin
              showmessage(Format('ERROR: %s',[AMessage]));
            end);
          end
      );
    end).Start;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  TCarbonClient.Create(edit7.Text).ServerVersion.Complete(
    procedure(bstrReturn: string)
    begin
      Form1.memo3.Text := bstrReturn;
    end).Error(
    procedure(errorMessage: string)
    begin
      Form1.memo3.Text := errorMessage;
    end
  ).Execute;
end;

end.

