unit HttpServerCommand;

interface
uses
  classes, IdContext, IdCustomHTTPServer, generics.collections,
  System.SysUtils;

type
  TRESTCommandClass = class of TRESTCommand;
  THttpServerCommand= class;
  TRESTCommandREG= class;

  TRESTCommand=class
  private
    FParams: TStringList;
    FContext: TIdContext;
    FRequestInfo: TIdHTTPRequestInfo;
    FResponseInfo: TIdHTTPResponseInfo;
    FReg: TRESTCommandREG;
    procedure start(AReg: TRESTCommandREG; AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo; AParams: TStringList);
    procedure ParseParams(AURI, AMask:String);
  protected
    procedure execute(); virtual;
  public
    constructor create(AServer: THttpServerCommand);
    procedure ResponseJSON(Json: String);
    destructor Destroy; override;
    property Context: TIdContext read FContext;
    property RequestInfo: TIdHTTPRequestInfo read FRequestInfo;
    property ResponseInfo: TIdHTTPResponseInfo read FResponseInfo;
    property Params: TStringList read FParams;
  end;

  TRESTCommandREG= class
  public
    FTYPE: String;
    FPATH: String;
    FCommand: TRESTCommandClass;
    constructor Create(ATYPE:String; APATH: String; ACommand: TRESTCommandClass);
  end;

  THttpServerCommandRegister=class(TComponent)
  private
    FList: TObjectList<TRESTCommandREG>;
  public
    procedure Register(ATYPE:String; APATH: String; ACommand: TRESTCommandClass);
    constructor Create(AOwner: TComponent); override;
    function isUri(AURI: String; AMask: String; AParams: TStringList): boolean;
    function FindCommand(ACommand: String; AURI: String; Params: TStringList): TRESTCommandREG;
    destructor Destroy; override;
  end;

  THttpServerCommand= class (TComponent)
  private
    FCommands: THttpServerCommandRegister;
    procedure SetCommands(const Value: THttpServerCommandRegister);
    function TrataCommand(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo): boolean;
    procedure TrataErro(ACmd: TRESTCommandREG;AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;  E: Exception);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    property Commands: THttpServerCommandRegister read FCommands;
  end;


implementation

{ THttpServerCommand }
function THttpServerCommand.TrataCommand(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo): boolean;
var
  cmdReg: TRESTCommandREG;
  cmd: TRESTCommand;
  Params: TStringList;
begin
  Params:= TStringList.Create;
  try
    cmdReg:= FCommands.FindCommand(ARequestInfo.Command,ARequestInfo.URI, Params);
    if cmdReg=nil then  exit(false);

    try
      cmd:=cmdReg.FCommand.create(self);
      try
        cmd.start(cmdReg, AContext, ARequestInfo, AResponseInfo, Params);
        cmd.execute;
      finally
        cmd.Free;
      end;
    except
      on e:Exception do
      begin
         TrataErro(cmdReg, AContext, ARequestInfo, AResponseInfo, e);
      end;
    end;
    result:= true;
  finally
    params.Free;
  end;
end;


procedure THttpServerCommand.TrataErro(ACmd: TRESTCommandREG;
  AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo; E: Exception);
begin
  // TODO ...
  AResponseInfo.ContentText := format('<http><body>RestServer<br>Erro no commando conhecido:%s => %s: %s </body></http>',[ARequestInfo.Command, ARequestInfo.URI, e.Message]);
end;

procedure THttpServerCommand.CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  if not TrataCommand(AContext,ARequestInfo,AResponseInfo) then

  AResponseInfo.ContentText := format('<http><body>RestServer<br>Commando não conhecido:%s => %s </body></http>',[ARequestInfo.Command, ARequestInfo.URI]);
end;


constructor THttpServerCommand.Create(AOwner: TComponent);
begin
  inherited;
  FCommands:= THttpServerCommandRegister.Create(self);
end;

destructor THttpServerCommand.Destroy;
begin
  FCommands.Free;
  inherited;
end;

