unit FH.CARBONAPI;

interface

uses
  System.SysUtils,
  System.Variants,
  System.Classes,
  IdGlobal,
  IdIOHandler,
  IdTCPClient;
type
  ICarbonClient = interface

    function SetHost(AValue: string): ICarbonClient;
    function SetPort(AValue: word): ICarbonClient;
    function SetASync(AValue: boolean): ICarbonClient;

    procedure Execute;
    function Complete(OnComplete: TProc<string>): ICarbonClient;
    function Error(OnError: TProc<string>): ICarbonClient;
    function Command(const bstrCommand : string): ICarbonClient;
    function ServerVersion(): ICarbonClient;
    function ProfileList(): ICarbonClient;
    function GetNodeStatus(): ICarbonClient;
    function GetServerNodeStatus(): ICarbonClient;
    function JobQueryInfo(JobGuid: string): ICarbonClient;
  end;


  TCarbonClient = class(TInterfacedObject, ICarbonClient)
  private const
    CarbonAPIVer      = '1.2';
    CarbonApiFooter   = 'CarbonAPIXML1';
    CarbonApiPort     = 1120;
  private
    FASync        : boolean;
    FHost         : string;
    FPort         : word;
    FEncoding     : TEncoding;
    FCommand      : string;
    FOnComplete   : TProc<string>;
    FOnError      : TProc<string>;
    FSelf         : ICarbonClient;

    procedure DoComplete(const bstrReturn: string);
    procedure DoError(const errorMessage: string);
    procedure CarbonCommand(const bstrCommand : string; OnReturn: TProc<string>; OnError: TProc<string>; ASync : boolean = true);

  public
    constructor Create(); overload;
    destructor Destroy; override;
    class function Create(const Host: string): ICarbonClient; overload;

    procedure Execute;
    function SetASync(AValue: boolean): ICarbonClient;
    function SetHost(AValue: string): ICarbonClient;
    function SetPort(AValue: word): ICarbonClient;
    function Command(const bstrCommand : string): ICarbonClient;
    function Complete(OnComplete: TProc<string>): ICarbonClient;
    function Error(OnError: TProc<string>): ICarbonClient;

    function ServerVersion(): ICarbonClient;
    function ProfileList(): ICarbonClient;
    function GetNodeStatus(): ICarbonClient;
    function GetServerNodeStatus(): ICarbonClient;
    function JobQueryInfo(JobGuid: string): ICarbonClient;
  end;


implementation

(* ------------------------------------------------------------------------- *)
constructor TCarbonClient.Create();
begin
  inherited Create;
  FEncoding := TEncoding.UTF8;
  FPort := CarbonApiPort;
  FASync := true;
  FSelf := Self;
end;

destructor TCarbonClient.Destroy;
begin
  inherited Destroy;
end;

class function TCarbonClient.Create(const Host: string): ICarbonClient;
var
  LCarbonClient : ICarbonClient;
begin
  LCarbonClient := TCarbonClient.Create();
  result := LCarbonClient.SetHost(Host);
end;

procedure TCarbonClient.CarbonCommand(const bstrCommand : string; OnReturn: TProc<string>; OnError: TProc<string>; ASync : boolean = true);
var
  LWorkThread : TThread;
begin
    LWorkThread := TThread.CreateAnonymousThread(
      procedure()
      var
        LResponse : string;
        LBuffer   : TIdBytes;
        LSize     : integer;
        LTcpClient : TIdTcpClient;
      begin
        TThread.NameThreadForDebugging(Format('FH.CARBONAPI.CARBONCOMMAND.%d', [TThread.CurrentThread.ThreadID]), TThread.CurrentThread.ThreadID);
        LTcpClient := TIdTcpClient.Create(nil);
        try
          try
            LTcpClient.Host := Self.FHost;
            LTcpClient.Port := Self.FPort;
            LTcpClient.ReadTimeout := 1000;
            LTcpClient.Connect;
            if not LTcpClient.Connected then
              raise Exception.Create('Client not connected to carbon server');

            LTcpClient.IOHandler.Write(Format('%s %d %s', [TCarbonClient.carbonApiFooter, bstrCommand.Length, bstrCommand]), IndyTextEncoding(FEncoding));

            if LTcpClient.IOHandler.InputBufferIsEmpty then
              LTcpClient.IOHandler.CheckForDataOnSource(IdTimeoutInfinite);

            LResponse := LTcpClient.IOHandler.WaitFor(Format('%s ', [CarbonApiFooter]), true, false, nil, 1000);
            LResponse := LTcpClient.IOHandler.WaitFor(' ', true, false, nil, 1000);
            try
              LSize := StrToInt(LResponse);
              LTcpClient.IOHandler.ReadBytes(LBuffer, LSize);
            except
              repeat
                AppendByte(LBuffer, LTcpClient.IOHandler.ReadByte);
              until LTcpClient.IOHandler.InputBufferIsEmpty;
            end;

            LResponse := BytesToString(LBuffer);

            if assigned(OnReturn) then
              OnReturn(LResponse);

            //LTcpClient.IOHandler.CheckForDisconnect(true, false);

          except
            on e: Exception do
            begin
              if assigned(OnError) then
                OnError(E.Message);
            end;
          end;
        finally
          LTcpClient.Destroy;
        end;
      end
    );

    if ASync then
    begin
      LWorkThread.Start;
    end else
    begin
      LWorkThread.FreeOnTerminate := false;
      LWorkThread.Start;
      LWorkThread.WaitFor;
      FreeAndNil(LWorkThread);
    end;

