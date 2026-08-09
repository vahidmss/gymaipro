# App images

Bundled under `images/` via `pubspec.yaml` (`- images/`).

## In use

| File | Used for |
|------|----------|
| `poster1.jpg` … `poster5.jpg` | Welcome + dashboard carousel |
| `gymai_body_front_v2.png` | Muscle heatmap (front) |
| `gymai_body_back_v2.png` | Muscle heatmap (back) |
| `breakfast.png` / `lunch.png` / `dinner.png` / `snack.png` | Meal section icons |
| `gymaifoodplaceholder.png` / `food_placeholder.png` | Food placeholders |
| `whey.png` | Supplement meal card |
| `log.png` | Home workout hero |
| `calorymeter.jpg` | Home calorie hero |
| `gymaicoach.jpg` | Home AI coach banner |
| `logoforlightmode.png` | Home AppBar (light) |
| `logofordarkmode.png` | Home AppBar (dark) |
| `mainlogo_no_bg.png` | App update / chrome dialog |
| `GYMAI_logo_transparent.png` | Auth + exercise builder |
| `GymAI.jpg` | Launcher / splash / AI trainer avatar |

## Removed

League badge images (`bronze.png` … `diamond.png`) — UI now uses emoji/color chips, not asset art.


## Optional CDN

If you host a copy on the server:

```
https://gymaipro.ir/static/app-images/
```

`AppAssetConfig.remoteFileNames` is currently empty — everything loads from the APK.
