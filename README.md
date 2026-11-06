# Track Calo

Ứng dụng Android theo dõi calo và bữa ăn cá nhân, thiết kế cho người Việt. Local-first: không tài khoản, không quảng cáo, không gửi dữ liệu lên mạng.

## Tính năng

- Thiết lập hồ sơ và mục tiêu calo theo Mifflin–St Jeor, chọn mục tiêu giảm / giữ / tăng cân.
- Màn **Hôm nay**: vòng calo còn lại, macro đạm / tinh bột / béo, nước, các bữa trong ngày.
- **Thêm bữa**: tìm món Việt không dấu (`pho bo` khớp “Phở bò”), gần đây, yêu thích, tất cả, món tự tạo; chỉnh khẩu phần theo gram hoặc theo bát/tô/đĩa; giữ món tự tạo để xóa.
- **Bữa quen**: lưu một bữa đã ghi thành combo và thêm lại bằng một chạm.
- **Nhật ký**: xem theo ngày, sửa/xóa món, sao chép bữa hôm qua.
- **Tiến độ**: cân nặng và biểu đồ, calo 7 ngày, chuỗi ngày ghi, gợi ý đạm/cân nặng.
- **Cài đặt**: hồ sơ, mục tiêu tay, kiểu macro, mục tiêu nước, xuất/nhập JSON, xóa dữ liệu.
- 113 món Việt có sẵn với khẩu phần gợi ý; có thể tạo món riêng.

## Cài đặt

Tải APK tại [GitHub Releases · Track Calo](https://github.com/Sang6215/track-calo/releases/latest).

```text
TrackCalo-v1.0.2.apk
SHA-256: 431c953a76c8ae20ef9edeef060e28b4132f67ba24b5dbf5ed345c6bb22be34e
```

Cài qua ADB:

```bash
adb install -r TrackCalo-v1.0.2.apk
```

Bản build gốc nằm ở `build/app/outputs/flutter-apk/app-release.apk`.

### Bản 1.0.2

- Logo mới gồm bát cơm trắng, chiếc lá và vòng theo dõi calo màu vàng trên nền xanh dương.
- Đồng bộ logo ở màn thiết lập, cài đặt và biểu tượng ngoài màn hình điện thoại.
- Bổ sung adaptive icon cho Android, chừa lề an toàn khi launcher bo tròn biểu tượng.
- Logo gốc và prompt nằm trong `assets/branding/`; xuất lại các kích thước icon bằng `python tools/generate_launcher_icons.py` (cần Pillow).
- Cài bằng `adb install -r` để cập nhật và giữ dữ liệu ứng dụng hiện tại.

Hoặc chép APK sang điện thoại và mở để cài (cho phép cài từ nguồn không xác định). APK dùng debug keystore của máy build; nếu cần cập nhật về sau, build lại trên cùng máy hoặc tạo keystore release riêng.

## Build

Yêu cầu: Flutter 3.41+, Android SDK 36, JDK 21.

```bash
export ANDROID_HOME="D:/code/track_ta/.tooling/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
flutter pub get
flutter build apk --release
```

Nếu SDK nằm chỗ khác, đổi `ANDROID_HOME` cho đúng. `android/local.properties` không được commit; đặt `ANDROID_HOME` là đủ để build. `kotlin.incremental=false` được bật sẵn để tránh lỗi cache Kotlin khi project ở ổ D: còn pub cache ở ổ C:.

Chạy thử trên điện thoại:

```bash
flutter run --release
```

## Kiểm thử

```bash
flutter analyze
flutter test
```

Hiện có 13 unit test cho logic TDEE/macro/tìm kiếm/store/khôi phục backup và 2 widget test cho onboarding và màn Hôm nay. Toàn bộ 15 test đang xanh; `flutter analyze` sạch.

## Dữ liệu và quyền riêng tư

- Dữ liệu nằm trong bộ nhớ riêng của ứng dụng: `bua_data.json`, ảnh không có trong phiên bản này.
- `android:allowBackup="false"`: Android không tự đưa dữ liệu lên Google Drive.
- Ứng dụng không xin quyền `INTERNET`.
- Tự động sao lưu một bản mỗi ngày vào `backups/`, giữ 7 bản gần nhất. Bản này nằm trong bộ nhớ ứng dụng và mất khi gỡ app — dùng **Xuất bản sao lưu** trong mục “Tôi” để giữ tệp JSON ra ngoài.
- Không có API key, không có tài khoản.

## Giới hạn đã biết

- Giá trị dinh dưỡng là ước tính tham khảo, không thay thế tư vấn y khoa.
- Chưa có quét barcode, nhận diện món bằng ảnh, nhắc nhở theo giờ, đồng bộ đám mây.
- Release đang ký bằng debug key; phù hợp dùng cá nhân, không phù hợp phát hành Play Store.
- Đã chạy thử trên emulator Android 15 (1080×2400): onboarding, thêm món, nhật ký, tiến độ, cài đặt và xuất backup qua share sheet. Bản 1.0.2 đã được cài cập nhật thành công trên vivo V2352A (Android 16), xác nhận phiên bản 1.0.2 / mã bản dựng 3, mở ứng dụng và kiểm tra logo mới. Chưa kiểm tra lại toàn bộ các luồng tính năng trên điện thoại thật.

## Cấu trúc

```text
lib/
  main.dart              khởi động, chọn onboarding hoặc app shell
  models.dart            hồ sơ, món, log, combo, công thức TDEE/macro
  store.dart             lưu JSON, backup, truy vấn theo ngày
  theme.dart             màu, font, component theme
  widgets.dart           vòng calo, macro bar, bottom bar, date strip
  screens/               onboarding, today, add food, diary, progress, settings
assets/
  data/seed_foods.json   kho món khởi đầu
  fonts/                 Be Vietnam Pro + Fraunces (OFL)
```

## Nguồn dữ liệu

Số liệu dinh dưỡng được tổng hợp và làm tròn từ bảng thành phần dinh dưỡng thực phẩm Việt Nam và dữ liệu USDA/Open Food Facts, dùng cho mục đích cá nhân. Nếu cần độ chính xác cao, hãy tự tạo món với nhãn dinh dưỡng thật.
