# วิธีรันแอปบน emulator / simulator

คู่มือคำสั่งสำหรับรัน MoneyLens บนเครื่องจำลอง (Mac) ใช้ร่วมกับ [README.md](README.md)
ค่าที่เป็นความลับ (คีย์ที่ไม่ใช่ publishable) ห้ามใส่ในแอปหรือใน git

## 1. ครั้งแรกบนเครื่องใหม่

```sh
cd ~/MoneyLens
flutter pub get
dart run build_runner build      # สร้างโค้ด Drift (*.g.dart)
flutter gen-l10n                 # สร้างไฟล์ข้อความ ไทย/อังกฤษ
flutter doctor                   # ตรวจว่า Flutter / Android SDK / Xcode พร้อม
```

## 2. Android emulator

### 2.1 เปิด emulator

```sh
# ดูรายชื่อเครื่องจำลองที่มี (ตัวอย่าง: Pixel_9, Medium_Phone_API_36)
~/Library/Android/sdk/emulator/emulator -list-avds

# เปิดเครื่อง (ใส่ & หรือเปิดอีกแท็บ terminal เพราะคำสั่งนี้ค้างอยู่ตลอด)
~/Library/Android/sdk/emulator/emulator -avd Pixel_9

# รอจนบูตเสร็จ (ขึ้น 1 แปลว่าเสร็จ)
adb shell getprop sys.boot_completed

# ตรวจว่า Flutter เห็นเครื่อง (ปกติ id คือ emulator-5554)
flutter devices
```

หรือเปิดจาก Android Studio → Device Manager → ปุ่ม ▶

### 2.2 รันแอปแบบเชื่อม Supabase จริง (ใช้บ่อยที่สุด)

```sh
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxxxxx
```

- คีย์ `sb_publishable_...` ดูได้ที่ Supabase Dashboard → Project Settings → API Keys
  (เป็นคีย์สาธารณะที่ออกแบบให้ใส่ในแอปได้ แต่ **ห้ามใช้ `sb_secret_...` / `service_role`**)
- **ต้องใส่ `--dart-define` ทุกครั้งที่รัน** ถ้าลืม แอปจะเข้าโหมดจำลอง (ดูหัวข้อ 4)
- รอจน log ขึ้น `Supabase init completed` และ `Flutter run key commands`

ระหว่างที่ `flutter run` ทำงาน กดใน terminal นั้นได้:

| ปุ่ม | ทำอะไร |
|---|---|
| `r` | hot reload (โหลดโค้ดใหม่ คงสถานะ) |
| `R` | hot restart (เริ่มแอปใหม่ ใช้โค้ดล่าสุด) |
| `q` | หยุดและออก |
| `h` | ดูคำสั่งทั้งหมด |

### 2.3 ตัวเลือกเพิ่มเติม (ใส่ต่อท้ายคำสั่ง `flutter run`)

| ตัวเลือก | ใช้ทำอะไร |
|---|---|
| `--dart-define=ML_SAMPLE_DATA=true` | ใส่ข้อมูลตัวอย่าง และเปิดการสแกนสลิปแบบจำลอง |
| `--dart-define=ML_SCENARIO=offline` | ดูหน้าออฟไลน์ (ค่าอื่น: `dbError`, `loading`) |
| `--dart-define=SUPABASE_URL=https://...` | ใช้โปรเจกต์อื่น (ค่าเริ่มต้นคือโปรเจกต์ของเรา) |

## 3. iOS simulator

```sh
open -a Simulator                       # เปิด Simulator
xcrun simctl list devices available     # ดูรายชื่อเครื่อง
flutter devices                         # ดู id ของ simulator
flutter run -d <simulator-id> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxxxxx
```

ต้องมี Xcode และ CocoaPods (`sudo gem install cocoapods` หรือ `brew install cocoapods`)

## 4. โหมดจำลอง (ไม่ใส่คีย์)

```sh
flutter run -d emulator-5554
```

- ปุ่ม "ดำเนินการต่อด้วย Google" จะเข้าสู่ระบบเป็นผู้ใช้ตัวอย่างทันที ไม่เปิดเบราว์เซอร์
- ไม่ต่อ Supabase ไม่ซิงก์ เหมาะกับการดูหน้าตาและทดสอบ flow
- ถ้าเปิดแอปแล้วกด Google แล้วเข้าหน้าวันเกิดทันทีโดยไม่เด้งเบราว์เซอร์ แปลว่าอยู่โหมดนี้

## 5. ทดสอบ Google sign-in บน emulator

ต้องตั้งค่าครั้งเดียว (ดู README → "Sign-in (Google)"):

1. Supabase → Authentication → URL Configuration → Redirect URLs มี `com.moneylens.app://login-callback/`
2. Google Cloud → Audience → อีเมลที่ใช้ทดสอบอยู่ในรายการ **Test users**
3. บน emulator ต้องมี Chrome ที่เปิดหน้าเว็บได้ (ล็อกอิน Google ใน Chrome ไว้ จะกลับเข้าแอปได้เร็ว)

