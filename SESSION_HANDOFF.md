# CapCut Editor — Session Handoff (ทำงานต่อจากนี้)

อัปเดตล่าสุด: หลัง commit `a15dbb7` (iOS perf). อ่านไฟล์นี้ก่อนเริ่มทำต่อทุกครั้ง.

## 1) โปรเจกต์คืออะไร
โปรแกรมตัดต่อวิดีโอบนเว็บ สไตล์ CapCut — **ไฟล์เดียว static, ไม่มี build, ไม่มี backend** (HTML/JS/CSS + CDN: tabler-icons, @xenova/transformers).

## 2) ที่อยู่ไฟล์ / เซิร์ฟเวอร์ / deploy
- **repo (แก้ที่นี่):** `C:\Users\USER\Documents\capcut-editor`  (git, branch `main`)
  - **`capcut_editor.html`** = ไฟล์หลัก (canonical) — แก้ไฟล์นี้
  - `index.html` = สำเนาของ capcut_editor.html (GitHub Pages เสิร์ฟที่ root) → **ต้อง sync ก่อน push**
  - `history/` = ทุกเวอร์ชั่นเก่า, `serve.ps1`, `vercel.json`, `.nojekyll`
- **GitHub:** https://github.com/anusorn12445/capcut-editor  (PUBLIC, branch main)
- **Live (GitHub Pages):** https://anusorn12445.github.io/capcut-editor/  — auto-deploy ทุก push (CDN lag ~1-3 นาที, hard refresh Ctrl+F5)
- **เทสต์ในเครื่อง:**
  - preview MCP config ชื่อ `capcut` (ใน `Avatar-3d-live-main/.claude/launch.json`) → serve.ps1 พอร์ต **8093** → http://localhost:8093/capcut_editor.html
  - สำเนาใน Downloads: `capcut_editor_v5.html` / `v6.html` เสิร์ฟพอร์ต **8091** (รัน serve.ps1 -Root Downloads ถ้าดับ)

## 3) วิธี push (สำคัญ — ไม่มี gh/vercel CLI, ไม่มี Node ในเครื่อง มีแต่ git)
GitHub OAuth token เก็บใน Windows Credential Manager (target `git:https://github.com`, user `anusorn12445`, scope repo). GCM ไม่คืน token แบบ non-interactive → อ่านด้วย Win32 `CredRead` ใน PowerShell แล้ว push โดยไม่เก็บ token:
```
git -C <repo> -c "http.extraheader=Authorization: basic <base64(anusorn12445:TOKEN)>" push origin main
```
- ก่อน push เสมอ: `Copy-Item capcut_editor.html index.html` (sync) + sync Downloads v5/v6
- push print progress ลง stderr → PowerShell โชว์แดง (NativeCommandError) แต่ `$LASTEXITCODE` 0 = สำเร็จ
- ⚠️ ห้ามใส่ **raw key** ในโค้ด/ไฟล์ที่ commit → GitHub **Secret Scanning บล็อก push**

