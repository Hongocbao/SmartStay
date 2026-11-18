-- =================================================================================
-- SMARTSTAY - CHUẨN HÓA SCHEMA, FOREIGN KEYS & SUPABASE STORAGE (END-TO-END)
-- Đảm bảo 100% bảng mở rộng có khóa ngoại (FK) nối về Phong, CuDan, NguoiDung, HoaDon, ChiSoSuDung
-- Không dùng DROP TABLE để bảo toàn dữ liệu hiện có trên Supabase!
-- =================================================================================

-- 1. Tạo Public Bucket 'smartstay-media' trên Supabase Storage để lưu Video/Ảnh thật
DO $$
BEGIN
    BEGIN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'smartstay-media',
            'smartstay-media',
            true,
            52428800,
            ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/webm', 'video/quicktime', 'video/x-matroska']
        )
        ON CONFLICT (id) DO UPDATE SET public = true;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
        DROP POLICY IF EXISTS "SmartStay Media Public Read" ON storage.objects;
        CREATE POLICY "SmartStay Media Public Read"
            ON storage.objects FOR SELECT
            TO anon, authenticated
            USING (bucket_id = 'smartstay-media');

        DROP POLICY IF EXISTS "SmartStay Media Public Upload" ON storage.objects;
        CREATE POLICY "SmartStay Media Public Upload"
            ON storage.objects FOR INSERT
            TO anon, authenticated
            WITH CHECK (bucket_id = 'smartstay-media');

        DROP POLICY IF EXISTS "SmartStay Media Public Update" ON storage.objects;
        CREATE POLICY "SmartStay Media Public Update"
            ON storage.objects FOR UPDATE
            TO anon, authenticated
            USING (bucket_id = 'smartstay-media');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $$;

