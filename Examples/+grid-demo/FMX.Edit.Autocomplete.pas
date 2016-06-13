unit FMX.Edit.Autocomplete;

interface

uses
  FMX.Edit.Style, FMX.Controls.Presentation, FMX.Controls.Model, FMX.Presentation.Messages,
  FMX.Controls, FMX.ListBox, System.Classes, System.Types, FMX.Presentation.Style, FH.CARBONAPI.PROFILE;

type

  TStyledAutocompleteEdit = class(TStyledEdit)
  private
    FSuggestions: TArray<ICarbonProfile>;
    FPopup: TPopup;
    FListBox: TListBox;
    FDropDownCount: Integer;
  protected
    procedure MMDataChanged(var AMessage: TDispatchMessageWithValue<TDataRecord>); message MM_DATA_CHANGED;
    procedure PMSetSize(var AMessage: TDispatchMessageWithValue<TSizeF>); message PM_SET_SIZE;
    procedure DoChangeTracking; override;
    procedure RebuildSuggestionList;
    procedure RecalculatePopupHeight;
    procedure KeyDown(var Key: Word; var KeyChar: Char; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TStyledAutocompleteEditProxy = class(TStyledPresentationProxy<TStyledAutocompleteEdit>);

implementation

uses
  FMX.Presentation.Factory, FMX.Types, System.SysUtils, System.Math, System.UITypes;

{ TStyledAutocompleteEdit }

constructor TStyledAutocompleteEdit.Create(AOwner: TComponent);
begin
  inherited;
  FPopup := TPopup.Create(nil);
  FPopup.Parent := Self;
  FPopup.PlacementTarget := Self;
  FPopup.Placement := TPlacement.Bottom;
  FPopup.Width := Width;
  FListBox := TListBox.Create(nil);
  FListBox.Parent := FPopup;
  FListBox.Align := TAlignLayout.Client;
  FDropDownCount := 5;
end;

destructor TStyledAutocompleteEdit.Destroy;
var
  i       : integer;
  Profile : ICarbonProfile;
begin
  FPopup := nil;
  FListBox := nil;

  for Profile in FSuggestions do
  begin
    Profile._Release;
  end;
  inherited;
end;

procedure TStyledAutocompleteEdit.DoChangeTracking;

  function HasSuggestion: Boolean;
  var
    I: Integer;
  begin
    I := 0;
    Result := False;
    while not Result and (I < Length(FSuggestions)) do
    begin
      Result := FSuggestions[I].Name.ToLower.Contains(Model.Text.ToLower) or Model.Text.IsEmpty;
      if not Result then
        Inc(I)
      else
        Exit(Result);
    end;
  end;

  function IndexOfSuggestion: Integer;
  var
    Found: Boolean;
    I: Integer;
  begin
    Found := False;
    I := 0;
    Result := -1;
    while not Found and (I < FListBox.Count) do
    begin
      Found := FListBox.Items[I].ToLower.Contains(Model.Text.ToLower);
      if not Found then
        Inc(I)
      else
        Exit(I);
    end;
  end;

begin
  inherited;
  if HasSuggestion then
  begin
    RebuildSuggestionList;
    RecalculatePopupHeight;
    Index := IndexOfSuggestion;
    if Model.Text.IsEmpty then
      FListBox.ItemIndex := 0
    else
      FListBox.ItemIndex := Index;
    FPopup.IsOpen := True;
  end
  else
    FPopup.IsOpen := False;
end;

procedure TStyledAutocompleteEdit.KeyDown(var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  inherited;
  case Key of
    vkReturn:
      if FListBox.Selected <> nil then
      begin
        Model.Text := FListBox.Selected.Text;
        Edit.TagString := FListBox.Selected.TagString;
        Edit.GoToTextEnd;
        FPopup.IsOpen := False;
      end;
    vkEscape:
      FPopup.IsOpen := False;
    vkDown:
      begin
        if FListBox.Selected <> nil then
          FListBox.ItemIndex := Min(FListBox.Count - 1, FListBox.ItemIndex + 1);
        if not FPopup.IsOpen then
          DoChangeTracking;
      end;
    vkUp:
      if FListBox.Selected <> nil then
        FListBox.ItemIndex := Max(0, FListBox.ItemIndex - 1);
  end;
end;

procedure TStyledAutocompleteEdit.MMDataChanged(var AMessage: TDispatchMessageWithValue<TDataRecord>);
var
  Data: TDataRecord;
begin
  Data := AMessage.Value;
  if Data.Value.IsType < TArray<ICarbonProfile>> and (Data.Key = 'suggestion_list') then
    FSuggestions := AMessage.Value.Value.AsType<TArray<ICarbonProfile>>;
end;

procedure TStyledAutocompleteEdit.PMSetSize(var AMessage: TDispatchMessageWithValue<TSizeF>);
begin
  inherited;
  FPopup.Width := Width;
end;

procedure TStyledAutocompleteEdit.RebuildSuggestionList;
var
  LProfile  : ICarbonProfile;
  LItem     : TListBoxItem;
begin
  FListBox.Clear;
  FListBox.BeginUpdate;
  try
    for LProfile in FSuggestions do
    begin
      if LProfile.Name.ToLower.Contains(Model.Text.ToLower) or Model.Text.IsEmpty  then
      begin
        LItem  := TListBoxItem.Create(FListBox);
        try
          LItem.Enabled := true;
          LItem.Text := LProfile.Name;
          LItem.TagString := LProfile.GUID;
          LItem.Data := TObject(Pointer(LProfile));
        finally
          FListBox.AddObject(LItem);
        end;
      end;
    end;
  finally
    FListBox.EndUpdate;
  end;
end;

procedure TStyledAutocompleteEdit.RecalculatePopupHeight;
begin
  FPopup.Height := FListBox.ListItems[0].Height * Min(FDropDownCount, FListBox.Items.Count) + FListBox.BorderHeight;
  FPopup.PopupFormSize := TSizeF.Create(FPopup.Width, FPopup.Height);
end;

initialization
  TPresentationProxyFactory.Current.Register('AutocompleteEdit-style', TStyledAutocompleteEditProxy);
finalization
  TPresentationProxyFactory.Current.Unregister('AutocompleteEdit-style', TStyledAutocompleteEditProxy);
end.