procedure THttpServerCommand.SetCommands(
  const Value: THttpServerCommandRegister);
begin

end;

{ THttpServerCommandRegister }

constructor THttpServerCommandRegister.Create(AOwner: TComponent);
begin
  inherited;
  FList:= TObjectList<TRESTCommandREG>.Create(True);
end;

destructor THttpServerCommandRegister.Destroy;
begin
  FList.Free;
  inherited;
end;

function THttpServerCommandRegister.FindCommand(ACommand, AURI: String; Params: TStringList): TRESTCommandREG;
var
  I: Integer;
begin
  for I := 0 to FList.Count-1 do
  begin
    if SameText(ACommand,FList[i].FTYPE) then
    begin
       if isURI(AURI,FList[i].FPATH, Params) then
       begin
          exit(FList[i]);
       end;
    end;
  end;
  result:= nil;
end;

function THttpServerCommandRegister.isUri(AURI, AMask: String; AParams: TStringList): boolean;
var
  sl1: TStringList;
  sl2: TStringList;
  I: Integer;
begin
  sl1:= TStringList.Create;
  sl2:= TStringList.Create;
  try
    sl1.StrictDelimiter:= true;
    sl1.Delimiter:= '/';
    sl1.DelimitedText := AMask;

    sl2.StrictDelimiter:= true;
    sl2.Delimiter:= '/';
    sl2.DelimitedText := AURI;

    for I := 0 to sl1.Count-1 do
    begin
      if sl1[i].StartsWith(':') then
      begin
        AParams.Values[sl1[i].Substring(1,255)]:= sl2[i];
      end else
      begin
         if not SameText(sl1[i],sl2[i]) then exit(false);
      end;
    end;
    result:= true;
  finally
    sl1.Free;
    sl2.Free;
  end;
end;
//begin
//  if SameText(AURI, AMask) then  exit(true);
//  result:= false;
//end;

procedure THttpServerCommandRegister.Register(ATYPE, APATH: String;
  ACommand: TRESTCommandClass);
begin
  FList.Add(TRESTCommandREG.Create(ATYPE, APATH, ACommand));
end;

{ TRESTCommandREG }

constructor TRESTCommandREG.Create(ATYPE, APATH: String;
  ACommand: TRESTCommandClass);
begin
  FTYPE:= AType;
  FPATH:= APATH;
  FCommand:= ACommand;
end;

{ TRESTCommand }

constructor TRESTCommand.create(AServer: THttpServerCommand);
begin
  FParams:= TStringList.Create;
end;

procedure TRESTCommand.start(AReg: TRESTCommandREG; AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo; AParams: TStringList);
begin
  FContext:= AContext;
  FRequestInfo:= ARequestInfo;
  FResponseInfo:= AResponseInfo;
  FReg:= AReg;
  FParams.Assign(AParams);
  ParseParams(ARequestInfo.URI, AReg.FPATH);

end;

destructor TRESTCommand.Destroy;
begin
  FParams.free;
  inherited;
end;

procedure TRESTCommand.execute;
begin

end;

procedure TRESTCommand.ParseParams(AURI, AMask: String);
var
  sl1: TStringList;
  sl2: TStringList;
  I: Integer;
begin
  sl1:= TStringList.Create;
  sl2:= TStringList.Create;
  try
    sl1.StrictDelimiter:= true;
    sl1.Delimiter:= '/';
    sl1.DelimitedText := AMask;

    sl2.StrictDelimiter:= true;
    sl2.Delimiter:= '/';
    sl2.DelimitedText := AURI;

    for I := 0 to sl1.Count-1 do
    begin
      if sl1[i].StartsWith(':') then
      begin
        FParams.Values[sl1[i].Substring(1,255)]:= sl2[i];
      end;
    end;
  finally
    sl1.Free;
    sl2.Free;
  end;
end;

procedure TRESTCommand.ResponseJSON(Json: String);
begin
  ResponseInfo.ContentText := Json;
  ResponseInfo.ContentType := 'Application/JSON';
end;

end.
