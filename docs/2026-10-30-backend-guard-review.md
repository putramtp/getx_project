# Review Guard Backend & Sinkronisasi App — 30 Oktober 2026

Ringkasan semua temuan dari sesi review guard backend (`D:\laravel-project\MasterSystemBackend`)
dan penyesuaian app Flutter (`D:\PROJECT\getx_project`) setelah merge commit Jimmy (`4bbae472`).

> **Status:** semua perubahan di kedua repo **belum di-commit**.

---

## 1. Ringkasan

| Area | Selesai | Terbuka |
|---|---|---|
| Guard kritis backend | 5 (§2.1) | 0 |
| Temuan sedang/kecil backend | 8 (§2.2, 2 di antaranya oleh Jimmy) | — |
| Bug tambahan backend | 3 (§2.3) | — |
| Penyesuaian app ke perubahan backend | 5 (§2.4) | — |
| Bug app | 2 (§2.5) | — |
| Bug kode | — | 3 (§5.1) |
| Butuh keputusan | — | 4 (§5.2) |
| Kecil / performa | — | 3 (§5.3) |
| Verifikasi / environment | dev DB tersinkron (§3) | 6 (§5.4) |

---

## 2. Yang sudah dikerjakan

### 2.1 Backend — guard kritis

| # | Temuan | Perbaikan |
|---|---|---|
| 1 | `createOutflowData` (scan outflow dari app) tidak memakai guard yang dipakai web `store()`: tanpa cek approval Outflow Request, OA dibatalkan, MR dibatalkan, dan stok *free-to-issue* | Ditambah `assertPayloadOasNotCancelled`, `assertPayloadOutflowRequestsApproved`, `assertReservationsNotFromCancelledMr`, `validateQtyOnStore` (pesan per baris digabung jadi satu `DomainException`) |
| 2 | `line_id` yang sama dikirim dua kali dalam satu payload lolos cek "melebihi qty" (receive & outflow) | `mergeLocalLinesById()` di `StockMutationTrait` — entri digabung per `line_id` sebelum dicek |
| 3 | Receive tanpa row lock → dua receipt bersamaan bisa lolos cek over-receive | `lockPoLines()` (`lockForUpdate`, urut id) di `createReceiveData`, `validateQtyOnStore`, `validateQtyOnUpdate` |
| 4 | Serial BATCH di outflow selalu dinonaktifkan seluruhnya, tanpa cek sisa isi batch | `attachWorkerSelectedOutflowSerials`: sisa batch = IN − OUT, pengambilan melebihi sisa ditolak, batch tetap aktif selama masih ada sisa, entri batch yang sama dijumlah; serial UNIQUE dobel ditolak |
| 5 | `scanned[].id` tidak dibatasi ke item baris → serial item lain bisa dikeluarkan | `resolveOutflowSerial` dan `ExpiredStock::resolve` kini memfilter `item_id` |

### 2.2 Backend — temuan sedang/kecil

| # | Temuan | Perbaikan |
|---|---|---|
| 6 | Qty transaksi UNIQUE ≠ jumlah serial | Sudah ditutup oleh Jimmy (`assertSerialsNamed`) |
| 7 | `OutflowDataRequest` percaya flag `manage_sn` dari app | `withValidator` membaca `manage_sn` dari item di DB |
| 8 | PO/OR yang sudah dihapus (header soft-delete) masih bisa diterima/dikeluarkan → error PHP | Pesan jelas "has been deleted…" di receive & outflow |
| 9 | `createDelivery`: `id` tidak divalidasi, typo `defaultBillingAddresses`, tanpa lock | Validasi `exists:outflow_orders,id,deleted_at,NULL`, typo diperbaiki, `lockForUpdate` |
| 10 | `receive_number` unik tanpa validasi | Sudah ditutup oleh Jimmy (unik per supplier) |
| 11 | Picker invoice tanpa permission | `roLineBySupplierPurchaseInvoice` → `receive-order.view`, `ooLineByCustomerSalesInvoice` → `outflow-order.view`, `poLineBySupplierPurchaseInvoice` → `purchase-order.view` |
| 12 | `confirmSerials` tanpa batas ukuran `codes` | `max:500`, tiap kode `max:255` |
| — | Receive versi **web** juga lolos "baris PO sama dua kali" | `validateQtyOnStore/OnUpdate` menjumlah qty per `po_line_id` |

### 2.3 Backend — bug tambahan

