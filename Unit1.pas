unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, IdContext, HttpServerCommand;

type
  TForm1 = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FormCreate(Sender: TObject);
  private
    FCommand: THttpServerCommand;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
type
  TRestTeste=class(TRESTCommand)
  protected
    procedure execute; override;
  end;

  TRestTeste2=class(TRESTCommand)
  protected
    procedure execute; override;
  end;

  TRestTesteParam=class(TRESTCommand)
  protected
    procedure execute; override;
  end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FCommand:= THttpServerCommand.Create(self);
  FCommand.Commands.Register('GET','/teste1', TRestTeste);
  FCommand.Commands.Register('GET','/teste2', TRestTeste2);
  FCommand.Commands.Register('GET','/teste3/:param1', TRestTesteParam);
end;

procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
   FCommand.CommandGet(AContext,  ARequestInfo, AResponseInfo);
end;

{ TRestTeste }

procedure TRestTeste.execute;
begin
  inherited;
  ResponseJSON('{''teste'':''ok''}');
end;

{ TRestTeste2 }

procedure TRestTeste2.execute;
begin
  inherited;
  ResponseJSON('{''teste2'':''ok''}');
end;

{ TRestTesteParam }

procedure TRestTesteParam.execute;
begin
  inherited;
  ResponseJSON('{''params'':'+QuotedStr(params.commatext)+'}');
end;

end.