end;

function TCarbonClient.SetHost(AValue: string): ICarbonClient;
begin
  if Length(AValue) > 0 then
    FHost := AValue;
  result := self;
end;

function TCarbonClient.SetASync(AValue: boolean): ICarbonClient;
begin
  FASync := AValue;
  result := self;
end;

function TCarbonClient.SetPort(AValue: word): ICarbonClient;
begin
  FPort := AValue;
  result := self;
end;

procedure TCarbonClient.Execute;
begin
 CarbonCommand(FCommand,
    procedure(bstrReturn: string)
    begin
      DoComplete(bstrReturn);
      FSelf := nil;
    end,
    procedure(errorMessage: string)
    begin
      DoError(errorMessage);
      FSelf := nil;
    end, FASync);

end;

procedure TCarbonClient.DoComplete(const bstrReturn: string);
begin
  if assigned(FOnComplete) then
    FOnComplete(bstrReturn);
end;

procedure TCarbonClient.DoError(const errorMessage: string);
begin
  if assigned(FOnError) then
    FOnError(errorMessage);
end;

function TCarbonClient.Complete(OnComplete: TProc<string>): ICarbonClient;
begin
  FOnComplete := OnComplete;
  result := self;
end;

function TCarbonClient.Error(OnError: TProc<string>): ICarbonClient;
begin
  FOnError := OnError;
  result := self;
end;

function TCarbonClient.Command(const bstrCommand : string): ICarbonClient;
begin
  FCommand  := bstrCommand;
  result := self;
end;

function TCarbonClient.ServerVersion(): ICarbonClient;
const
  bstrCommand = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'+
                '<cnpsXML CarbonAPIVer="1.2" TaskType="Version" />';
begin
  FCommand  := bstrCommand;
  result := self;
end;

////
//  Returns Global Node Settings including
//  Enabled.DWD, Priority.DWD and Slots.DWD in the
//  element <NodeStatus>
function TCarbonClient.GetNodeStatus(): ICarbonClient;
const
  bstrCommand = '<?xml version="1.0" encoding="UTF-8"?>'+
                '<cnpsXML CarbonAPIVer="1.2" TaskType="NodeCommand">'+
                '<NodeCommand Command="GetNodeStatus" NodeIP="127.0.0.1" />'+
                '</cnpsXML>';
begin
  FCommand  := bstrCommand;
  result := self;
end;

////
//  Returns Server Settings for the Node including
//  Enabled.DWD, Priority.DWD, Slots.DWD and
//  FreeSlots.DWD in the element
//  <ServerNodeStatus>
function TCarbonClient.GetServerNodeStatus(): ICarbonClient;
const
  bstrCommand = '<?xml version="1.0" encoding="UTF-8"?>'+
                '<cnpsXML CarbonAPIVer="1.2" TaskType="NodeCommand">'+
                '<NodeCommand Command="GetServerNodeStatus" NodeIP="127.0.0.1" />'+
                '</cnpsXML>';
begin
  FCommand  := bstrCommand;
  result := self;
end;

/////
//  Returns an informational structure for this job in the element
//  <JobInfo>
function TCarbonClient.JobQueryInfo(JobGuid: string): ICarbonClient;
begin
  FCommand  := Format('<?xml version="1.0" encoding="UTF-8"?>'+
                      '<cnpsXML CarbonAPIVer="1.2" TaskType="JobCommand">'+
                      '<JobCommand Command="QueryInfo" GUID="%s"/>'+
                      '</cnpsXML>', [JobGuid]);
  result := self;
end;

function TCarbonClient.ProfileList(): ICarbonClient;
const
  bstrCommand = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'+
                '<cnpsXML CarbonAPIVer="1.2" TaskType="ProfileList">'+
                '<ProfileAttributes ProfileType="Destination" />'+
                '</cnpsXML>';
begin
  FCommand  := bstrCommand;
  result := self;
end;

end.