| Bug | Perbaikan |
|---|---|
| Receive dari app tidak mengecek "unit utuh" untuk item serial (2,5 unit UNIQUE → 2 SKU; batch qty 0 → batch kosong) | `assertWholeSerialUnits()` di `createReceiveData` |
| Expiry item UNIQUE dari app dibuang (`expired_date => null`) → peringatan stok expired tidak pernah muncul | Tiap unit memakai expiry entri asalnya (mis. 2 exp Maret + 3 exp Juni) |
| `filled.*.expired_date` tanpa validasi → error SQL | Rule `nullable|date` |

### 2.4 App — penyesuaian ke perubahan backend (merge Jimmy)

| Perubahan backend | Penyesuaian app |
|---|---|
| Delivered wajib `receiver_name`; status hanya maju (`next_statuses`); delivery Delivered terkunci | Dialog "Received by", panel & dropdown hanya status berikutnya, edit disembunyikan saat Delivered, tampil "Received by" / "Delivered at" |
| `updated_by` diisi server | App tidak lagi mengirim `updated_by`; `AuthService.userId` & `GET /user/currentDetail` dihapus |
| Undo status (manager) & bukti pengiriman | Tombol "Undo to …" (dialog alasan) bila `undo.available`; kartu Proof of delivery (Take photo / From gallery via `image_picker`) |
| `409 expired_batch` | `ExpiredStockException` + `submitOutflowData()` (dialog daftar expired → kirim ulang `confirm_expired: true`) |
| Error teknis hanya `reference` | `checkResponse` menampilkan "Reference: …" |

### 2.5 App — bug

| Bug | Perbaikan |
|---|---|
| Status **Failed** (final) tersimpan tanpa konfirmasi | Konfirmasi untuk Cancelled dan Failed |
| Reservasi tanpa customer (WO/MR) tampil dengan Fill di By Request, lalu ditolak backend (INV-D-16) | **Opsi 1:** kartu "Work order reservation", detail read-only (banner, tanpa Fill/Scan, Continue nonaktif) |

### 2.6 Test

- **Backend:** `tests/Feature/Inventory/MobileScanGuardsTest.php` — 13 test (semua guard di atas); bersama test terkait: **24/24 lolos**.
- **App:** `flutter analyze` bersih; **97/97 unit test lolos** (baru: `delivery_model_test`, `expired_stock_exception_test`, `outflow_request_model_test`); `flutter build apk --debug` berhasil.
- **Patrol:** harness merotasi beberapa akun (`TEST_USERNAME` dipisah koma, `accountFor`) karena batas baru 20 login/jam/akun; `delivery_test` memilih delivery yang masih bisa diubah dan menangani dialog penerima/konfirmasi.

---

## 3. Environment dev yang sudah dibereskan

- **Tenant `mc` (`1c1df3fd…`) tertinggal 22 migrasi** merge Jimmy (`receiver_name`, `status_undone_*`, `expired_confirmed_*`, dll.) → `php artisan deploy:sync-tenants --tenants=1c1df3fd…`.
- **6 tenant lain** skemanya lengkap tapi izin baru (mis. `delivery.undo-status`) belum ada → `deploy:sync-tenants` untuk keenamnya.
- Hasil akhir: **7 tenant + central = 0 migrasi tertunda**, izin & kolom baru ada di semua tenant.
- **Backup sebelum perubahan** (semua dump lengkap):
  `C:\Users\Asus\AppData\Local\Temp\claude\D--PROJECT-getx-project\b6db45df-f2db-46d6-a0b1-acdc94a98925\scratchpad\tenant_<id>_backup_before_sync.sql`
- **Akun test** di tenant `mc`: `e2e_tester`, `e2e_tester2`, `e2e_tester3`, `e2e_tester4` (role admin, password sama). Password:
  `C:\Users\Asus\AppData\Local\Temp\claude\D--PROJECT-getx-project\b6db45df-f2db-46d6-a0b1-acdc94a98925\scratchpad\e2e_pw.txt`

---

## 4. Hasil Patrol E2E

| Run | Cakupan | Hasil | Catatan |
|---|---|---|---|
| 1 | Test 1–21 | 18 ✅ / 3 ❌ | Dihentikan otomatis (memori sistem rendah) |
| 2 | Test 16–42 | 24 ✅ / 3 ❌ | 15 menit |

Semua test pernah lolos minimal sekali, **kecuali 4**:

