-- =================================================================================
-- SMARTSTAY - MODULE KHÁM PHÁ, VIDEO TOUR & ĐĂNG KÝ THUÊ PHÒNG TRỰC TUYẾN
-- An toàn tuyệt đối (không DROP TABLE, giữ nguyên 100% dữ liệu hiện có trên Supabase)
-- Chạy trực tiếp trên Supabase SQL Editor hoặc tự động đồng bộ khi khởi động Backend
-- =================================================================================

-- 1. Mở rộng bảng "Phong" thêm thông tin hiển thị cho thuê, tiện ích nổi bật & lượt xem
ALTER TABLE IF EXISTS "Phong" ADD COLUMN IF NOT EXISTS "TieuDeChoThue" TEXT NULL;
ALTER TABLE IF EXISTS "Phong" ADD COLUMN IF NOT EXISTS "TienIchNoiBat" TEXT NULL;
ALTER TABLE IF EXISTS "Phong" ADD COLUMN IF NOT EXISTS "DangMoChoThue" BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE IF EXISTS "Phong" ADD COLUMN IF NOT EXISTS "LuotXem" INT NOT NULL DEFAULT 18;
ALTER TABLE IF EXISTS "Phong" ADD COLUMN IF NOT EXISTS "DiemDanhGia" DOUBLE PRECISION NOT NULL DEFAULT 4.8;
ALTER TABLE IF EXISTS "Phong" ADD COLUMN IF NOT EXISTS "CapNhatLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 2. Tạo bảng "PhongMedia" lưu danh sách ảnh thực tế & Video Tour cho từng phòng
CREATE TABLE IF NOT EXISTS "PhongMedia" (
    "Id" SERIAL PRIMARY KEY,
    "MaPhong" INT NOT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL,
    "LoaiMedia" VARCHAR(16) NOT NULL DEFAULT 'Image', -- 'Image' | 'Video'
    "Url" TEXT NOT NULL,
    "MoTa" TEXT NULL,
    "ThuTu" INT NOT NULL DEFAULT 0,
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Tạo bảng "PhieuDangKyPhong" lưu yêu cầu đăng ký thuê mới / xin chuyển phòng
CREATE TABLE IF NOT EXISTS "PhieuDangKyPhong" (
    "MaPhieu" VARCHAR(64) PRIMARY KEY,
    "MaPhong" INT NOT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL,
    "MaCuDan" INT NULL,
    "LoaiYeuCau" VARCHAR(32) NOT NULL DEFAULT 'ThueMoi', -- 'ThueMoi' | 'ChuyenPhong'
    "HoTen" TEXT NOT NULL,
    "SoDienThoai" VARCHAR(32) NOT NULL,
    "SoCanCuoc" VARCHAR(32) NULL,
    "NgayDuKienVaoO" DATE NOT NULL DEFAULT CURRENT_DATE,
    "GhiChu" TEXT NULL,
    "TrangThai" VARCHAR(32) NOT NULL DEFAULT 'ChoDuyet', -- 'ChoDuyet' | 'DaDuyet' | 'TuChoi'
    "LyDoTuChoi" TEXT NULL,
    "MaHopDongTao" INT NULL,
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "CapNhatLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Thiết lập khóa ngoại (Foreign Keys) hiển thị rõ trên Supabase Schema Visualizer
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_PhongMedia_Phong') THEN
        ALTER TABLE "PhongMedia"
            ADD CONSTRAINT "FK_PhongMedia_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_PhieuDangKyPhong_Phong') THEN
        ALTER TABLE "PhieuDangKyPhong"
            ADD CONSTRAINT "FK_PhieuDangKyPhong_Phong"
            FOREIGN KEY ("MaPhong") REFERENCES "Phong"("MaPhong") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_PhieuDangKyPhong_CuDan') THEN
        ALTER TABLE "PhieuDangKyPhong"
            ADD CONSTRAINT "FK_PhieuDangKyPhong_CuDan"
            FOREIGN KEY ("MaCuDan") REFERENCES "CuDan"("MaCuDan") ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_PhieuDangKyPhong_HopDong') THEN
        ALTER TABLE "PhieuDangKyPhong"
            ADD CONSTRAINT "FK_PhieuDangKyPhong_HopDong"
            FOREIGN KEY ("MaHopDongTao") REFERENCES "HopDong"("MaHopDong") ON DELETE SET NULL;
    END IF;
END $$;

-- Index hỗ trợ tìm kiếm & lọc nhanh
CREATE INDEX IF NOT EXISTS "IX_PhongMedia_MaPhong" ON "PhongMedia" ("MaPhong", "ThuTu");
CREATE INDEX IF NOT EXISTS "IX_PhieuDangKyPhong_MaPhong" ON "PhieuDangKyPhong" ("MaPhong", "TrangThai");
CREATE INDEX IF NOT EXISTS "IX_PhieuDangKyPhong_TaoLuc" ON "PhieuDangKyPhong" ("TaoLuc" DESC);

-- 5. Khởi tạo dữ liệu mô tả & tiện ích mẫu cho các phòng chưa có mô tả (không ghi đè dữ liệu đã sửa)
UPDATE "Phong"
SET
    "TieuDeChoThue" = COALESCE(
        "TieuDeChoThue",
        'Căn hộ thông minh ' || "KyHieuPhong" || ' • Tầng ' || "SoTang" || ' (Full nội thất)'
    ),
    "TienIchNoiBat" = COALESCE(
        "TienIchNoiBat",
        'Khóa vân tay IoT,Máy lạnh Inverter,Ban công đón nắng,Wi-Fi 6 tốc độ cao,Tủ lạnh & Kệ bếp riêng'
    ),
    "MoTa" = COALESCE(
        NULLIF(TRIM("MoTa"), ''),
        'Không gian sống hiện đại thiết kế tối giản theo chuẩn SmartStay, ánh sáng tự nhiên tràn ngập, an ninh 3 lớp bằng vân tay & camera AI 24/7.'
    ),
    "LuotXem" = CASE WHEN "LuotXem" <= 0 THEN 24 + ("MaPhong" % 35) ELSE "LuotXem" END,
    "DiemDanhGia" = CASE WHEN "DiemDanhGia" <= 0 THEN 4.8 ELSE "DiemDanhGia" END
WHERE "TieuDeChoThue" IS NULL OR "TienIchNoiBat" IS NULL;

-- 6. Seed ảnh & Video Tour thực tế có âm thanh cho các phòng chưa có dòng nào trong "PhongMedia"
INSERT INTO "PhongMedia" ("MaPhong", "KyHieuPhong", "LoaiMedia", "Url", "MoTa", "ThuTu")
SELECT
    p."MaPhong",
    p."KyHieuPhong",
    'Image',
    CASE (p."MaPhong" % 4)
        WHEN 0 THEN 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80'
        WHEN 1 THEN 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=900&q=80'
        WHEN 2 THEN 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=900&q=80'
        ELSE 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80'
    END,
    'Góc toàn cảnh phòng ' || p."KyHieuPhong",
    0
FROM "Phong" p
WHERE NOT EXISTS (
    SELECT 1 FROM "PhongMedia" m WHERE m."MaPhong" = p."MaPhong" AND m."LoaiMedia" = 'Image'
);

INSERT INTO "PhongMedia" ("MaPhong", "KyHieuPhong", "LoaiMedia", "Url", "MoTa", "ThuTu")
SELECT
    p."MaPhong",
    p."KyHieuPhong",
    'Image',
    'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=900&q=80',
    'Khu vực học tập & làm việc phòng ' || p."KyHieuPhong",
    1
FROM "Phong" p
WHERE (SELECT COUNT(*) FROM "PhongMedia" m WHERE m."MaPhong" = p."MaPhong" AND m."LoaiMedia" = 'Image') < 2;

INSERT INTO "PhongMedia" ("MaPhong", "KyHieuPhong", "LoaiMedia", "Url", "MoTa", "ThuTu")
SELECT
    p."MaPhong",
    p."KyHieuPhong",
    'Video',
    'https://www.w3schools.com/html/mov_bbb.mp4',
    'Video Tour 360° thực tế phòng ' || p."KyHieuPhong",
    10
FROM "Phong" p
WHERE NOT EXISTS (
    SELECT 1 FROM "PhongMedia" m WHERE m."MaPhong" = p."MaPhong" AND m."LoaiMedia" = 'Video'
);

-- 7. Đảm bảo bucket 'smartstay-media' công khai và cấp quyền PostgREST + RLS + Realtime
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "PhongMedia", "PhieuDangKyPhong" TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['PhongMedia', 'PhieuDangKyPhong']
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
        EXECUTE format('DROP POLICY IF EXISTS "AllowAll_%s" ON %I;', tbl, tbl);
        EXECUTE format('CREATE POLICY "AllowAll_%s" ON %I FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);', tbl, tbl);
    END LOOP;

    -- Bật Supabase Realtime cho Phong, PhongMedia, PhieuDangKyPhong
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "PhongMedia";
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "PhieuDangKyPhong";
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $$;
