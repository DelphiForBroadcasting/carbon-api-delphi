unit FH.CARBONAPI.PROFILE;

interface

uses
  System.SysUtils, System.Variants, System.JSON;

type
  ICarbonProfile = interface
  ['{3C3DA828-3C70-44DD-8BFD-526729C87D9F}']
    procedure SetName(AValue: string);
    procedure SetDescription(AValue: string);
    procedure SetCategory(AValue: string);
    procedure SetGUID(AValue: string);

    function GetName: string;
    function GetDescription: string;
    function GetCategory: string;
    function GetGUID: string;

    property Name: string read GetName write SetName;
    property Description: string read GetDescription write SetDescription;
    property Category: string read GetCategory write SetCategory;
    property GUID: string read GetGUID write SetGUID;
  end;

  TCarbonProfile = class(TInterfacedObject, ICarbonProfile)
  private
    FName         : string;
    FDescription  : string;
    FCategory     : string;
    FGUID         : string;
    function GetName: string;
    function GetDescription: string;
    function GetCategory: string;
    function GetGUID: string;

    procedure SetName(AValue: string);
    procedure SetDescription(AValue: string);
    procedure SetCategory(AValue: string);
    procedure SetGUID(AValue: string);
  public
    class function Create(const Name: string; const Description: string; const Category: string; const GUID: string):ICarbonProfile; overload; static;
    property Name: string read GetName write FName;
    property Description: string read GetDescription write FDescription;
    property Category: string read GetCategory write FCategory;
    property GUID: string read GetGUID write FGUID;
  end;

implementation

class function TCarbonProfile.Create(const Name: string; const Description: string; const Category: string; const GUID: string):ICarbonProfile;
begin
  result := TCarbonProfile.Create();
end;

procedure TCarbonProfile.SetName(AValue: string);
begin
  FName := AValue;
end;

procedure TCarbonProfile.SetDescription(AValue: string);
begin
  FDescription := AValue;
end;

procedure TCarbonProfile.SetCategory(AValue: string);
begin
  FCategory := AValue;
end;

procedure TCarbonProfile.SetGUID(AValue: string);
begin
  FGUID := AValue;
end;

function TCarbonProfile.GetName: string;
begin
  result := FName;
end;

function TCarbonProfile.GetDescription: string;
begin
  result := FDescription;
end;

function TCarbonProfile.GetCategory: string;
begin
  result := FCategory;
end;

function TCarbonProfile.GetGUID: string;
begin
  result := FGUID;
end;

end.