| Test | Penyebab |
|---|---|
| `delivery_test` › editing details then marking a status | Bug di test (label `RichText`); sudah diperbaiki, **belum diuji ulang di device** |
| `outflow_order_test` › outflowing a request line creates a delivery | ✅ **Lolos** setelah B3 (baris OA batal kini read-only) + perbaikan helper test |
| `receive_order_test` › receiving a PO line reaches confirm serials | Login gagal — tunnel ngrok putus |
| `receive_order_test` › receiving a supplier line reaches confirm serials | ✅ **Lolos** setelah B3 (baris tanpa harga kini read-only) + perbaikan helper test |

**Helper test yang diperbaiki (B3 memunculkannya):** `openOrderWithAction` membuka maks. 15 kartu (reservasi WO & request terblokir kini memenuhi atas list) dan menggulir Item Summary dengan `scrollUntilExists` — list yang hit-testable (bukan milik route di bawahnya), lalu `ensureVisible` sebelum tap. `e2eTest` menerima `tags`; selalu beri `--device` (Chrome/Edge ikut terdaftar → Patrol menunggu pilihan interaktif). Run ini memakai 1 unit `PO-SMP-SN-OPEN` (sisa 3) dan membuat 1 outflow tanpa delivery (tunnel putus di run sebelumnya) + 1 outflow dengan delivery di tenant `mc`.

---

## 5. Masih terbuka

### 5.1 Bug kode

| # | Bug | Lokasi | Dampak |
|---|---|---|---|
| B1 | ✅ **Selesai** — qty desimal membuat Item Summary crash. Kini semua qty lewat `safeToNum` (8 model line/header PO/OR, test `order_qty_parsing_test.dart`). Lalu D2 diputuskan: dukungan desimal penuh (lihat D2) | App: model line PO/OR + header `received`/`total` | — |
| B2 | ✅ **Selesai** — `exists:…,id,deleted_at,NULL` + pesan "A line has been removed from this document since it was opened. Reload it and try again." (+ terjemahan id) di `ReceiveDataRequest` & `OutflowDataRequest`; 2 test | Backend | — |
| B3 | ✅ **Selesai** — summary PO/OR mengirim `can_receive`/`can_issue` + `blocked_reason` dari guard yang sama dengan submit (`ReceiveOrderService::receiveBlocker`, `OutflowOrderService::issueBlockers`); app menampilkan baris read-only dengan alasan (ikon gembok, tanpa Fill/Scan), draft lama dibuang, Continue melewatinya. Cek qty & stok *free-to-issue* tetap saat submit | App + backend summary | — |

**B3 — cara kerja:** aturan tidak disalin ke app. Backend menjalankan assert yang sama dengan jalur submit per baris (approval di-cache per request) dan mengirim alasan pertamanya; `createReceiveData` kini memakai `receiveBlocker` yang sama, dan cek deleted/closed di `createOutflowData` dipindah ke `reservationStateRefusal` yang juga dipakai summary. Aturan baru cukup ditambahkan di blocker.

### 5.2 Butuh keputusan

