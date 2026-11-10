-- =========================================================================================
-- SMARTSTAY ENTERPRISE EXTENSION - SUPABASE POSTGRESQL
-- Đã tích hợp sẵn toàn bộ bảng Enterprise & View vào schema_postgresql_supabase.sql
-- File này dùng để chạy bổ sung độc lập (Idempotent) trên Supabase SQL Editor nếu cần.
-- =========================================================================================

CREATE INDEX IF NOT EXISTS "IX_Phong_TrangThai" ON "Phong"("TrangThai", "SoTang");
CREATE INDEX IF NOT EXISTS "IX_HoaDon_TrangThai_KyTinhTien" ON "HoaDon"("TrangThai", "KyTinhTien");
CREATE INDEX IF NOT EXISTS "IX_PhieuSuCo_TrangThai_UuTien" ON "PhieuSuCo"("TrangThai", "UuTien");
CREATE INDEX IF NOT EXISTS "IX_ThanhToan_TrangThai" ON "ThanhToan"("TrangThai");