-- 2. Tạo bảng (nếu chưa có) kèm đầy đủ cột khóa ngoại
CREATE TABLE IF NOT EXISTS "ChoDoCuTin" (
    "MaTin" VARCHAR(64) PRIMARY KEY,
    "MaPhong" INT NULL,
    "MaCuDanBan" INT NULL,
    "MaCuDanGiuCho" INT NULL,
    "TieuDe" TEXT NOT NULL,
    "DanhMuc" VARCHAR(50) NOT NULL DEFAULT 'electronics',
    "GiaBan" NUMERIC(18, 2) NOT NULL DEFAULT 0,
    "GiaGoc" NUMERIC(18, 2) NOT NULL DEFAULT 0,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "NguoiBan" TEXT NOT NULL DEFAULT 'Cư dân SmartStay',
    "TinhTrang" TEXT NOT NULL DEFAULT 'Mới đăng',
    "MoTa" TEXT NOT NULL DEFAULT '',
    "HinhAnhUrl" TEXT NULL,
    "VideoUrl" TEXT NULL,
    "TrangThai" VARCHAR(40) NOT NULL DEFAULT 'Đang bán',
    "NguoiGiuCho" TEXT NULL,
    "SoSaoTrungBinh" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "SoLuotDanhGia" INT NOT NULL DEFAULT 0,
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "ChoDoCuDanhGia" (
    "Id" SERIAL PRIMARY KEY,
    "MaTin" VARCHAR(64) NOT NULL,
    "MaCuDan" INT NULL,
    "MaPhong" INT NULL,
    "NguoiDanhGia" TEXT NOT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "SoSao" INT NOT NULL DEFAULT 5,
    "BinhLuan" TEXT NOT NULL,
    "ThoiGian" VARCHAR(64) NOT NULL DEFAULT 'Vừa xong',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "VeKhachVangLai" (
    "MaVe" VARCHAR(64) PRIMARY KEY,
    "MaPhong" INT NULL,
    "MaCuDan" INT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "TenKhach" TEXT NOT NULL,
    "SoDienThoai" VARCHAR(32) NULL,
    "MaPin" VARCHAR(16) NOT NULL,
    "HieuLucDen" TEXT NOT NULL,
    "TrangThai" VARCHAR(40) NOT NULL DEFAULT 'Đang hiệu lực',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "ChiaTienPhong" (
    "MaChia" VARCHAR(64) PRIMARY KEY,
    "MaPhong" INT NULL,
    "MaHoaDon" INT NULL,
    "MaCuDanTao" INT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "TieuDe" TEXT NOT NULL,
    "TongTien" NUMERIC(18, 2) NOT NULL DEFAULT 0,
    "SoThanhVien" INT NOT NULL DEFAULT 3,
    "MoiNguoi" NUMERIC(18, 2) NOT NULL DEFAULT 0,
    "TrangThai" VARCHAR(40) NOT NULL DEFAULT 'Chờ đóng',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "ChiSoTuKiemTra" (
    "Id" SERIAL PRIMARY KEY,
    "MaPhong" INT NULL,
    "MaCuDan" INT NULL,
    "MaChiSoChinhThuc" BIGINT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "CheDo" VARCHAR(24) NOT NULL DEFAULT 'both',
    "DienKyTruoc" DOUBLE PRECISION NOT NULL DEFAULT 1420,
    "DienMoiChup" DOUBLE PRECISION NOT NULL DEFAULT 1540,
    "NuocKyTruoc" DOUBLE PRECISION NOT NULL DEFAULT 84,
    "NuocMoiChup" DOUBLE PRECISION NOT NULL DEFAULT 92,
    "TongTienTamTinh" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "TomTatTieuThu" TEXT NULL,
    "NguonCapNhat" TEXT NULL,
    "AnhBangChungUrl" TEXT NULL,
    "TrangThaiDuyet" VARCHAR(32) NOT NULL DEFAULT 'Chờ quản lý duyệt',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "NhatKyCuocGoi" (
    "MaCuocGoi" VARCHAR(64) PRIMARY KEY,
    "MaNguoiGoi" INT NULL,
    "MaNguoiNhan" INT NULL,
    "MaCuDan" INT NULL,
    "MaPhong" INT NULL,
    "NguoiGoi" TEXT NOT NULL,
    "VaiTroNguoiGoi" VARCHAR(32) NOT NULL DEFAULT 'CuDan',
    "NguoiNhan" TEXT NOT NULL,
    "VaiTroNguoiNhan" VARCHAR(32) NOT NULL DEFAULT 'QuanLy',
    "LoaiCuocGoi" VARCHAR(24) NOT NULL DEFAULT 'Video',
    "NoiDungTraoDoi" TEXT NOT NULL DEFAULT '',
    "ThoiLuongGiay" INT NOT NULL DEFAULT 0,
    "TrangThai" VARCHAR(40) NOT NULL DEFAULT 'Đã kết nối',
    "ThoiDiem" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Bổ sung cột FK bằng ALTER TABLE IF NOT EXISTS cho các bảng đã tạo từ phiên bản trước
ALTER TABLE "ChoDoCuTin" ADD COLUMN IF NOT EXISTS "MaPhong" INT NULL;
ALTER TABLE "ChoDoCuTin" ADD COLUMN IF NOT EXISTS "MaCuDanBan" INT NULL;
ALTER TABLE "ChoDoCuTin" ADD COLUMN IF NOT EXISTS "MaCuDanGiuCho" INT NULL;

ALTER TABLE "ChoDoCuDanhGia" ADD COLUMN IF NOT EXISTS "MaCuDan" INT NULL;
ALTER TABLE "ChoDoCuDanhGia" ADD COLUMN IF NOT EXISTS "MaPhong" INT NULL;

ALTER TABLE "VeKhachVangLai" ADD COLUMN IF NOT EXISTS "MaPhong" INT NULL;
ALTER TABLE "VeKhachVangLai" ADD COLUMN IF NOT EXISTS "MaCuDan" INT NULL;

ALTER TABLE "ChiaTienPhong" ADD COLUMN IF NOT EXISTS "MaPhong" INT NULL;
ALTER TABLE "ChiaTienPhong" ADD COLUMN IF NOT EXISTS "MaHoaDon" INT NULL;
ALTER TABLE "ChiaTienPhong" ADD COLUMN IF NOT EXISTS "MaCuDanTao" INT NULL;

ALTER TABLE "ChiSoTuKiemTra" ADD COLUMN IF NOT EXISTS "MaPhong" INT NULL;
ALTER TABLE "ChiSoTuKiemTra" ADD COLUMN IF NOT EXISTS "MaCuDan" INT NULL;
ALTER TABLE "ChiSoTuKiemTra" ADD COLUMN IF NOT EXISTS "MaChiSoChinhThuc" BIGINT NULL;
ALTER TABLE "ChiSoTuKiemTra" ADD COLUMN IF NOT EXISTS "TrangThaiDuyet" VARCHAR(32) NOT NULL DEFAULT 'Chờ quản lý duyệt';

ALTER TABLE "NhatKyCuocGoi" ADD COLUMN IF NOT EXISTS "MaNguoiGoi" INT NULL;
ALTER TABLE "NhatKyCuocGoi" ADD COLUMN IF NOT EXISTS "MaNguoiNhan" INT NULL;
ALTER TABLE "NhatKyCuocGoi" ADD COLUMN IF NOT EXISTS "MaCuDan" INT NULL;
ALTER TABLE "NhatKyCuocGoi" ADD COLUMN IF NOT EXISTS "MaPhong" INT NULL;

-- Bổ sung cột FK cho 3 bảng lõi trước đó còn đứng riêng lẻ (CauHinhToChuc, TriThucAiRAG, LichSuGiaoDichVi, PhieuDatGiuCho)
ALTER TABLE IF EXISTS "CauHinhToChuc" ADD COLUMN IF NOT EXISTS "MaToaNhaMacDinh" INT NULL;
ALTER TABLE IF EXISTS "CauHinhToChuc" ADD COLUMN IF NOT EXISTS "NguoiCapNhat" INT NULL;

ALTER TABLE IF EXISTS "TriThucAiRAG" ADD COLUMN IF NOT EXISTS "MaToaNha" INT NULL;
ALTER TABLE IF EXISTS "TriThucAiRAG" ADD COLUMN IF NOT EXISTS "NguoiCapNhat" INT NULL;

ALTER TABLE IF EXISTS "PhieuDatGiuCho" ADD COLUMN IF NOT EXISTS "MaCuDan" INT NULL;

-- 4. Seed 3 tin mặc định vào "ChoDoCuTin" & đồng bộ dữ liệu mồ côi trước khi gắn FK
INSERT INTO "ChoDoCuTin" ("MaTin", "TieuDe", "DanhMuc", "GiaBan", "GiaGoc", "KyHieuPhong", "NguoiBan", "TinhTrang", "MoTa", "HinhAnhUrl", "VideoUrl", "TrangThai", "SoSaoTrungBinh", "SoLuotDanhGia")
VALUES
    ('MKT-001', 'Quạt đứng Senko 3 tốc độ gió có hẹn giờ', 'electronics', 120000, 350000, 'P.305', 'Hồ Ngọc Bảo (P.305)', 'Còn rất mới 95%', 'Dùng được 4 tháng, chạy êm ru, có remote điều khiển. Pass lại do phòng đã có máy lạnh.', 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=600&q=80', 'https://www.w3schools.com/html/mov_bbb.mp4', 'Đang bán', 4.9, 2),
    ('MKT-002', 'Combo 5 cuốn giáo trình Cấu trúc dữ liệu & Giải thuật', 'free', 0, 0, 'P.201', 'Nguyễn Dương Bảo (P.201)', 'TẶNG MIỄN PHÍ 0Đ', 'Mình đã học xong môn, tặng lại cho các bạn khóa dưới cần ôn thi cuối kỳ.', 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80', NULL, 'Đang bán', 5.0, 1),
    ('MKT-003', 'Ấm đun nước siêu tốc Sunhouse Inox 1.8L', 'electronics', 70000, 180000, 'P.401', 'Trần Hoàng Gia Bảo (P.401)', 'Inox 304', 'Đun sôi siêu nhanh trong 3 phút, tự ngắt điện an toàn khi sôi, còn nguyên hộp.', 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80', 'https://www.w3schools.com/html/mov_bbb.mp4', 'Đang bán', 4.8, 1)
ON CONFLICT ("MaTin") DO NOTHING;

-- Tự động nâng cấp link mẫu cũ (flower.mp4 không có âm thanh hoặc demo://) sang video MP4 có âm thanh thực tế
UPDATE "ChoDoCuTin"
SET "VideoUrl" = 'https://www.w3schools.com/html/mov_bbb.mp4'
WHERE "VideoUrl" LIKE '%flower.mp4%' OR "VideoUrl" LIKE 'demo://%';

-- Đảm bảo mọi MaTin đang có trong ChoDoCuDanhGia đều tồn tại trong ChoDoCuTin trước khi tạo FK
INSERT INTO "ChoDoCuTin" ("MaTin", "TieuDe", "DanhMuc", "GiaBan", "GiaGoc", "KyHieuPhong", "NguoiBan", "TinhTrang", "MoTa")
SELECT DISTINCT d."MaTin", 'Sản phẩm Chợ Cư Dân (' || d."MaTin" || ')', 'electronics', 50000, 100000, d."KyHieuPhong", 'Cư dân SmartStay', 'Đã xác minh', 'Đồng bộ tự động từ đánh giá cư dân'
FROM "ChoDoCuDanhGia" d
WHERE NOT EXISTS (SELECT 1 FROM "ChoDoCuTin" t WHERE t."MaTin" = d."MaTin");

-- Tự động map MaPhong và MaCuDan cho các bản ghi hiện có dựa trên KyHieuPhong
UPDATE "ChoDoCuTin" t
SET "MaPhong" = COALESCE(
    (SELECT p."MaPhong" FROM "Phong" p WHERE UPPER(p."KyHieuPhong") = UPPER(t."KyHieuPhong") LIMIT 1),
    (SELECT p."MaPhong" FROM "Phong" p ORDER BY p."MaPhong" LIMIT 1)
),
"MaCuDanBan" = COALESCE("MaCuDanBan", (SELECT c."MaCuDan" FROM "CuDan" c ORDER BY c."MaCuDan" LIMIT 1))
WHERE t."MaPhong" IS NULL;

UPDATE "ChoDoCuDanhGia" d
SET "MaPhong" = COALESCE(
    (SELECT p."MaPhong" FROM "Phong" p WHERE UPPER(p."KyHieuPhong") = UPPER(d."KyHieuPhong") LIMIT 1),
    (SELECT p."MaPhong" FROM "Phong" p ORDER BY p."MaPhong" LIMIT 1)
),
"MaCuDan" = COALESCE("MaCuDan", (SELECT c."MaCuDan" FROM "CuDan" c ORDER BY c."MaCuDan" LIMIT 1))
WHERE d."MaPhong" IS NULL;

UPDATE "VeKhachVangLai" v
SET "MaPhong" = COALESCE(
    (SELECT p."MaPhong" FROM "Phong" p WHERE UPPER(p."KyHieuPhong") = UPPER(v."KyHieuPhong") LIMIT 1),
    (SELECT p."MaPhong" FROM "Phong" p ORDER BY p."MaPhong" LIMIT 1)
),
"MaCuDan" = COALESCE("MaCuDan", (SELECT c."MaCuDan" FROM "CuDan" c ORDER BY c."MaCuDan" LIMIT 1))
WHERE v."MaPhong" IS NULL;

UPDATE "ChiaTienPhong" s
SET "MaPhong" = COALESCE(
    (SELECT p."MaPhong" FROM "Phong" p WHERE UPPER(p."KyHieuPhong") = UPPER(s."KyHieuPhong") LIMIT 1),
    (SELECT p."MaPhong" FROM "Phong" p ORDER BY p."MaPhong" LIMIT 1)
),
"MaHoaDon" = COALESCE("MaHoaDon", (SELECT h."MaHoaDon" FROM "HoaDon" h ORDER BY h."MaHoaDon" DESC LIMIT 1)),
"MaCuDanTao" = COALESCE("MaCuDanTao", (SELECT c."MaCuDan" FROM "CuDan" c ORDER BY c."MaCuDan" LIMIT 1))
WHERE s."MaPhong" IS NULL;

UPDATE "ChiSoTuKiemTra" m
SET "MaPhong" = COALESCE(
    (SELECT p."MaPhong" FROM "Phong" p WHERE UPPER(p."KyHieuPhong") = UPPER(m."KyHieuPhong") LIMIT 1),
    (SELECT p."MaPhong" FROM "Phong" p ORDER BY p."MaPhong" LIMIT 1)
),
"MaCuDan" = COALESCE("MaCuDan", (SELECT c."MaCuDan" FROM "CuDan" c ORDER BY c."MaCuDan" LIMIT 1)),
"MaChiSoChinhThuc" = COALESCE("MaChiSoChinhThuc", (SELECT cs."MaChiSo" FROM "ChiSoSuDung" cs ORDER BY cs."MaChiSo" DESC LIMIT 1))
WHERE m."MaPhong" IS NULL;

UPDATE "NhatKyCuocGoi" g
SET "MaNguoiGoi" = COALESCE("MaNguoiGoi", (SELECT u."MaNguoiDung" FROM "NguoiDung" u ORDER BY u."MaNguoiDung" LIMIT 1)),
    "MaNguoiNhan" = COALESCE("MaNguoiNhan", (SELECT u."MaNguoiDung" FROM "NguoiDung" u ORDER BY u."MaNguoiDung" DESC LIMIT 1)),
    "MaCuDan" = COALESCE("MaCuDan", (SELECT c."MaCuDan" FROM "CuDan" c ORDER BY c."MaCuDan" LIMIT 1)),
    "MaPhong" = COALESCE("MaPhong", (SELECT p."MaPhong" FROM "Phong" p ORDER BY p."MaPhong" LIMIT 1))
WHERE g."MaPhong" IS NULL;

-- 5. Thiết lập toàn bộ Ràng buộc Khóa Ngoại (Foreign Keys) hiển thị rõ trên Supabase Schema Visualizer
DO $$
BEGIN
    -- ChoDoCuTin -> Phong, CuDan
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChoDoCuTin_Phong') THEN
        ALTER TABLE "ChoDoCuTin"
            ADD CONSTRAINT "FK_ChoDoCuTin_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChoDoCuTin_CuDanBan') THEN
        ALTER TABLE "ChoDoCuTin"
            ADD CONSTRAINT "FK_ChoDoCuTin_CuDanBan"
            FOREIGN KEY ("MaCuDanBan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChoDoCuTin_CuDanGiuCho') THEN
        ALTER TABLE "ChoDoCuTin"
            ADD CONSTRAINT "FK_ChoDoCuTin_CuDanGiuCho"
            FOREIGN KEY ("MaCuDanGiuCho") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    -- ChoDoCuDanhGia -> ChoDoCuTin, CuDan, Phong
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChoDoCuDanhGia_ChoDoCuTin') THEN
        ALTER TABLE "ChoDoCuDanhGia"
            ADD CONSTRAINT "FK_ChoDoCuDanhGia_ChoDoCuTin"
            FOREIGN KEY ("MaTin") REFERENCES "ChoDoCuTin"("MaTin") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChoDoCuDanhGia_CuDan') THEN
        ALTER TABLE "ChoDoCuDanhGia"
            ADD CONSTRAINT "FK_ChoDoCuDanhGia_CuDan"
            FOREIGN KEY ("MaCuDan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChoDoCuDanhGia_Phong') THEN
        ALTER TABLE "ChoDoCuDanhGia"
            ADD CONSTRAINT "FK_ChoDoCuDanhGia_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE SET NULL;
    END IF;

    -- VeKhachVangLai -> Phong, CuDan
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_VeKhachVangLai_Phong') THEN
        ALTER TABLE "VeKhachVangLai"
            ADD CONSTRAINT "FK_VeKhachVangLai_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_VeKhachVangLai_CuDan') THEN
        ALTER TABLE "VeKhachVangLai"
            ADD CONSTRAINT "FK_VeKhachVangLai_CuDan"
            FOREIGN KEY ("MaCuDan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    -- ChiaTienPhong -> Phong, HoaDon, CuDan
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChiaTienPhong_Phong') THEN
        ALTER TABLE "ChiaTienPhong"
            ADD CONSTRAINT "FK_ChiaTienPhong_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChiaTienPhong_HoaDon') THEN
        ALTER TABLE "ChiaTienPhong"
            ADD CONSTRAINT "FK_ChiaTienPhong_HoaDon"
            FOREIGN KEY ("MaHoaDon") REFERENCES "HoaDon"("MaHoaDon") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChiaTienPhong_CuDan') THEN
        ALTER TABLE "ChiaTienPhong"
            ADD CONSTRAINT "FK_ChiaTienPhong_CuDan"
            FOREIGN KEY ("MaCuDanTao") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    -- ChiSoTuKiemTra -> Phong, CuDan, ChiSoSuDung
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChiSoTuKiemTra_Phong') THEN
        ALTER TABLE "ChiSoTuKiemTra"
            ADD CONSTRAINT "FK_ChiSoTuKiemTra_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChiSoTuKiemTra_CuDan') THEN
        ALTER TABLE "ChiSoTuKiemTra"
            ADD CONSTRAINT "FK_ChiSoTuKiemTra_CuDan"
            FOREIGN KEY ("MaCuDan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ChiSoTuKiemTra_ChiSoSuDung') THEN
        ALTER TABLE "ChiSoTuKiemTra"
            ADD CONSTRAINT "FK_ChiSoTuKiemTra_ChiSoSuDung"
            FOREIGN KEY ("MaChiSoChinhThuc") REFERENCES "ChiSoSuDung"("MaChiSo") ON DELETE SET NULL;
    END IF;

    -- NhatKyCuocGoi -> NguoiDung, CuDan, Phong
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_NhatKyCuocGoi_NguoiGoi') THEN
        ALTER TABLE "NhatKyCuocGoi"
            ADD CONSTRAINT "FK_NhatKyCuocGoi_NguoiGoi"
            FOREIGN KEY ("MaNguoiGoi") REFERENCES "NguoiDung"("MaNguoiDung") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_NhatKyCuocGoi_NguoiNhan') THEN
        ALTER TABLE "NhatKyCuocGoi"
            ADD CONSTRAINT "FK_NhatKyCuocGoi_NguoiNhan"
            FOREIGN KEY ("MaNguoiNhan") REFERENCES "NguoiDung"("MaNguoiDung") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_NhatKyCuocGoi_CuDan') THEN
        ALTER TABLE "NhatKyCuocGoi"
            ADD CONSTRAINT "FK_NhatKyCuocGoi_CuDan"
            FOREIGN KEY ("MaCuDan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_NhatKyCuocGoi_Phong') THEN
        ALTER TABLE "NhatKyCuocGoi"
            ADD CONSTRAINT "FK_NhatKyCuocGoi_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE SET NULL;
    END IF;

    -- CauHinhToChuc -> ToaNha, NguoiDung
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_CauHinhToChuc_ToaNha') THEN
        ALTER TABLE "CauHinhToChuc"
            ADD CONSTRAINT "FK_CauHinhToChuc_ToaNha"
            FOREIGN KEY ("MaToaNhaMacDinh") REFERENCES "ToaNha"("MaToaNha") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_CauHinhToChuc_NguoiDung') THEN
        ALTER TABLE "CauHinhToChuc"
            ADD CONSTRAINT "FK_CauHinhToChuc_NguoiDung"
            FOREIGN KEY ("NguoiCapNhat") REFERENCES "NguoiDung"("MaNguoiDung") ON DELETE SET NULL;
    END IF;

    -- TriThucAiRAG -> ToaNha, NguoiDung
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_TriThucAiRAG_ToaNha') THEN
        ALTER TABLE "TriThucAiRAG"
            ADD CONSTRAINT "FK_TriThucAiRAG_ToaNha"
            FOREIGN KEY ("MaToaNha") REFERENCES "ToaNha"("MaToaNha") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_TriThucAiRAG_NguoiDung') THEN
        ALTER TABLE "TriThucAiRAG"
            ADD CONSTRAINT "FK_TriThucAiRAG_NguoiDung"
            FOREIGN KEY ("NguoiCapNhat") REFERENCES "NguoiDung"("MaNguoiDung") ON DELETE SET NULL;
    END IF;

    -- LichSuGiaoDichVi -> HoaDon
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_LSVi_HoaDon') THEN
        ALTER TABLE "LichSuGiaoDichVi"
            ADD CONSTRAINT "FK_LSVi_HoaDon"
            FOREIGN KEY ("MaHoaDonLienQuan") REFERENCES "HoaDon"("MaHoaDon") ON DELETE SET NULL;
    END IF;

    -- PhieuDatGiuCho -> CuDan
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_DatCho_CuDan') THEN
        ALTER TABLE "PhieuDatGiuCho"
            ADD CONSTRAINT "FK_DatCho_CuDan"
            FOREIGN KEY ("MaCuDan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;
END $$;

-- 6. Cấp quyền truy cập PostgREST & RLS cho các bảng mở rộng
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
    "ChoDoCuTin", "ChoDoCuDanhGia", "VeKhachVangLai",
    "ChiaTienPhong", "ChiSoTuKiemTra", "NhatKyCuocGoi"
TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['ChoDoCuTin', 'ChoDoCuDanhGia', 'VeKhachVangLai', 'ChiaTienPhong', 'ChiSoTuKiemTra', 'NhatKyCuocGoi']
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
        EXECUTE format('DROP POLICY IF EXISTS "AllowAll_%s" ON %I;', tbl, tbl);
        EXECUTE format('CREATE POLICY "AllowAll_%s" ON %I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);', tbl, tbl);
    END LOOP;
END $$;
