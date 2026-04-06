resource "google_storage_bucket_object" "index" {
  name         = "index.html"
  bucket       = var.bucket_name
  content_type = "text/html"
  content      = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Nuon Static Site</title>
      <style>
        body { font-family: system-ui, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f5f5f5; }
        .card { background: white; padding: 3rem; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; }
        h1 { color: #1a1a2e; }
        p { color: #555; }
        code { background: #eee; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.9rem; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Deployed by Nuon</h1>
        <p>This static site is hosted on Google Cloud Storage with Cloud CDN.</p>
        <p>Install ID: <code>${var.install_id}</code></p>
      </div>
    </body>
    </html>
  HTML
}
