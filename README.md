# Delphi WinHTTP Library

Biblioteca HTTP completa para Delphi usando exclusivamente `WinHttp.WinHttpRequest.5.1`.

## Índice

- [Introdução](#introdução)
- [Requisitos](#requisitos)
- [Compatibilidade](#compatibilidade)
- [Instalação](#instalação)
- [Exemplos de Uso](#exemplos-de-uso)
- [API Completa](#api-completa)
- [HTTPS/TLS](#httpstls)
- [Segurança](#segurança)
- [Limitações](#limitações-conhecidas)

---

## Introdução

Biblioteca HTTP leve e confiável para Delphi Windows, utilizando exclusivamente o backend **WinHttp.WinHttpRequest.5.1**.

**Características:**
- ✅ Unit única e portátil (`Request.WinHttp.pas`)
- ✅ Compatível Delphi 7 até Delphi 13 Florence
- ✅ Todos métodos HTTP (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS, etc.)
- ✅ HTTPS/TLS com validação de certificados
- ✅ Autenticação Basic e Bearer Token
- ✅ Upload/Download de arquivos
- ✅ JSON e Form URL Encoded
- ✅ Proxy configurável
- ✅ Timeout personalizável
- ✅ Exceções específicas por tipo de erro

---

## Requisitos

### Sistema
- Windows 2000 ou superior
- WinHTTP 5.1 (instalado por padrão no Windows XP SP2+)

### Verificação
```delphi
try
  CreateOleObject('WinHttp.WinHttpRequest.5.1');
  // WinHTTP disponível
except
  // WinHTTP NÃO disponível
end;
```

---

## Compatibilidade

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

## Instalação

1. Copie `Request.WinHttp.pas` para seu projeto
2. Adicione ao uses: `uses Request.WinHttp;`
3. Compile e use!

---

## Exemplos de Uso

### GET Simples
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Writeln(Request.Get('https://api.exemplo.com/dados'));
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
    Request.PostJson('https://api.exemplo.com/usuarios', '{"nome":"Joao"}');
  finally
    Request.Free;
  end;
end;
```

### Com Headers e Auth
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.SetBearerToken('meu-token');
    Request.SetRequestHeader('Accept', 'application/json');
    Request.Get('https://api.exemplo.com/protegido');
  finally
    Request.Free;
  end;
end;
```

### Download de Arquivo
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.DownloadFile('https://exemplo.com/arquivo.zip', 'C:\arquivo.zip');
  finally
    Request.Free;
  end;
end;
```

### Tratamento de Erros
```delphi
var
  Request: TWinHttpRequest;
begin
  Request := TWinHttpRequest.Create;
  try
    Request.RaiseForStatus := True;
    Request.Get('https://api.exemplo.com/erro');
  except
    on E: EWinHttpTimeoutException do
      Writeln('Timeout');
    on E: EWinHttpResponseException do
      Writeln('HTTP ', E.HttpStatus);
    on E: EWinHttpException do
      Writeln('Erro: ', E.Message);
  end;
  Request.Free;
end;
```

---

## API Completa

### Métodos Principais
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

### Configuração
```delphi
procedure SetRequestHeader(const Name: string; const Value: string);
procedure SetBearerToken(const Token: string);
procedure SetBasicAuthentication(const UserName: string; const Password: string);
procedure SetTimeouts(ResolveTimeout, ConnectTimeout, SendTimeout, ReceiveTimeout: Integer);
procedure SetProxy(ProxyType: TProxyType; const ProxyServer: string = ''; const ProxyBypass: string = '');
```

### Propriedades
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

### Exceções
```delphi
EWinHttpException
EWinHttpTimeoutException
EWinHttpConnectionException
EWinHttpResponseException
EWinHttpCertificateException
```

---

## HTTPS/TLS

### Validação de Certificados
Por padrão, certificados são validados automaticamente:
- Certificado não expirado
- Autoridade confiável
- Hostname correto
- Cadeia válida

### Ignorar Erros (INSEGURO!)
```delphi
Request.IgnoreCertificateErrors := True; // ⚠️ Apenas para desenvolvimento!
```

---

## Segurança

### Boas Práticas
1. Nunca logue credenciais
2. Mantenha validação de certificados em produção
3. Use HTTPS sempre
4. Capture exceções apropriadamente

### Headers Protegidos
A biblioteca nunca registra: Authorization, Cookie, senhas ou tokens.

---

## Limitações Conhecidas

### Cookies
- ✅ Gerenciamento automático por domínio
- ❌ Sem acesso direto via API
- Workaround: `SetRequestHeader('Cookie', 'valor')`

### Async
- ⚠️ Modo async existe mas sem callbacks implementados
- ✅ Use modo síncrono (default)

### ClearRequestHeaders
- ❌ Não suportado pelo WinHTTP
- Workaround: Crie nova instância

### Thread Safety
- ⚠️ Uma instância por thread!
- Objeto COM não é thread-safe

---

## License

MIT License - Use livremente.

---

## Links

- [Microsoft WinHTTP Docs](https://learn.microsoft.com/windows/win32/winhttp/winhttp-start-page)