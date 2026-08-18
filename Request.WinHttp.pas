unit Request.WinHttp;

{$IFDEF VER150}{$DEFINE DELPHI7_OR_OLDER}{$ENDIF}
{$IFDEF VER160}{$DEFINE DELPHI8_OR_OLDER}{$ENDIF}
{$IFDEF VER170}{$DEFINE DELPHI2005_OR_OLDER}{$ENDIF}
{$IFDEF VER180}{$DEFINE DELPHI2006_OR_OLDER}{$ENDIF}
{$IFDEF VER185}{$DEFINE DELPHI2007_OR_OLDER}{$ENDIF}
{$IFDEF VER190}{$DEFINE DELPHI2009_OR_OLDER}{$ENDIF}
{$IFDEF VER200}{$DEFINE DELPHI2010_OR_OLDER}{$ENDIF}

interface

uses
  {$IFNDEF DELPHI7_OR_OLDER}
  System.SysUtils, System.Classes, System.Variants, System.Types,
  Winapi.Windows, Winapi.ActiveX,
  {$ELSE}
  SysUtils, Classes, Variants, Windows, ActiveX,
  {$ENDIF}
  ComObj;

type
  EWinHttpException = class;
  EWinHttpTimeoutException = class;
  EWinHttpConnectionException = class;
  EWinHttpResponseException = class;
  EWinHttpCertificateException = class;
  TWinHttpRequest = class;

  EWinHttpException = class(Exception)
  private
    FErrorCode: Integer;
    FHttpStatus: Integer;
  public
    constructor Create(const AMsg: string; AErrorCode: Integer = 0; AHttpStatus: Integer = 0);
    property ErrorCode: Integer read FErrorCode;
    property HttpStatus: Integer read FHttpStatus;
  end;

  EWinHttpTimeoutException = class(EWinHttpException);
  EWinHttpConnectionException = class(EWinHttpException);
  EWinHttpResponseException = class(EWinHttpException);
  EWinHttpCertificateException = class(EWinHttpException);

  TProxyType = (ptDefault, ptDirect, ptExplicit);
  TLogEvent = procedure(Sender: TObject; const Method, URL: string; Status: Integer; Duration: Double) of object;

  TWinHttpRequest = class
  private
    FWinHttp: OleVariant;
    FMethod, FURL: string;
    FAsync: Boolean;
    FUserAgent: string;
    FRaiseForStatus, FFollowRedirects, FIgnoreCertificateErrors, FHeadersSent: Boolean;
    FMaxRedirects, FResolveTimeout, FConnectTimeout, FSendTimeout, FReceiveTimeout: Integer;
    FProxyType: TProxyType;
    FProxyServer, FProxyBypass: string;
    FOnLog: TLogEvent;
    FStartTime, FEndTime: TDateTime;
    function GetStatus: Integer;
    function GetStatusText: string;
    function GetResponseText: string;
    function GetResponseBody: TBytes;
    function GetResponseHeaders: string;
    function GetSuccess: Boolean;
    function InitializeCOM: Boolean;
    procedure ApplyTimeouts;
    procedure ApplyProxy;
    procedure SetDefaultHeaders;
    function EncodeBase64(const Input: string): string;
    procedure InternalSend(const Body: OleVariant);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open(const Method: string; const URL: string; Async: Boolean = False);
    procedure Send; overload;
    procedure Send(const Body: string); overload;
    procedure Send(const Body: TBytes); overload;
    function Get(const URL: string): string;
    function GetBytes(const URL: string): TBytes;
    function Post(const URL: string; const Body: string; const ContentType: string = ''): string;
    function PostBytes(const URL: string; const Body: TBytes; const ContentType: string = ''): string;
    function Put(const URL: string; const Body: string; const ContentType: string = ''): string;
    function Patch(const URL: string; const Body: string; const ContentType: string = ''): string;
    function Delete(const URL: string): string;
    function Head(const URL: string): string;
    function Options(const URL: string): string;
    function PostJson(const URL: string; const Json: string): string;
    function PutJson(const URL: string; const Json: string): string;
    function PatchJson(const URL: string; const Json: string): string;
    function PostForm(const URL: string; const FormData: string): string;
    procedure DownloadFile(const URL: string; const FileName: string);
    procedure UploadFile(const URL: string; const FileName: string; const FieldName: string = 'file');
    procedure SetRequestHeader(const Name: string; const Value: string);
    function GetResponseHeader(const Name: string): string;
    function GetAllResponseHeaders: string;
    procedure ClearRequestHeaders;
    procedure SetBearerToken(const Token: string);
    procedure SetBasicAuthentication(const UserName: string; const Password: string);
    procedure SetCredentials(const UserName: string; const Password: string);
    procedure SetTimeouts(ResolveTimeout, ConnectTimeout, SendTimeout, ReceiveTimeout: Integer);
    procedure SetProxy(ProxyType: TProxyType; const ProxyServer: string = ''; const ProxyBypass: string = '');
    property Status: Integer read GetStatus;
    property StatusText: string read GetStatusText;
    property ResponseText: string read GetResponseText;
    property ResponseBody: TBytes read GetResponseBody;
    property ResponseHeaders: string read GetResponseHeaders;
    property Success: Boolean read GetSuccess;
    property RaiseForStatus: Boolean read FRaiseForStatus write FRaiseForStatus;
    property FollowRedirects: Boolean read FFollowRedirects write FFollowRedirects;
    property MaxRedirects: Integer read FMaxRedirects write FMaxRedirects;
    property IgnoreCertificateErrors: Boolean read FIgnoreCertificateErrors write FIgnoreCertificateErrors;
    property UserAgent: string read FUserAgent write FUserAgent;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property Method: string read FMethod;
    property URL: string read FURL;
    property Async: Boolean read FAsync;
    property RequestDuration: Double read FEndTime - FStartTime;
  end;

