-- =================================================================================
-- SMARTSTAY - BẢNG LƯU TRỮ BỀN VỮNG & SUPABASE STORAGE BUCKET (CHỐNG MẤT DỮ LIỆU F5)
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

-- 2. Chợ Đồ Cũ Sinh Viên (Tin đăng + Giữ chỗ/Đặt mua + Đánh giá bình luận)
CREATE TABLE IF NOT EXISTS "ChoDoCuTin" (
    "MaTin" VARCHAR(64) PRIMARY KEY,
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
    "NguoiDanhGia" TEXT NOT NULL,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "SoSao" INT NOT NULL DEFAULT 5,
    "BinhLuan" TEXT NOT NULL,
    "ThoiGian" VARCHAR(64) NOT NULL DEFAULT 'Vừa xong',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Vé Khách Vãng Lai (IoT)
CREATE TABLE IF NOT EXISTS "VeKhachVangLai" (
    "MaVe" VARCHAR(64) PRIMARY KEY,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "TenKhach" TEXT NOT NULL,
    "SoDienThoai" VARCHAR(32) NULL,
    "MaPin" VARCHAR(16) NOT NULL,
    "HieuLucDen" TEXT NOT NULL,
    "TrangThai" VARCHAR(40) NOT NULL DEFAULT 'Đang hiệu lực',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Chia Tiền Phòng Ở Ghép
CREATE TABLE IF NOT EXISTS "ChiaTienPhong" (
    "MaChia" VARCHAR(64) PRIMARY KEY,
    "KyHieuPhong" VARCHAR(32) NOT NULL DEFAULT 'P.305',
    "TieuDe" TEXT NOT NULL,
    "TongTien" NUMERIC(18, 2) NOT NULL DEFAULT 0,
    "SoThanhVien" INT NOT NULL DEFAULT 3,
    "MoiNguoi" NUMERIC(18, 2) NOT NULL DEFAULT 0,
    "TrangThai" VARCHAR(40) NOT NULL DEFAULT 'Chờ đóng',
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Sổ Tự Kiểm Tra Chỉ Số Điện/Nước OCR
CREATE TABLE IF NOT EXISTS "ChiSoTuKiemTra" (
    "Id" SERIAL PRIMARY KEY,
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
    "TaoLuc" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Nhật Ký Cuộc Gọi WebRTC
CREATE TABLE IF NOT EXISTS "NhatKyCuocGoi" (
    "MaCuocGoi" VARCHAR(64) PRIMARY KEY,
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

-- 7. Cấp quyền truy cập PostgREST & RLS cho các bảng mới
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
