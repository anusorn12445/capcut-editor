param(
  [int]$Port = 8080,
  [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.htm'  = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.glb'  = 'model/gltf-binary'
  '.gltf' = 'model/gltf+json'
  '.hdr'  = 'image/vnd.radiance'
  '.exr'  = 'image/x-exr'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.wasm' = 'application/wasm'
  '.bin'  = 'application/octet-stream'
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving '$Root' at $prefix  (Ctrl+C to stop)"

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    $rel = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'index.html' }
    $path = Join-Path $Root $rel

    # prevent path traversal outside root
    $fullRoot = [System.IO.Path]::GetFullPath($Root)
    $fullPath = [System.IO.Path]::GetFullPath($path)
    if (-not $fullPath.StartsWith($fullRoot)) {
      $res.StatusCode = 403; $res.Close(); continue
    }

    $isHead = ($req.HttpMethod -eq 'HEAD')
    try {
      if (Test-Path $fullPath -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
        $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
        $res.ContentLength64 = $bytes.Length
        if (-not $isHead) { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
        Write-Host ("200  {0}  {1}" -f $req.HttpMethod, $rel)
      } else {
        $res.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rel")
        $res.ContentLength64 = $msg.Length
        if (-not $isHead) { $res.OutputStream.Write($msg, 0, $msg.Length) }
        Write-Host ("404  {0}  {1}" -f $req.HttpMethod, $rel)
      }
    } catch {
      Write-Host ("ERR  {0}  {1}" -f $rel, $_.Exception.Message)
    } finally {
      try { $res.Close() } catch {}
    }
  }
} finally {
  $listener.Stop()
}