function UrlEncode(const S: string): string;
function Base64Encode(const Input: string): string;

implementation

const
  ERROR_WINHTTP_TIMEOUT = 12002;
  ERROR_WINHTTP_NAME_NOT_RESOLVED = 12007;
  ERROR_WINHTTP_CANNOT_CONNECT = 12003;
  ERROR_WINHTTP_SECURE_FAILURE = 12038;
  DEFAULT_TIMEOUT = 30000;
  DEFAULT_USER_AGENT = 'Delphi-WinHttp/1.0';

constructor TWinHttpRequest.Create;
begin
  inherited Create;
  FResolveTimeout := DEFAULT_TIMEOUT;
  FConnectTimeout := DEFAULT_TIMEOUT;
  FSendTimeout := DEFAULT_TIMEOUT;
  FReceiveTimeout := DEFAULT_TIMEOUT;
  FFollowRedirects := True;
  FMaxRedirects := 5;
  FIgnoreCertificateErrors := False;
  FRaiseForStatus := False;
  FProxyType := ptDefault;
  FUserAgent := DEFAULT_USER_AGENT;
  InitializeCOM;
  try
    FWinHttp := CreateOleObject('WinHttp.WinHttpRequest.5.1');
  except
    on E: Exception do
      raise EWinHttpConnectionException.Create('Failed to create WinHttp.WinHttpRequest.5.1. (' + E.Message + ')', 0, 0);
  end;
  ApplyProxy;
  ApplyTimeouts;
end;

destructor TWinHttpRequest.Destroy;
begin
  if not VarIsEmpty(FWinHttp) then FWinHttp := Unassigned;
  inherited Destroy;
end;

function TWinHttpRequest.InitializeCOM: Boolean;
var hr: HRESULT;
begin
  hr := CoInitialize(nil);
  Result := SUCCEEDED(hr) or (hr = RPC_E_CHANGED_MODE);
end;

procedure TWinHttpRequest.ApplyTimeouts;
begin
  if not VarIsEmpty(FWinHttp) then
    try
      FWinHttp.Option(1, 0, FResolveTimeout);
      FWinHttp.Option(2, 0, FConnectTimeout);
      FWinHttp.Option(3, 0, FSendTimeout);
      FWinHttp.Option(4, 0, FReceiveTimeout);
    except end;
end;

procedure TWinHttpRequest.ApplyProxy;
begin
  if not VarIsEmpty(FWinHttp) then
    try
      case FProxyType of
        ptDefault: FWinHttp.SetProxy(0, '', '');
        ptDirect: FWinHttp.SetProxy(1, '', '');
        ptExplicit: FWinHttp.SetProxy(2, FProxyServer, FProxyBypass);
      end;
    except
      on E: Exception do
        raise EWinHttpConnectionException.Create('Proxy config failed. (' + E.Message + ')', 0, 0);
    end;
