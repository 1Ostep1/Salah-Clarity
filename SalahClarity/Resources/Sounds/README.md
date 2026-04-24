# Azan notification sound

> ⚠️ **The live `azan.caf` now lives at `SalahClarity/azan.caf`** (next to
> `Assets.xcassets`). This folder is kept only for documentation.

## Why not here?

`UNNotificationSound(named: "azan.caf")` looks up the file at the **root of
the main app bundle**. Because this project uses
`PBXFileSystemSynchronizedRootGroup` (Xcode 16 synchronized groups), the
physical folder layout is preserved when files are copied into the `.app`.

So a file placed at `SalahClarity/Resources/Sounds/azan.caf` ends up at
`.app/Sounds/azan.caf` — iOS can't find it with the bare name and silently
falls back (often to no sound at all). The fix is to place the file at the
top level of the app target:

```
SalahClarity/
├── App/
├── Assets.xcassets/
├── azan.caf        ← here
├── Features/
├── Models/
└── ...
```

## iOS constraints

- **Format**: CAF (Core Audio Format), AIFF, or WAV only. MP3 is not
  allowed for notification sounds.
- **Length**: must be **30 seconds or shorter** (the current `azan.caf`
  is ~29 s — fine).
- **Codec**: Linear PCM, MA4 (IMA/ADPCM), µLaw, or aLaw. The current
  file is 16-bit PCM @ 22 kHz stereo — well within spec.

## Converting an MP3 to CAF

```sh
# Trim to ≤30s AND convert to CAF in one step
afconvert -f caff -d LEI16@22050 -c 1 \
  --trim 0:0:30 \
  input-azan.mp3 azan.caf
```

Or with ffmpeg:

```sh
ffmpeg -i input-azan.mp3 -t 30 -ac 1 -ar 22050 \
  -c:a pcm_s16le -f caf azan.caf
```