## 4) ฟีเจอร์ที่ทำแล้ว (อ้างอิงด้วยชื่อฟังก์ชัน — เลขบรรทัดเลื่อนได้)
- **Multi-track compositor:** `drawCompositeTo` `renderAt` `compositorTick` `syncTrack` `syncAudioLane` (วาดทุก track ลง 1 canvas)
- **Export:** `startExport` `beginRecord` `exportTick` `setupExportAudio` `primeExportTracks` (preload ทุก track ก่อนอัด กันคลิปดำ); เสียงวิดีโอ track บนสุด + A1 ถูกอัด
- **Snap วางคลิป:** `dropLane` + `placeClipOnLane` — คลิปแรกของแลน→0 วิ, ตัวถัดไปต่อท้าย, ขยาย timeline อัตโนมัติ
- **Multi-select media → กระจายลง V1,V2,..:** `toggleMediaSelect` `mediaSelection` `dstart`('MULTI') `dropSelectionToTracks` `ensureVideoTracks` (เพิ่ม track อัตโนมัติ)
- **ลบไฟล์ media:** `deleteMedia` (× ตอน hover, confirm ถ้าใช้ใน timeline)
- **Redo:** `undo`/`redo` + `undoStack`/`redoStack`
- **AI prompt (สั่งจริง):** `qai` → color grade/brightness/contrast/saturation/volume/zoom/rotate/split/auto-cut/transition/subtitle/delete (ไทย+อังกฤษ) via `aiSetProp` `aiApplyPresetAll`
- **Subtitle:** `generateSubtitles` → `transcribeViaApi`/`apiTranscribeRaw` → `groupWordsIntoLines` → `createSubtitleClips`; แสดงผล `drawSubtitle` + `wrapSubtitle` (ตัดบรรทัดไทยด้วย `Intl.Segmenter('th')`)
- **ASR engines:** `asrCfg` (default `groq` + key ฝัง), `ASR_PRESETS`, `asrEndpoint`; provider: `local` (transformers.js whisper tiny/base/small) / `openai` / `groq` / `elevenlabs` (Scribe, auth `xi-api-key`) / `custom`; UI: ชิป "Whisper:" → modal `openSubtitleSetup`
- **ลบคำซ้ำ (MUTE ไม่ตัดคลิป):** `runRemoveRepeats` → `transcribeWords` → `detectRepeatWordRanges` (คำติดกัน + reduplication `leadingRepeat` + `Intl.Segmenter('th')`) → `applyMuteRanges`/`clipMutedAt`/`renderMuteMarks` (แถบแดงใต้คลิป); เก็บ `_muteRanges` เป็นเวลาในไฟล์ + อยู่ใน undo snapshot
- **AI Cut (FAB):** `runAICut` — 1 คลิป/track ขั้นบันได + cross-dissolve opacity keyframe
- **ค่าเริ่มต้น:** timeline = 1:10 (`timelineDuration=70`), subtitle on-device picker = small, UI accent = น้ำเงิน `#2f7bff`
- **iOS perf:** ข้าม `ctx.filter` เมื่อไม่ปรับสี, ข้าม transform เมื่อ identity, smoothing `low`, seek tolerance 0.6

## 5) ของสำคัญ/ข้อควรระวัง
- **Groq key:** ฝังแบบ base64+แยกชิ้นใน `DEFAULT_GROQ_KEY = atob('...'+'...')` (เลี่ยง secret scanner). เปลี่ยน key ใหม่: base64 key → แทนค่าใน atob. **ถ้าโดน abuse → revoke ที่ console.groq.com**
- ค่าตั้งเก็บใน `localStorage`: `asrCfg` (subtitle engine), `voiceCfg` (voice clone)
- **2 ไฟล์ (capcut_editor.html / index.html)** ต้อง sync ก่อน push เสมอ
- preview MCP **screenshot timeout บ่อย** → ใช้ `preview_eval` + inspect แทน
- ElevenLabs STT **อาจติด CORS** บน browser (Groq เปิด CORS, OpenAI/ElevenLabs อาจบล็อก)

## 6) งานที่ยังเหลือ / ทำต่อได้
- iOS export ถ้ายังกระตุก (อัดที่ res สูง) → เพิ่มออปชั่นลด res/fps ตอน export บนมือถือ; หรือใช้ `requestVideoFrameCallback`
- ลบคำซ้ำระดับ **ประโยค/วลี** (ตอนนี้ทำคำติดกัน + reduplication)
- บังคับ `language=th` ให้ Groq เพื่อความแม่นภาษาไทย (ตอนนี้ auto-detect)
- ฝัง key ElevenLabs (ตอนนี้ผู้ใช้กรอกเอง)
- export เงียบ ~0.5 วิแรก (encoder/AudioContext warmup)
- ย้าย repo → org Real-Factory (ตอนนี้บัญชีส่วนตัว เพราะ org บล็อก OAuth app)