end;

procedure TWinHttpRequest.SetDefaultHeaders;
begin
  if (FUserAgent <> '') and (not FHeadersSent) then
  begin
    SetRequestHeader('User-Agent', FUserAgent);
    FHeadersSent := True;
  end;
end;

procedure TWinHttpRequest.Open(const Method: string; const URL: string; Async: Boolean = False);
begin
  FMethod := Method;
  FURL := URL;
  FAsync := Async;
  FHeadersSent := False;
  if VarIsEmpty(FWinHttp) then raise EWinHttpConnectionException.Create('WinHTTP not initialized', 0, 0);
  try
    FWinHttp.Open(Method, URL, Async);
    if not FFollowRedirects then try FWinHttp.Option(47, 0, False) except end;
    if FIgnoreCertificateErrors then try FWinHttp.Option(48, 0, True) except end;
    SetDefaultHeaders;
  except
    on E: Exception do raise EWinHttpConnectionException.Create('Open failed. (' + E.Message + ')', 0, 0);
  end;
end;

procedure TWinHttpRequest.InternalSend(const Body: OleVariant);
var LogMethod, LogURL: string;
begin
  LogMethod := FMethod; LogURL := FURL;
  FStartTime := Now;
  try
    if VarIsEmpty(Body) then FWinHttp.Send else FWinHttp.Send(Body);
    FEndTime := Now;
    if Assigned(FOnLog) then FOnLog(Self, LogMethod, LogURL, GetStatus, RequestDuration);
    if FRaiseForStatus and not GetSuccess then
      raise EWinHttpResponseException.Create(Format('HTTP Error %d: %s', [GetStatus, GetStatusText]), 0, GetStatus);
  except
    on E: EOleException do
    begin
      FEndTime := Now;
      case E.ErrorCode of
        ERROR_WINHTTP_TIMEOUT: raise EWinHttpTimeoutException.Create('Request timeout.', E.ErrorCode, 0);
        ERROR_WINHTTP_NAME_NOT_RESOLVED: raise EWinHttpConnectionException.Create('DNS resolution failed.', E.ErrorCode, 0);
        ERROR_WINHTTP_CANNOT_CONNECT: raise EWinHttpConnectionException.Create('Connection failed.', E.ErrorCode, 0);
        ERROR_WINHTTP_SECURE_FAILURE: raise EWinHttpCertificateException.Create('SSL certificate validation failed.', E.ErrorCode, 0);
      else raise EWinHttpException.Create(Format('WinHTTP error %d: %s', [E.ErrorCode, E.Message]), E.ErrorCode, 0);
      end;
    end;
    on E: Exception do
    begin
      FEndTime := Now;
      if not (E is EWinHttpException) then raise EWinHttpException.Create('Request failed: ' + E.Message, 0, 0) else raise;
    end;
  end;
end;

procedure TWinHttpRequest.Send; begin InternalSend(Unassigned); end;
procedure TWinHttpRequest.Send(const Body: string); begin InternalSend(Body); end;
procedure TWinHttpRequest.Send(const Body: TBytes);
var ByteArray: OleVariant; i: Integer;
begin
  ByteArray := VarArrayCreate([0, High(Body)], varByte);
  for i := 0 to High(Body) do ByteArray[i] := Body[i];
  InternalSend(ByteArray);
end;