## 6. ทดสอบ

```sh
flutter test                              # unit + widget (ไม่ต้องเปิด emulator)
dart analyze lib test integration_test    # ตรวจโค้ด
flutter test integration_test -d emulator-5554   # ทดสอบบนเครื่องจริง/จำลอง (ใช้ผู้ใช้จำลอง)
```

## 7. Supabase ในเครื่อง (สำหรับรันเทสต์ SQL / ลอง migration) — ต้องมี Docker

```sh
open -a Docker                                          # เปิด Docker Desktop แล้วรอให้พร้อม
npx supabase@2.122.0 start -x edge-runtime,imgproxy,studio,logflare,vector,mailpit
npx supabase@2.122.0 db reset --local                   # ใช้ migration ทั้งหมดกับฐานข้อมูลในเครื่อง

# รันเทสต์ SQL ทีละชุด
for t in schema profiles sync delete_account; do
  docker exec -i supabase_db_MoneyLens psql -U postgres -v ON_ERROR_STOP=1 \
    < supabase/tests/${t}_test.sql
done

npx supabase@2.122.0 stop                               # หยุดเมื่อเสร็จ
```

ส่ง migration ขึ้นโปรเจกต์จริง (ทำหลังเทสต์ผ่านเท่านั้น):

```sh
npx supabase@2.122.0 db push
npx supabase@2.122.0 migration list --linked            # ดูว่าไฟล์ไหนขึ้นแล้ว
```

## 8. ดูสิ่งที่เกิดขึ้นบน emulator จากเครื่อง Mac

```sh
adb exec-out screencap -p > shot.png                    # แคปหน้าจอ
adb shell input tap 540 1200                            # แตะที่พิกัด (พิกเซลของจอจริง)
adb logcat -s flutter                                   # ดู log ของแอป
adb shell run-as com.moneylens.app ls app_flutter       # ดูไฟล์ฐานข้อมูลของแอป (moneylens_<user id>.sqlite)
```

## 9. หยุดทุกอย่าง

```sh
# หยุด flutter run: กด q ใน terminal หรือ
pkill -f "flutter_tools.snapshot run"

# ปิด emulator
adb emu kill

# ปิด Docker / Supabase ในเครื่อง
npx supabase@2.122.0 stop
osascript -e 'quit app "Docker"'
```

## 10. แก้ปัญหาที่เจอบ่อย

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | พื้นที่ emulator เต็ม ลอง `adb shell pm trim-caches 2G` ลบแอปที่ไม่ใช้ใน emulator หรือสร้าง emulator ใหม่ที่ให้พื้นที่มากกว่า (flutter จะถอนแอปเก่าแล้วติดตั้งใหม่ให้เอง ข้อมูลในเครื่องของแอปหายแต่ข้อมูลบน Supabase ไม่หาย) |
| `Lost connection to device` | `flutter run` หลุดจาก emulator แอปที่เปิดอยู่ไม่มีคีย์แล้ว (เข้าโหมดจำลอง) ให้หยุดแล้วรันใหม่ด้วยคำสั่งเต็ม |
| กด Google แล้วเข้าหน้าวันเกิดทันที ไม่เปิดเบราว์เซอร์ | อยู่โหมดจำลอง ลืมใส่ `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` |
| Google ขึ้น `access_denied` / `redirect_uri_mismatch` | อีเมลไม่ได้เป็น Test user หรือยังไม่ได้เพิ่ม Redirect URL (หัวข้อ 5) |
| ล็อกอินแล้วข้อมูลว่าง | รอซิงก์สักครู่ ดูสถานะที่ ตั้งค่า → โปรไฟล์ → "ซิงก์ข้อมูล" หรือแตะเพื่อซิงก์ทันที |
| emulator ปิดเอง | เครื่อง Mac หน่วยความจำไม่พอ ปิดโปรแกรมอื่น (โดยเฉพาะ Docker) แล้วเปิดใหม่ |
| Docker ค้าง (`docker info` ไม่ตอบ) | ปิดด้วย `osascript -e 'quit app "Docker"'` ถ้ายังค้างใช้ `pkill -f com.docker` แล้วเปิดใหม่ รอ 1–2 นาที |
| `supabase start` ขึ้น `ContainerCreateError` | Docker ยังเปิดไม่เสร็จ รอแล้วสั่งซ้ำ |
| `build_runner` / ข้อความ `AppLocalizations` ไม่เจอ | รัน `dart run build_runner build` และ `flutter gen-l10n` |
| คำสั่ง `sed -i` ใช้ไม่ได้บน Mac | macOS ต้องเขียน `sed -i '' 's/a/b/' ไฟล์` |
