$prefix = "http://localhost:3000/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "Server started at $prefix"
} catch {
    Write-Host "Error starting listener: $_"
    exit 1
}

$root = "c:\Users\Asus\Documents\Amnik Real estate landing page"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response
        
        try {
            $rawPath = $req.Url.AbsolutePath.TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($rawPath)) { 
                $rawPath = "index.html" 
            }
            
            # Sanitize path to prevent illegal characters
            $safePath = [System.Uri]::UnescapeDataString($rawPath)
            # Remove any query / invalid chars
            $invalidChars = [System.IO.Path]::GetInvalidPathChars()
            foreach ($c in $invalidChars) {
                $safePath = $safePath.Replace($c.ToString(), "")
            }
            $safePath = $safePath.Replace('"', '').Replace("'", "")
            
            $filePath = Join-Path $root $safePath

            if ([System.IO.File]::Exists($filePath)) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $contentType = switch ($ext) {
                    ".html" { "text/html; charset=utf-8" }
                    ".css"  { "text/css; charset=utf-8" }
                    ".js"   { "application/javascript; charset=utf-8" }
                    ".png"  { "image/png" }
                    ".jpg"  { "image/jpeg" }
                    ".jpeg" { "image/jpeg" }
                    ".svg"  { "image/svg+xml" }
                    default { "application/octet-stream" }
                }
                $res.ContentType = $contentType
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $res.StatusCode = 404
                $buf = [System.Text.Encoding]::UTF8.GetBytes("File Not Found")
                $res.OutputStream.Write($buf, 0, $buf.Length)
            }
        } catch {
            Write-Host "Request error: $_"
        } finally {
            try { $res.OutputStream.Close() } catch {}
            try { $res.Close() } catch {}
        }
    } catch {
        Write-Host "Listener loop error: $_"
    }
}
