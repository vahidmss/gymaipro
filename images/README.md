# App images for CDN upload

Upload **all files in this folder** to your server at:

```
https://gymaipro.ir/static/app-images/
```

Each file must be reachable directly, for example:

```
https://gymaipro.ir/static/app-images/poster1.png
https://gymaipro.ir/static/app-images/bronze.png
```

## Server setup (nginx example)

```nginx
location /static/app-images/ {
    alias /var/www/gymaipro/static/app-images/;
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

## Optional: override CDN base in `.env`

```
APP_ASSETS_CDN_BASE=https://gymaipro.ir/static/app-images
```

## Files list

| File | Used for |
|------|----------|
| bronze.png … diamond.png | League badges |
| poster1.png … poster5.png | Welcome + dashboard carousel |
| gymai_body_front_premium.png | Muscle heatmap (front) |
| gymai_body_back_premium.png | Muscle heatmap (back) |
| gymai_anatomy_body_front_back.png | Spare / future use |
| ai_robot.png | AI quick action button |

After upload, verify in mobile browser that each URL downloads/opens the image.

## Compress (recommended)

Before upload, compress PNGs to ~150–300 KB (TinyPNG, Squoosh, or `pngquant`).
WebP is supported by Flutter if you rename references in `AppAssetConfig`.
