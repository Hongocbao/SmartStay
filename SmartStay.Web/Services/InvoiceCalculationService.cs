using SmartStay.Web.Dtos;
using SmartStay.Web.Models;

namespace SmartStay.Web.Services;

public interface IInvoiceCalculationService
{
    KetQuaTinhBacThangDto TinhHoaDonBacThang(
        decimal sanLuongDien,
        decimal sanLuongNuoc,
        decimal tienPhong,
        decimal tienDichVuCoDinh,
        List<BacGium> bacGiaDien,
        List<BacGium> bacGiaNuoc,
        string kyHieuPhong,
        string tenCuDan,
        CauHinhToChuc? cauHinh);
}

public class InvoiceCalculationService : IInvoiceCalculationService
{
    public KetQuaTinhBacThangDto TinhHoaDonBacThang(
        decimal sanLuongDien,
        decimal sanLuongNuoc,
        decimal tienPhong,
        decimal tienDichVuCoDinh,
        List<BacGium> bacGiaDien,
        List<BacGium> bacGiaNuoc,
        string kyHieuPhong,
        string tenCuDan,
        CauHinhToChuc? cauHinh)
    {
        var ketQua = new KetQuaTinhBacThangDto
        {
            SanLuongDien = sanLuongDien,
            SanLuongNuoc = sanLuongNuoc,
            TienPhong = tienPhong,
            TienDichVu = tienDichVuCoDinh
        };

        // 1. Tính bậc thang Điện
        var (tienDien, chiTietDien) = TinhTheoBac("Điện", sanLuongDien, bacGiaDien, "kWh");
        ketQua.TienDien = tienDien;
        ketQua.ChiTietBacThang.AddRange(chiTietDien);

        // 2. Tính bậc thang Nước
        var (tienNuoc, chiTietNuoc) = TinhTheoBac("Nước", sanLuongNuoc, bacGiaNuoc, "m³");
        ketQua.TienNuoc = tienNuoc;
        ketQua.ChiTietBacThang.AddRange(chiTietNuoc);

        // 3. Tổng tiền
        ketQua.TongTien = ketQua.TienPhong + ketQua.TienDien + ketQua.TienNuoc + ketQua.TienDichVu;

        // 4. Sinh URL VietQR Động
        var bin = cauHinh?.MaNganHang ?? "970422";
        var stk = cauHinh?.SoTaiKhoanNganHang ?? "0987654321";
        var chuTk = Uri.EscapeDataString(cauHinh?.TenChuTaiKhoan ?? "SMARTSTAY MANAGEMENT");
        var noiDungQr = Uri.EscapeDataString($"HD {kyHieuPhong} {tenCuDan}".Replace(" ", "%20"));
        var amount = (long)Math.Round(ketQua.TongTien);

        ketQua.UrlVietQr = $"https://img.vietqr.io/image/{bin}-{stk}-compact2.png?amount={amount}&addInfo={noiDungQr}&accountName={chuTk}";

        return ketQua;
    }

    private static (decimal tongTien, List<ChiTietBacThangItemDto> items) TinhTheoBac(
        string tenDichVu,
        decimal tongSanLuong,
        List<BacGium> danhSachBac,
        string donVi)
    {
        decimal tongTien = 0;
        var items = new List<ChiTietBacThangItemDto>();
        decimal sanLuongConLai = Math.Max(0, tongSanLuong);

        var bacSapXep = danhSachBac.OrderBy(b => b.ThuTuBac).ToList();
        decimal mucTieuThuDaLap = 0;

        foreach (var bac in bacSapXep)
        {
            if (sanLuongConLai <= 0) break;

            // SoLuongDen là ngưỡng lũy kế (ví dụ 50, 100, 200), không phải số lượng
            // điểm rời rạc. Bậc 1 vì vậy chứa 50 đơn vị, bậc 2 chứa thêm 50 đơn vị.
            decimal gioiHanBac = bac.SoLuongDen.HasValue
                ? Math.Max(0, bac.SoLuongDen.Value - mucTieuThuDaLap)
                : decimal.MaxValue;
            decimal soLuongTrongBac = Math.Min(sanLuongConLai, gioiHanBac);

            decimal thanhTien = soLuongTrongBac * bac.DonGia;
            tongTien += thanhTien;
            sanLuongConLai -= soLuongTrongBac;
            if (bac.SoLuongDen.HasValue)
            {
                mucTieuThuDaLap = Math.Max(mucTieuThuDaLap, bac.SoLuongDen.Value);
            }

            string moTa = bac.SoLuongDen.HasValue
                ? $"{tenDichVu} Bậc {bac.ThuTuBac} ({bac.SoLuongTu} - {bac.SoLuongDen.Value} {donVi})"
                : $"{tenDichVu} Bậc {bac.ThuTuBac} (Trên {bac.SoLuongTu} {donVi})";

            items.Add(new ChiTietBacThangItemDto
            {
                TenDichVu = tenDichVu,
                ThuTuBac = bac.ThuTuBac,
                MoTaBac = moTa,
                SoLuong = soLuongTrongBac,
                DonGia = bac.DonGia,
                ThanhTien = thanhTien
            });
        }

        return (tongTien, items);
    }
}
