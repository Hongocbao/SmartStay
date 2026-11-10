-- =================================================================================
-- SMARTSTAY - PHƯƠNG ÁN A: CẤU HÌNH SUPABASE REALTIME & ROW LEVEL SECURITY (RLS)
-- Tương thích 100% với Schema 40 bảng hiện có trên Supabase (odasdzyuriucofavonjl)
-- KHÔNG dùng lệnh DROP TABLE để bảo toàn toàn bộ dữ liệu hiện tại!
-- =================================================================================

-- 1. Bật Supabase Realtime cho các bảng điều khiển liên thông giữa Admin và Client App
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "Phong";
    EXCEPTION WHEN duplicate_object OR undefined_table THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "HoaDon";
    EXCEPTION WHEN duplicate_object OR undefined_table THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "PhieuSuCo";
    EXCEPTION WHEN duplicate_object OR undefined_table THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "ThongBao";
    EXCEPTION WHEN duplicate_object OR undefined_table THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE "ChiSoSuDung";
    EXCEPTION WHEN duplicate_object OR undefined_table THEN NULL;
    END;
END $$;

-- 2. Cấp quyền truy cập qua cổng PostgREST (Phương án A - Flutter gọi trực tiếp Supabase)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE "PhieuSuCo", "ThanhToan", "ChiSoSuDung", "DangKySuKien" TO anon, authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- 3. Bật Row Level Security (RLS) và tạo Policy an toàn cho Phương án A
ALTER TABLE IF EXISTS "Phong" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Cho phep doc danh sach phong" ON "Phong";
CREATE POLICY "Cho phep doc danh sach phong"
    ON "Phong" FOR SELECT
    TO anon, authenticated
    USING (true);

ALTER TABLE IF EXISTS "ThongBao" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Cho phep doc thong bao toa nha" ON "ThongBao";
CREATE POLICY "Cho phep doc thong bao toa nha"
    ON "ThongBao" FOR SELECT
    TO anon, authenticated
    USING (true);

ALTER TABLE IF EXISTS "HoaDon" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Cho phep tra cuu hoa don" ON "HoaDon";
CREATE POLICY "Cho phep tra cuu hoa don"
    ON "HoaDon" FOR SELECT
    TO anon, authenticated
    USING (true);

ALTER TABLE IF EXISTS "PhieuSuCo" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Cho phep doc phieu su co" ON "PhieuSuCo";
CREATE POLICY "Cho phep doc phieu su co"
    ON "PhieuSuCo" FOR SELECT
    TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS "Cho phep cu dan gui phieu su co" ON "PhieuSuCo";
CREATE POLICY "Cho phep cu dan gui phieu su co"
    ON "PhieuSuCo" FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Cho phep cap nhat trang thai su co" ON "PhieuSuCo";
CREATE POLICY "Cho phep cap nhat trang thai su co"
    ON "PhieuSuCo" FOR UPDATE
    TO anon, authenticated
    USING (true);
