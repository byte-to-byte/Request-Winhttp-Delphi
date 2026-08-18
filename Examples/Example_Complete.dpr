program Example_Complete;

{$APPTYPE CONSOLE}

uses
  {$IFDEF VER150}
  SysUtils,
  {$ELSE}
  System.SysUtils,
  {$ENDIF}
  Request.WinHttp;

procedure TestGet;
var
  Request: TWinHttpRequest;
  Response: string;
begin
  Writeln('=== TESTE GET ===');
  Request := TWinHttpRequest.Create;
  try
    Response := Request.Get('https://httpbin.org/get');
    Writeln('Status: ', Request.Status);
    Writeln('Response: ', Copy(Response, 1, 200));
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestPostJson;
var
  Request: TWinHttpRequest;
  JsonData, Response: string;
begin
  Writeln('=== TESTE POST JSON ===');
  Request := TWinHttpRequest.Create;
  try
    JsonData := '{"nome": "Joao", "idade": 30}';
    Response := Request.PostJson('https://httpbin.org/post', JsonData);
    Writeln('Status: ', Request.Status);
    Writeln('Response: ', Copy(Response, 1, 200));
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestAuth;
var
  Request: TWinHttpRequest;
  Response: string;
begin
  Writeln('=== TESTE AUTENTICACAO ===');
  Request := TWinHttpRequest.Create;
  try
    { Bearer Token }
    Request.SetBearerToken('meu-token-secreto-123');
    Response := Request.Get('https://httpbin.org/headers');
    Writeln('Bearer - Status: ', Request.Status);
    
    { Basic Auth }
    Request.SetBasicAuthentication('usuario', 'senha');
    Response := Request.Get('https://httpbin.org/headers');
    Writeln('Basic - Status: ', Request.Status);
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestHeaders;
var
  Request: TWinHttpRequest;
  ContentType: string;
begin
  Writeln('=== TESTE HEADERS ===');
  Request := TWinHttpRequest.Create;
  try
    Request.SetRequestHeader('Accept', 'application/json');
    Request.SetRequestHeader('X-Custom-Header', 'MeuValor');
    Request.Get('https://httpbin.org/headers');
    
    ContentType := Request.GetResponseHeader('Content-Type');
    Writeln('Content-Type: ', ContentType);
    Writeln('All Headers: ', Copy(Request.ResponseHeaders, 1, 300));
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestTimeout;
var
  Request: TWinHttpRequest;
begin
  Writeln('=== TESTE TIMEOUT ===');
  Request := TWinHttpRequest.Create;
  try
    Request.SetTimeouts(5000, 5000, 5000, 10000);
    Writeln('Timeouts configurados');
    Writeln('Resolve: 5000ms, Connect: 5000ms, Send: 5000ms, Receive: 10000ms');
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestErrorHandling;
var
  Request: TWinHttpRequest;
begin
  Writeln('=== TESTE TRATAMENTO DE ERRO ===');
  Request := TWinHttpRequest.Create;
  try
    Request.RaiseForStatus := True;
    
    try
      { URL que retorna 404 }
      Request.Get('https://httpbin.org/status/404');
    except
      on E: EWinHttpResponseException do
        Writeln('Erro HTTP capturado: ', E.HttpStatus);
      on E: EWinHttpException do
        Writeln('Erro WinHTTP: ', E.Message);
    end;
    
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestBinary;
var
  Request: TWinHttpRequest;
  ImageBytes: TBytes;
begin
  Writeln('=== TESTE DADOS BINARIOS ===');
  Request := TWinHttpRequest.Create;
  try
    ImageBytes := Request.GetBytes('https://httpbin.org/bytes/100');
    Writeln('Bytes recebidos: ', Length(ImageBytes));
    if Length(ImageBytes) > 0 then
      Writeln('Primeiro byte: ', ImageBytes[0]);
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestSuccessProperty;
var
  Request: TWinHttpRequest;
begin
  Writeln('=== TESTE SUCCESS PROPERTY ===');
  Request := TWinHttpRequest.Create;
  try
    Request.RaiseForStatus := False;
    
    { 200 OK }
    Request.Get('https://httpbin.org/status/200');
    Writeln('Status 200 - Success: ', Request.Success);
    
    { 404 Not Found }
    Request.Get('https://httpbin.org/status/404');
    Writeln('Status 404 - Success: ', Request.Success);
    
    { 500 Internal Server Error }
    Request.Get('https://httpbin.org/status/500');
    Writeln('Status 500 - Success: ', Request.Success);
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestCustomMethod;
var
  Request: TWinHttpRequest;
begin
  Writeln('=== TESTE METODO CUSTOMIZADO ===');
  Request := TWinHttpRequest.Create;
  try
    { WebDAV PROPFIND }
    Request.Open('PROPFIND', 'https://httpbin.org/anything');
    Request.SetRequestHeader('Depth', '0');
    Request.Send;
    Writeln('PROPFIND Status: ', Request.Status);
  finally
    Request.Free;
  end;
  Writeln;
end;

procedure TestLogging;
type
  TLogger = class
    procedure OnLog(Sender: TObject; const Method, URL: string; 
                    Status: Integer; Duration: Double);
  end;

var
  Request: TWinHttpRequest;
  Logger: TLogger;

{ TLogger }
procedure TLogger.OnLog(Sender: TObject; const Method, URL: string; 
                        Status: Integer; Duration: Double);
begin
  Writeln(Format('[LOG] %s %s -> %d (%.3fs)', [Method, URL, Status, Duration]));
end;

begin
  Writeln('=== TESTE LOGGING ===');
  Logger := TLogger.Create;
  Request := TWinHttpRequest.Create;
  try
    Request.OnLog := Logger.OnLog;
    Request.Get('https://httpbin.org/get');
  finally
    Request.Free;
    Logger.Free;
  end;
  Writeln;
end;

begin
  try
    Writeln('Delphi WinHTTP Library - Exemplos Completos');
    Writeln('============================================');
    Writeln;
    
    TestGet;
    TestPostJson;
    TestAuth;
    TestHeaders;
    TestTimeout;
    TestErrorHandling;
    TestBinary;
    TestSuccessProperty;
    TestCustomMethod;
    TestLogging;
    
    Writeln('Todos os testes completados!');
    
  except
    on E: Exception do
      Writeln('Erro: ', E.ClassName, ': ', E.Message);
  end;
  
  Write('Pressione Enter para sair...');
  Readln;
end.