| # | Masalah | Siapa |
|---|---|---|
| D1 | `closed.period` di `confirmSerials` — scan label setelah bulan ditutup → 409, padahal tidak mengubah stok; app tidak bisa mengirim alasan | Jimmy / tim |
| D2 | ✅ **Selesai** — qty desimal didukung penuh di receive & outflow (koma/titik, ≤ 6 desimal); item serial UNIQUE/BATCH tetap unit bulat. Backend: outflow `qty` `min:1` → `gt:0` + guard unit bulat untuk entri serial di `OutflowDataRequest` (3 test baru di `MobileScanGuardsTest`) | — |
| D3 | Reservasi WO dikeluarkan langsung dari app (opsi 2, `issue-by-work-order`) | Ditunda |
| D4 | Picker invoice (#11) kini butuh izin *view* dokumen sumber — user web tanpa izin itu akan 403 | Konfirmasi ke tim web |

### 5.3 Kecil / performa

| # | Masalah |
|---|---|
| K1 | ✅ **Selesai** — endpoint baru `GET /delivery/status-count` (satu `COUNT … GROUP BY status_id`, izin `delivery.view`); Home memakai hitungan Pending darinya |
| K2 | ✅ **Selesai** — `GET /delivery-status` kini mengirim `label`; app menampilkan label (pill, daftar, chip filter, panel "Now"/"Mark", dropdown, dialog, undo) dan tetap memakai `name` untuk logika |
| K3 | ✅ **Selesai** — bukti foto bisa diketuk → preview layar penuh (zoom) lewat `GET …/proofs/{media}/preview` (`ApiProvider.getBytes`); file non-gambar (PDF dari web) diarahkan ke web — belum bisa dibuka di app tanpa dependensi baru (`open_filex`) |

### 5.4 Verifikasi / environment

| # | Masalah |
|---|---|
| V1 | **Regresi belum dipastikan** untuk `WorkOrderCancelMaterialsTest` dan `OutboundSerialsRequiredTest` (memakai trait serial yang diubah) — gagal di run subset yang terhenti, belum dibandingkan dengan HEAD bersih. **Update (D2):** `OutboundSerialsRequiredTest` dijalankan ulang — semua test non-HTTP lolos, 3 yang gagal hanya karena tenancy (V2); `WorkOrderCancelMaterialsTest` belum |
| V2 | Test backend HTTP dengan `$tenancy = true` gagal di mesin ini ("Tenant could not be identified on domain mastersystembackend.test"), juga di HEAD bersih — puluhan file tidak bisa dipercaya sampai setup domain test diperbaiki |
| V3 | Full suite backend (±9.100 test) belum dijalankan — serial ±15–20 jam, tanpa paratest/CI |
| V4 | Patrol test delivery #6 belum diuji ulang di device |
| V5 | Tunnel ngrok sesekali putus (`Connection closed before full header`), dan HTTP 503 di Item Summary saat memori mesin rendah |
| V6 | Data dev untuk test receive: perlu PO terbuka **yang punya harga** (seeder sampel) |

### 5.5 Operasional

- Server lain (staging/production) yang menarik merge Jimmy **wajib** `php artisan deploy:sync-tenants` — tanpa itu Delivered/undo/expired error SQL. Rilis app versi baru setelah backend termigrasi.
- Hapus akun `e2e_tester*` bila tidak dipakai lagi.

---

## 6. Daftar file yang diubah

### Backend (`D:\laravel-project\MasterSystemBackend`)

- `app/Http/Controllers/Inventory/OutflowOrderController.php` — validasi `createDelivery`, permission picker
- `app/Http/Controllers/Inventory/PurchaseOrderController.php` — permission picker
- `app/Http/Controllers/Inventory/ReceiveOrderController.php` — permission picker
- `app/Http/Requests/Inventory/ConfirmSerialRequest.php` — batas `codes`
- `app/Http/Requests/Inventory/OutflowDataRequest.php` — `manage_sn` dari DB
- `app/Http/Requests/Inventory/ReceiveDataRequest.php` — validasi `expired_date`
- `app/Services/Inventory/OutflowOrderService.php` — guard web di `createOutflowData`, merge baris, OR terhapus, `createDelivery`
- `app/Services/Inventory/ReceiveOrderService.php` — lock, merge/jumlah per baris PO, PO terhapus, unit utuh
- `app/Support/Inventory/ExpiredStock.php` — scoping `item_id`
- `app/Traits/StockMutationTrait.php` — `mergeLocalLinesById`, batch outflow, scoping serial, expiry per unit
- `tests/Feature/Inventory/MobileScanGuardsTest.php` (baru)

### App (`D:\PROJECT\getx_project`)

- `lib/app/data/models/delivery_model.dart` — `receiverName`, `deliveredAt`, `nextStatusIds`, `proofs`, undo
- `lib/app/data/models/outlfow_request_model.dart` — `hasCustomer`
- `lib/app/data/providers/api_providers.dart` — `reference`, `ExpiredStockException`
- `lib/app/data/providers/delivery_provider.dart` — undo, upload bukti, tanpa `getCurrentUserId`
- `lib/app/global/widget/qty_input_dialogs.dart` — `_TextDialog` generik, dialog penerima & alasan undo
- `lib/app/modules/delivery/…` — controller, detail view, status panel, `delivery_proof_card.dart` (baru)
- `lib/app/modules/outflow_order/outflow_submit.dart` (baru) + kedua detail controller outflow
- `lib/app/modules/outflow_order/views/outflow_order_by_request_detail_view.dart` — reservasi WO read-only
- `lib/app/services/auth_service.dart` — hapus `userId`
- `patrol_test/common/harness.dart`, `patrol_test/delivery_test.dart`
- `pubspec.yaml` / `pubspec.lock` (+ registrant plugin desktop) — `image_picker`
- `test/…` — 3 file test baru
- `CLAUDE.md` — delivery, error handling, kredensial Patrol, reservasi WO