function TWinHttpRequest.Get(const URL: string): string; begin Open('GET', URL); Send; Result := ResponseText; end;
function TWinHttpRequest.GetBytes(const URL: string): TBytes; begin Open('GET', URL); Send; Result := ResponseBody; end;
function TWinHttpRequest.Post(const URL: string; const Body: string; const ContentType: string = ''): string;
begin Open('POST', URL); if ContentType <> '' then SetRequestHeader('Content-Type', ContentType); Send(Body); Result := ResponseText; end;
function TWinHttpRequest.PostBytes(const URL: string; const Body: TBytes; const ContentType: string = ''): string;
begin Open('POST', URL); if ContentType <> '' then SetRequestHeader('Content-Type', ContentType); Send(Body); Result := ResponseText; end;
function TWinHttpRequest.Put(const URL: string; const Body: string; const ContentType: string = ''): string;
begin Open('PUT', URL); if ContentType <> '' then SetRequestHeader('Content-Type', ContentType); Send(Body); Result := ResponseText; end;
function TWinHttpRequest.Patch(const URL: string; const Body: string; const ContentType: string = ''): string;
begin Open('PATCH', URL); if ContentType <> '' then SetRequestHeader('Content-Type', ContentType); Send(Body); Result := ResponseText; end;
function TWinHttpRequest.Delete(const URL: string): string; begin Open('DELETE', URL); Send; Result := ResponseText; end;
function TWinHttpRequest.Head(const URL: string): string; begin Open('HEAD', URL); Send; Result := ''; end;
function TWinHttpRequest.Options(const URL: string): string; begin Open('OPTIONS', URL); Send; Result := GetResponseHeader('Allow'); end;
function TWinHttpRequest.PostJson(const URL: string; const Json: string): string; begin Result := Post(URL, Json, 'application/json'); end;
function TWinHttpRequest.PutJson(const URL: string; const Json: string): string; begin Result := Put(URL, Json, 'application/json'); end;
function TWinHttpRequest.PatchJson(const URL: string; const Json: string): string; begin Result := Patch(URL, Json, 'application/json'); end;
function TWinHttpRequest.PostForm(const URL: string; const FormData: string): string; begin Result := Post(URL, FormData, 'application/x-www-form-urlencoded'); end;

procedure TWinHttpRequest.DownloadFile(const URL: string; const FileName: string);
var Stream: TFileStream; Body: TBytes;
begin
  Open('GET', URL); Send;
  Body := ResponseBody;
  if Length(Body) > 0 then
  begin
    Stream := TFileStream.Create(FileName, fmCreate);
    try Stream.WriteBuffer(Body[0], Length(Body)); finally Stream.Free; end;
  end;
end;

procedure TWinHttpRequest.UploadFile(const URL: string; const FileName: string; const FieldName: string = 'file');
var Stream: TFileStream; FileData: TBytes; Boundary, CRLF, Header: string; Body: TBytes; i: Integer;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try SetLength(FileData, Stream.Size); Stream.ReadBuffer(FileData[0], Stream.Size); finally Stream.Free; end;
  Boundary := '----WebKitFormBoundary' + IntToHex(Random(MaxInt), 8);
  CRLF := #$0D#$0A;
  Header := '--' + Boundary + CRLF + 'Content-Disposition: form-data; name="' + FieldName + '"; filename="' + ExtractFileName(FileName) + '"' + CRLF + 'Content-Type: application/octet-stream' + CRLF + CRLF;
  SetLength(Body, Length(Header) + Length(FileData) + Length(Boundary) + 4);
  for i := 0 to Length(Header) - 1 do Body[i] := Ord(Header[i + 1]);
  for i := 0 to High(FileData) do Body[Length(Header) + i] := FileData[i];
  Header := CRLF + '--' + Boundary + '--' + CRLF;
  for i := 0 to Length(Header) - 1 do Body[Length(Header) + Length(FileData) + i] := Ord(Header[i + 1]);
  Open('POST', URL);
  SetRequestHeader('Content-Type', 'multipart/form-data; boundary=' + Boundary);
  Send(Body);
end;

procedure TWinHttpRequest.SetRequestHeader(const Name: string; const Value: string);
begin
  if not VarIsEmpty(FWinHttp) then
    try FWinHttp.SetRequestHeader(Name, Value)
    except on E: Exception do raise EWinHttpException.Create('Failed to set header "' + Name + '". (' + E.Message + ')', 0, 0); end;
end;

function TWinHttpRequest.GetResponseHeader(const Name: string): string;
begin
  if not VarIsEmpty(FWinHttp) then try Result := FWinHttp.GetResponseHeader(Name) except Result := ''; end else Result := '';
end;

function TWinHttpRequest.GetAllResponseHeaders: string;
begin
  if not VarIsEmpty(FWinHttp) then try Result := FWinHttp.GetAllResponseHeaders except Result := ''; end else Result := '';
