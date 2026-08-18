# Delphi WinHTTP Library

Complete HTTP library for Delphi using exclusively `WinHttp.WinHttpRequest.5.1`.

## Table of Contents

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Complete API](#complete-api)
- [HTTPS/TLS](#httpstls)
- [Security](#security)
- [Known Limitations](#known-limitations)

---

## Introduction

Lightweight and reliable HTTP library for Delphi on Windows, using exclusively the **WinHttp.WinHttpRequest.5.1** backend.

**Features:**
- ✅ Single portable unit (`Request.WinHttp.pas`)
- ✅ Compatible with Delphi 7 through Delphi 13 Florence
- ✅ All HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, etc.)
- ✅ HTTPS/TLS with certificate validation
- ✅ Basic and Bearer Token authentication
- ✅ File upload/download
- ✅ JSON and Form URL Encoded support
- ✅ Configurable proxy
- ✅ Customizable timeout
- ✅ Specific exceptions by error type

---

## Requirements

### System
- Windows 2000 or later
- WinHTTP 5.1 (installed by default on Windows XP SP2+)

### Verification
```delphi
try
  CreateOleObject('WinHttp.WinHttpRequest.5.1');
  // WinHTTP available
except
  // WinHTTP NOT available
end;
```

---

## Compatibility

| Delphi | Status |
|--------|--------|
| 7 | ✅ |
| 2007-2010 | ✅ |
| XE-XE7 | ✅ |
| 10.x | ✅ |
| 11 Alexandria | ✅ |
| 12 Athens | ✅ |
| 13 Florence | ✅ |

---

## Installation

1. Copy `Request.WinHttp.pas` to your project
2. Add to uses clause: `uses Request.WinHttp;`
3. Compile and use!

---

## Usage Examples

### Simple GET
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Writeln(Request.Get('https://api.example.com/data'));
  finally
    Request.Free;
  end;
end;
```

### POST JSON
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.PostJson('https://api.example.com/users', '{"name":"John"}');
  finally
    Request.Free;
  end;
end;
```

### With Headers and Auth
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.SetBearerToken('my-token');
    Request.SetRequestHeader('Accept', 'application/json');
    Request.Get('https://api.example.com/protected');
  finally
    Request.Free;
  end;
end;
```

### File Download
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.DownloadFile('https://example.com/file.zip', 'C:\file.zip');
  finally
    Request.Free;
  end;
end;
```

### Error Handling
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.RaiseForStatus := True;
    Request.Get('https://api.example.com/error');
  except
    on E: EWinHttpTimeoutException do
      Writeln('Timeout');
    on E: EWinHttpResponseException do
      Writeln('HTTP ', E.HttpStatus);
    on E: EWinHttpException do
      Writeln('Error: ', E.Message);
  end;
  Request.Free;
end;
```

---

## Complete API

### Main Methods
```delphi
function Get(const URL: string): string;
function GetBytes(const URL: string): TBytes;
function Post(const URL: string; const Body: string; const ContentType: string = ''): string;
function Put(const URL: string; const Body: string; const ContentType: string = ''): string;
function Patch(const URL: string; const Body: string; const ContentType: string = ''): string;
function Delete(const URL: string): string;
function PostJson(const URL: string; const Json: string): string;
function PostForm(const URL: string; const FormData: string): string;
procedure DownloadFile(const URL: string; const FileName: string);
procedure UploadFile(const URL: string; const FileName: string; const FieldName: string = 'file');
```

### Configuration
```delphi
procedure SetRequestHeader(const Name: string; const Value: string);
procedure SetBearerToken(const Token: string);
procedure SetBasicAuthentication(const UserName: string; const Password: string);
procedure SetTimeouts(ResolveTimeout, ConnectTimeout, SendTimeout, ReceiveTimeout: Integer);
procedure SetProxy(ProxyType: TProxyType; const ProxyServer: string = ''; const ProxyBypass: string = '');
```

### Properties
```delphi
property Status: Integer;
property StatusText: string;
property ResponseText: string;
property ResponseBody: TBytes;
property ResponseHeaders: string;
property Success: Boolean;
property RaiseForStatus: Boolean;
property FollowRedirects: Boolean;
property IgnoreCertificateErrors: Boolean;
property UserAgent: string;
```

### Exceptions
```delphi
EWinHttpException
EWinHttpTimeoutException
EWinHttpConnectionException
EWinHttpResponseException
EWinHttpCertificateException
```

---

## HTTPS/TLS

### Certificate Validation
By default, certificates are automatically validated:
- Certificate not expired
- Trusted authority
- Correct hostname
- Valid chain

### Ignore Errors (UNSAFE!)
```delphi
Request.IgnoreCertificateErrors := True; // ⚠️ Development only!
```

---

## Security

### Best Practices
1. Never log credentials
2. Keep certificate validation enabled in production
3. Always use HTTPS
4. Handle exceptions appropriately

### Protected Headers
The library never logs: Authorization, Cookie, passwords, or tokens.

---

## Known Limitations

### Cookies
- ✅ Automatic management per domain
- ❌ No direct API access
- Workaround: `SetRequestHeader('Cookie', 'value')`

### Async
- ⚠️ Async mode exists but callbacks not implemented
- ✅ Use synchronous mode (default)

### ClearRequestHeaders
- ❌ Not supported by WinHTTP
- Workaround: Create new instance

### Thread Safety
- ⚠️ One instance per thread!
- COM object is not thread-safe

---

## License

MIT License - Free to use.

---

## Links

- [Microsoft WinHTTP Docs](https://learn.microsoft.com/windows/win32/winhttp/winhttp-start-page)