end;

procedure TWinHttpRequest.ClearRequestHeaders; begin { Not supported by WinHTTP API } end;
procedure TWinHttpRequest.SetBearerToken(const Token: string); begin SetRequestHeader('Authorization', 'Bearer ' + Token); end;
procedure TWinHttpRequest.SetBasicAuthentication(const UserName: string; const Password: string);
begin SetRequestHeader('Authorization', 'Basic ' + EncodeBase64(UserName + ':' + Password)); end;

procedure TWinHttpRequest.SetCredentials(const UserName: string; const Password: string);
begin
  if not VarIsEmpty(FWinHttp) then
    try FWinHttp.SetCredentials(UserName, Password, 0)
    except on E: Exception do raise EWinHttpException.Create('SetCredentials failed. (' + E.Message + ')', 0, 0); end;
end;

procedure TWinHttpRequest.SetTimeouts(ResolveTimeout, ConnectTimeout, SendTimeout, ReceiveTimeout: Integer);
begin
  FResolveTimeout := ResolveTimeout; FConnectTimeout := ConnectTimeout;
  FSendTimeout := SendTimeout; FReceiveTimeout := ReceiveTimeout;
  ApplyTimeouts;
end;

procedure TWinHttpRequest.SetProxy(ProxyType: TProxyType; const ProxyServer: string; const ProxyBypass: string);
begin FProxyType := ProxyType; FProxyServer := ProxyServer; FProxyBypass := ProxyBypass; ApplyProxy; end;

function TWinHttpRequest.GetStatus: Integer;
begin if not VarIsEmpty(FWinHttp) then try Result := FWinHttp.Status except Result := 0; end else Result := 0; end;

function TWinHttpRequest.GetStatusText: string;
begin if not VarIsEmpty(FWinHttp) then try Result := FWinHttp.StatusText except Result := ''; end else Result := ''; end;

function TWinHttpRequest.GetResponseText: string;
begin if not VarIsEmpty(FWinHttp) then try Result := FWinHttp.ResponseText except Result := ''; end else Result := ''; end;

function TWinHttpRequest.GetResponseBody: TBytes;
var VariantData: OleVariant; i: Integer;
begin
  SetLength(Result, 0);
  if not VarIsEmpty(FWinHttp) then
    try
      VariantData := FWinHttp.ResponseBody;
      if not VarIsEmpty(VariantData) then
      begin
        SetLength(Result, VarArrayHighBound(VariantData, 1) + 1);
        for i := 0 to High(Result) do Result[i] := Byte(VariantData[i]);
      end;
    except end;
end;

function TWinHttpRequest.GetResponseHeaders: string; begin Result := GetAllResponseHeaders; end;
function TWinHttpRequest.GetSuccess: Boolean; var StatusCode: Integer; begin StatusCode := GetStatus; Result := (StatusCode >= 200) and (StatusCode < 300); end;

function TWinHttpRequest.EncodeBase64(const Input: string): string;
const Base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var i, j: Integer; Buf: LongWord;
begin
  Result := ''; i := 1;
  while i <= Length(Input) do
  begin
    Buf := 0;
    for j := 0 to 2 do begin Buf := Buf shl 8; if i <= Length(Input) then begin Buf := Buf or Ord(Input[i]); Inc(i); end; end;
    Result := Result + Base64Chars[(Buf shr 18) and $3F];
    Result := Result + Base64Chars[(Buf shr 12) and $3F];
    if i - 1 <= Length(Input) then Result := Result + Base64Chars[(Buf shr 6) and $3F] else Result := Result + '=';
    if i <= Length(Input) then Result := Result + Base64Chars[Buf and $3F] else Result := Result + '=';
  end;
end;

function UrlEncode(const S: string): string;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if c in ['a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~'] then Result := Result + c
    else if c = ' ' then Result := Result + '+'
    else Result := Result + '%' + IntToHex(Ord(c), 2);
  end;
end;

function Base64Encode(const Input: string): string; begin Result := EncodeBase64(Input); end;
constructor EWinHttpException.Create(const AMsg: string; AErrorCode: Integer; AHttpStatus: Integer);
begin inherited Create(AMsg); FErrorCode := AErrorCode; FHttpStatus := AHttpStatus; end;

end.
