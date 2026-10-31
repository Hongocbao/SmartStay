import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

DOC_PATH = r"e:\DAN_ChuyenNganh\BaoCaoTuan3_SmartStay.docx"
SCREENSHOT_DIR = r"e:\DAN_ChuyenNganh\docs\screenshots"

doc = Document()

# Set standard margins (2cm = 0.79 inch)
for section in doc.sections:
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(0.9)
    section.right_margin = Inches(0.9)

# Style helpers
def set_font(run, name="Times New Roman", size=13, bold=False, italic=False, color=None):
    run.font.name = name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    if color:
        run.font.color.rgb = color

def add_heading_1(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    set_font(run, size=15, bold=True, color=RGBColor(30, 58, 138)) # Navy blue

def add_heading_2(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    set_font(run, size=13.5, bold=True, color=RGBColor(37, 99, 235))

def add_heading_3(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    set_font(run, size=13, bold=True, color=RGBColor(15, 23, 42))

def add_body_p(text, bold_prefix=None, space_after=6):
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing = 1.3
    p.paragraph_format.space_after = Pt(space_after)
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        set_font(r_pre, size=13, bold=True)
    r = p.add_run(text)
    set_font(r, size=13)
    return p

def add_bullet_p(bold_prefix, text):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.line_spacing = 1.25
    p.paragraph_format.space_after = Pt(4)
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        set_font(r_pre, size=13, bold=True)
    r = p.add_run(text)
    set_font(r, size=13)

def add_figure_caption(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(12)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(text)
    set_font(run, size=11, bold=True, italic=True, color=RGBColor(71, 85, 105))

def add_image_centered(img_path, width_inches=4.2):
    if os.path.exists(img_path):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(4)
        run = p.add_run()
        run.add_picture(img_path, width=Inches(width_inches))

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

print("Building BaoCaoTuan3_SmartStay.docx...")

# ----------------- COVER & TITLE -----------------
title_p = doc.add_paragraph()
title_p.paragraph_format.space_before = Pt(20)
title_p.paragraph_format.space_after = Pt(4)
title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run_title = title_p.add_run("BÁO CÁO TIẾN ĐỘ ĐỒ ÁN CHUYÊN NGÀNH (TUẦN 3)")
set_font(run_title, size=18, bold=True, color=RGBColor(30, 58, 138))

sub_p = doc.add_paragraph()
sub_p.paragraph_format.space_after = Pt(16)
sub_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run_sub = sub_p.add_run("Tên đề tài: SmartStay – Hệ thống quản trị hệ sinh thái lưu trú thông minh đa nền tảng")
set_font(run_sub, size=14, bold=True, italic=True, color=RGBColor(37, 99, 235))

# ----------------- ASSIGNMENT TABLE -----------------
add_heading_2("BẢNG PHÂN CÔNG NHIỆM VỤ THỰC HIỆN DỰ ÁN (TUẦN 3)")

table = doc.add_table(rows=4, cols=4)
table.alignment = WD_TABLE_ALIGNMENT.CENTER
table.autofit = False

headers = ["STT", "Họ và Tên", "MSSV", "Nhiệm vụ thực hiện & Kết quả nghiệm thu"]
for i, h in enumerate(headers):
    cell = table.cell(0, i)
    cell.paragraphs[0].text = h
    cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_font(cell.paragraphs[0].runs[0], size=11.5, bold=True, color=RGBColor(255, 255, 255))
    set_cell_background(cell, "1E3A8A")

data = [
    ("1", "Hồ Ngọc Bảo", "2380600133", "Trưởng nhóm: Kiến trúc hệ thống All-in-One trên Android Studio, lập trình phân hệ Quản lý (Dashboard, Room Matrix, Kanban, IoT Lock) & phân hệ Cư dân (VietQR, Báo hỏng, AI Gemini)."),
    ("2", "Nguyễn Dương Bảo", "2380600154", "Nâng cấp Cơ sở dữ liệu SQL Server 46 bảng Enterprise (Stored Procedure tính điện nước bậc thang, Trigger Kanban), xây dựng API Backend .NET 8."),
    ("3", "Trần Hoàng Gia Bảo", "2380600178", "Thiết kế giao diện UI/UX Flutter Material 3, kiểm thử chức năng (Use Case UC01-UC35), đo kiểm hiệu năng và biên soạn tài liệu báo cáo."),
]

for row_idx, (stt, name, mssv, task) in enumerate(data, start=1):
    table.cell(row_idx, 0).paragraphs[0].text = stt
    table.cell(row_idx, 0).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    table.cell(row_idx, 1).paragraphs[0].text = name
    table.cell(row_idx, 2).paragraphs[0].text = mssv
    table.cell(row_idx, 2).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    table.cell(row_idx, 3).paragraphs[0].text = task
    
    bg_color = "F8FAFC" if row_idx % 2 == 1 else "FFFFFF"
    for col_idx in range(4):
        c = table.cell(row_idx, col_idx)
        set_cell_background(c, bg_color)
        set_font(c.paragraphs[0].runs[0], size=11)

p_space = doc.add_paragraph()
p_space.paragraph_format.space_after = Pt(10)

# ----------------- CHƯƠNG 1 -----------------
add_heading_1("1. Tổng Quan Kiến Trúc Hợp Nhất Hệ Sinh Thái SmartStay Trên Android Studio")
add_body_p(
    "Trong giai đoạn Tuần 3, nhóm nghiên cứu đã hiện thực hóa trọn vẹn toàn bộ các ca sử dụng (Use Case) từ giai đoạn thiết kế sang môi trường mã nguồn thực tế. Nhằm tối ưu hóa trải nghiệm phát triển, kiểm thử và chuyển giao đồ án, nhóm đã thống nhất hợp nhất toàn bộ các phân hệ của hệ sinh thái lưu trú SmartStay vào DUY NHẤT một dự án Flutter đa nền tảng, có thể mở, biên dịch và chạy trực tiếp trên Android Studio."
)
add_body_p(
    "Cơ chế chuyển đổi vai trò tức thì (Multi-Role Switcher): Hệ thống tích hợp một huy hiệu điều hướng thông minh cho phép người kiểm thử, giảng viên hướng dẫn hoặc hội đồng bảo vệ có thể luân chuyển ngay lập tức giữa 3 không gian làm việc độc lập:",
    bold_prefix="• "
)
add_bullet_p("Phân hệ Cư dân (Resident Portal): ", "Dành cho người thuê phòng (Hồ Ngọc Bảo - P.305), hỗ trợ tra cứu hợp đồng điện tử, quản lý danh mục tài sản bàn giao, theo dõi hóa đơn bậc thang, thanh toán mã động VietQR NAPAS 247, báo sự cố kỹ thuật 3 bước và tương tác với Trợ lý ảo AI Gemini 24/7.")
add_bullet_p("Phân hệ Ban Quản lý (Admin Portal): ", "Dành cho Quản lý vận hành (Nguyễn Hoàng Nam), tích hợp Bàn điều hành KPI giám sát tỷ lệ lấp đầy %, Sơ đồ phòng trực quan 5 tầng (Room Matrix) thực hiện Check-in / Check-out, Bảng Kanban điều phối sự cố 3 cột, công cụ phát hành hóa đơn tự động và đối soát thanh toán VietQR.")
add_bullet_p("Phân hệ Kỹ thuật viên (Technician Portal): ", "Dành cho nhân viên sửa chữa (Trần Văn Tuấn), tiếp nhận các phiếu bảo trì được phân công trên Kanban, ghi nhận tiến độ thay thế vật tư và hoàn tất nghiệm thu.")

add_body_p(
    "Kiểm định chất lượng mã nguồn: Toàn bộ cấu trúc mã nguồn dự án SmartStay đã được rà soát và kiểm tra bằng công cụ phân tích tĩnh `dart analyze`. Kết quả đạt chuẩn tuyệt đối: No issues found! (0 lỗi, 0 cảnh báo), đảm bảo tính ổn định và tuân thủ nguyên lý Clean Architecture."
)

# ----------------- CHƯƠNG 2 -----------------
add_heading_1("2. Hiện Thực Hóa Cơ Sở Dữ Liệu SQL Server Enterprise (46 Bảng Vật Lý)")
add_body_p(
    "Hệ thống cơ sở dữ liệu đã được triển khai và cấu hình trực tiếp trên máy chủ Microsoft SQL Server cục bộ (Instance: MSI-Bao\\SQLEXPRESS, Database: SmartStayDB). Dựa trên nền tảng 19 bảng mẫu của Tuần 2, nhóm đã mở rộng và chuẩn hóa lên quy mô 46 bảng vật lý chuẩn doanh nghiệp, đáp ứng trọn vẹn mọi nghiệp vụ phức tạp của mô hình căn hộ Co-Living và ký túc xá thông minh."
)
add_body_p(
    "Các nhóm thực thể dữ liệu nòng cốt bao gồm:",
    bold_prefix="2.1 Phân bổ thực thể dữ liệu: "
)
add_bullet_p("Nhóm Quản lý Tòa nhà & Phòng lưu trú: ", "ToaNha, Tang, Phong, Giuong, LoaiPhong, TienNghi, HopDongThue, DanhSachTaiSanBanGiao, LichSuChuyenPhong.")
add_bullet_p("Nhóm Cư dân & Khách vãng lai: ", "NguoiDung, VaiTro, CuDan, KhachLuuTru, PhuongTienCuDan, PhieuDatGiuCho.")
add_bullet_p("Nhóm Tài chính, Hóa đơn & Đối soát VietQR: ", "HoaDon, ChiTietHoaDon, BieuGiaDien, BieuGiaNuoc, LichSuDongTien, WebhookGiaoDichNganHang, ViCuDan, LichSuGiaoDichVi, SoQuyThuChi.")
add_bullet_p("Nhóm Quản lý Sự cố & Kanban Kỹ thuật: ", "PhieuBaoSuCo, NhatKyXuLySuCo, HinhAnhSuCo, DanhGiaSuCo, VatTuLinhKien, PhieuXuatVatTuSuCo.")
add_bullet_p("Nhóm Khóa thông minh IoT & Kiểm soát Cửa: ", "ThietBiIoT, LichSuTruyCapCua, LichSuRaVaoToaNha.")
add_bullet_p("Nhóm Tiện ích Cộng đồng & Trí tuệ Nhân tạo: ", "ThongBao, SuKienCongDong, DangKySuKien, TriThucAiRAG.")

add_body_p(
    "Lập trình nghiệp vụ mức Cơ sở dữ liệu (Stored Procedures & Triggers):",
    bold_prefix="2.2 Xử lý tự động hóa trên CSDL: "
)
add_bullet_p("Thủ tục sp_PhatHanhHoaDonThangTuDong: ", "Tự động truy xuất chỉ số điện nước mới nhất của các phòng đang hoạt động, áp dụng thuật toán tính lũy tiến bậc thang theo quy định hiện hành của Bộ Công Thương (4 bậc điện: 1.800 đ - 3.200 đ/kWh, 3 bậc nước: 12.000 đ - 18.000 đ/m³), tổng hợp tiền phòng và phí cố định để phát hành hàng loạt hóa đơn gắn mã VietQR.")
add_bullet_p("Trigger trg_PhieuSuCo_GhiNhatKyKanban: ", "Tự động bắt sự kiện khi trạng thái phiếu bảo trì thay đổi (từ 'Chờ xử lý' sang 'Đang sửa' hoặc 'Hoàn thành') để ghi nhận lịch sử vào bảng NhatKyXuLySuCo phục vụ theo dõi SLA và đánh giá KPI kỹ thuật viên.")
add_bullet_p("Khung nhìn v_SoDoPhongRealTime & v_BaoCaoDoanhThuTheoToaNha: ", "Tối ưu hóa tốc độ tải dữ liệu cho Sơ đồ phòng và Dashboard chỉ trong mili-giây, giảm tải tối đa cho hệ thống Backend API.")

# ----------------- CHƯƠNG 3 -----------------
add_heading_1("3. Hiện Thực Hóa Phân Hệ Cư Dân (Resident App)")
add_body_p(
    "Phân hệ Cư dân được xây dựng với ngôn ngữ thiết kế Material 3 hiện đại, tối ưu hóa giao diện dựa trên hồ sơ cư dân Hồ Ngọc Bảo (Phòng P.305, Tòa nhà A - Co-Living SmartStay)."
)

add_heading_2("3.1 Trang chủ Cư dân & Quản lý Hợp đồng Lưu trú")
add_body_p(
    "Trang chủ cung cấp cái nhìn tổng quan về trạng thái phòng ở, tình trạng hóa đơn đến hạn, sự cố đang xử lý và danh mục các tiện ích dịch vụ nội khu. Người dùng có thể tra cứu hợp đồng điện tử HD-2026-0305 và biên bản bàn giao 5 tài sản đính kèm (Máy lạnh Inverter Daikin 1.5HP, Giường thông minh nệm cao su non, Tủ quần áo 2 buồng cánh trượt, Bàn ghế công thái học, Khóa cửa thông minh vân tay/thẻ từ)."
)
add_image_centered(os.path.join(SCREENSHOT_DIR, "screen_01_resident_home.png"))
add_figure_caption("Hình 1: Giao diện Trang chủ phân hệ Cư dân (Hồ Ngọc Bảo - Phòng P.305)")

add_heading_2("3.2 Chi Tiết Hóa Đơn Lũy Tiến Bậc Thang & Thanh Toán VietQR NAPAS 247")
add_body_p(
    "Điểm đột phá của phân hệ tài chính SmartStay là tính minh bạch tối đa. Thay vì chỉ hiển thị một con số tổng quát, hóa đơn bóc tách chi tiết từng bậc thang tiêu thụ điện và nước của phòng P.305 trong kỳ tháng 10/2026 (120 kWh điện và 8 m³ nước). Mã VietQR động chuẩn NAPAS 247 được sinh trực tiếp trên màn hình, chứa sẵn thông tin ngân hàng thụ hưởng MB Bank, số tiền chính xác 4.159.000 đ và cú pháp thanh toán 'HD 2026 10 305'. Sau khi chuyển khoản, cư dân có thể tải ảnh biên lai ngân hàng lên hệ thống để Ban Quản lý đối soát nhanh chóng."
)
add_image_centered(os.path.join(SCREENSHOT_DIR, "screen_02_invoice_vietqr.png"))
add_figure_caption("Hình 2: Bóc tách hóa đơn điện nước bậc thang & Mã thanh toán VietQR NAPAS 247")

add_heading_2("3.3 Trợ Lý Ảo AI Gemini Hỗ Trợ Cư Dân 24/7 (AI Copilot)")
add_body_p(
    "Nhằm nâng cao chất lượng dịch vụ và giảm tải công việc trực tổng đài cho Ban Quản lý, hệ thống tích hợp Trợ lý ảo AI SmartStay Copilot. Ứng dụng mô hình ngôn ngữ lớn kết hợp cơ sở tri thức cục bộ (RAG từ bảng TriThucAiRAG), trợ lý AI có khả năng giải đáp tức thì các thắc mắc về công thức tính giá điện nước bậc thang, quy trình thanh toán VietQR, nội quy khung giờ yên tĩnh và hướng dẫn xử lý sự cố thiết bị khẩn cấp."
)
add_image_centered(os.path.join(SCREENSHOT_DIR, "screen_06_ai_chat.png"))
add_figure_caption("Hình 3: Giao diện Trò chuyện cùng Trợ lý ảo AI Gemini 24/7")

# ----------------- CHƯƠNG 4 -----------------
add_heading_1("4. Hiện Thực Hóa Phân Hệ Ban Quản Lý (Admin Portal)")
add_body_p(
    "Phân hệ Quản lý vận hành được thiết kế dành cho nhà quản lý tòa nhà, tập trung vào khả năng bao quát toàn bộ tài sản, tối ưu hóa quy trình tiếp nhận khách và xử lý sự cố."
)

add_heading_2("4.1 Bàn Điều Hành Trực Quan (Executive KPI Dashboard)")
add_body_p(
    "Dashboard tổng hợp thời gian thực các chỉ số vận hành cốt lõi: Tỷ lệ lấp đầy phòng (đạt 60.0% với 12/20 phòng đang ở), Tổng doanh thu tiền phòng tháng 10 đạt 48.000.000 đ, Số lượng sự cố đang bảo trì cần xử lý, và Tổng số công nợ chưa thu. Biểu đồ thanh trạng thái trực quan phân bổ rõ rệt 4 màu sắc: Đang ở (Xanh dương), Trống (Xanh lá), Đã đặt cọc (Vàng) và Đang bảo trì (Đỏ)."
)

add_heading_2("4.2 Sơ Đồ Phòng Trực Quan Đa Tầng (Interactive Room Matrix)")
add_body_p(
    "Room Matrix số hóa toàn bộ 20 phòng căn hộ trải dài từ Tầng 1 đến Tầng 5. Người quản lý có thể lọc phòng theo tầng hoặc theo trạng thái thuê. Mỗi thẻ phòng hiển thị mã phòng, loại phòng, cư dân đang thuê, chỉ số điện nước chốt gần nhất và dung lượng pin của khóa cửa IoT. Thao tác 1 chạm cho phép mở cửa sổ nghiệp vụ: Làm thủ tục nhận phòng mới (Check-in), Ghi chỉ số công tơ, Mở khóa từ xa và Làm thủ tục trả phòng (Check-out quyết toán cọc)."
)
add_image_centered(os.path.join(SCREENSHOT_DIR, "screen_03_room_matrix.png"))
add_figure_caption("Hình 4: Sơ đồ phòng trực quan đa tầng (Room Matrix) và bộ lọc trạng thái")

add_heading_2("4.3 Bảng Kanban Quản Lý Bảo Trì & Điều Phối Kỹ Thuật Viên")
add_body_p(
    "Quy trình xử lý sự cố được trực quan hóa theo mô hình Kanban chuẩn 3 cột: 'Chờ xử lý', 'Đang sửa' và 'Hoàn thành'. Khi cư dân gửi phiếu báo hỏng thiết bị, phiếu sẽ xuất hiện ở cột 'Chờ xử lý'. Người quản lý chỉ cần nhấn 'Phân công Kỹ thuật viên' để gán việc cho nhân sự chuyên trách (KTV Trần Văn Tuấn / Lê Minh Khang), phiếu sẽ tự động di chuyển sang cột 'Đang sửa'. Sau khi sửa xong, kỹ thuật viên bấm 'Xác nhận hoàn thành' để gửi thông báo cho cư dân đánh giá chất lượng nghiệm thu."
)
add_image_centered(os.path.join(SCREENSHOT_DIR, "screen_04_kanban.png"))
add_figure_caption("Hình 5: Bảng Kanban điều phối và theo dõi tiến độ bảo trì sự cố")

# ----------------- CHƯƠNG 5 -----------------
add_heading_1("5. Phân Hệ Khóa Thông Minh IoT & Kiểm Soát Ra Vào")
add_body_p(
    "Hệ thống SmartStay kết nối với mạng lưới khóa điện tử thông minh qua cổng Gateway Zigbee 3.0 / WiFi 2.4GHz, cho phép giám sát an ninh tòa nhà theo thời gian thực."
)
add_bullet_p("Giám sát nguồn năng lượng khóa: ", "Hiển thị chính xác mức pin (%) của từng phòng, tự động gửi thông báo cảnh báo màu vàng khi dung lượng pin xuống dưới 80% để kỹ thuật viên kịp thời sạc hoặc thay pin dự phòng.")
add_bullet_p("Lệnh mở khóa từ xa (Remote Unlock): ", "Hỗ trợ Ban Quản lý mở cửa phòng trực tiếp từ ứng dụng trong các tình huống khẩn cấp hoặc khi cư dân để quên chìa khóa/thẻ từ.")
add_bullet_p("Nhật ký truy cập cửa thời gian thực: ", "Ghi nhận chi tiết lịch sử ra vào của từng phòng: Thời gian chính xác, người mở, phương thức xác thực (Vân tay sinh trắc học, Thẻ từ RFID Master, Mở từ xa qua App, Mã PIN bảo mật) và phát hiện ngay lập tức các nỗ lực truy cập bất hợp pháp.")
add_image_centered(os.path.join(SCREENSHOT_DIR, "screen_05_iot_smartlock.png"))
add_figure_caption("Hình 6: Phân hệ Giám sát Khóa cửa thông minh IoT & Nhật ký vào ra")

# ----------------- CHƯƠNG 6 -----------------
add_heading_1("6. Đánh Giá Kết Quả Kiểm Thử & Kế Hoạch Tuần Tiếp Theo")
add_heading_2("6.1 Kết Quả Kiểm Thử Ca Sử Dụng (Use Cases)")
add_body_p(
    "Nhóm đã tiến hành kiểm thử toàn diện trên thiết bị Android Emulator và môi trường Android Studio. Kết quả đạt được như sau:"
)

test_table = doc.add_table(rows=6, cols=4)
test_table.alignment = WD_TABLE_ALIGNMENT.CENTER
test_headers = ["Mã UC", "Tên Ca Sử Dụng", "Kịch Bản Kiểm Thử Thực Tế", "Kết Quả"]
for i, h in enumerate(test_headers):
    c = test_table.cell(0, i)
    c.paragraphs[0].text = h
    c.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_font(c.paragraphs[0].runs[0], size=11.5, bold=True, color=RGBColor(255, 255, 255))
    set_cell_background(c, "1E3A8A")

test_cases = [
    ("UC01", "Chuyển đổi vai trò linh hoạt", "Chuyển đổi giữa Cư dân, Quản lý và Kỹ thuật viên bằng Multi-Role Switcher.", "ĐẠT (100%)"),
    ("UC02", "Xem hóa đơn & VietQR", "Kiểm tra bóc tách bậc thang điện nước và quét mã VietQR Napas 247.", "ĐẠT (100%)"),
    ("UC03", "Báo hỏng & Kanban sự cố", "Tạo phiếu báo hỏng máy lạnh P.305, phân công KTV và cập nhật trạng thái.", "ĐẠT (100%)"),
    ("UC04", "Sơ đồ phòng & Check-in", "Lọc phòng theo tầng, mở modal nhận phòng mới và trả phòng thu cọc.", "ĐẠT (100%)"),
    ("UC05", "Khóa IoT & Trợ lý ảo AI", "Thử lệnh mở khóa từ xa và hỏi đáp Trợ lý AI Gemini về biểu giá bậc thang.", "ĐẠT (100%)"),
]

for r_idx, (uc, name, scenario, res) in enumerate(test_cases, start=1):
    test_table.cell(r_idx, 0).paragraphs[0].text = uc
    test_table.cell(r_idx, 0).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    test_table.cell(r_idx, 1).paragraphs[0].text = name
    test_table.cell(r_idx, 2).paragraphs[0].text = scenario
    test_table.cell(r_idx, 3).paragraphs[0].text = res
    test_table.cell(r_idx, 3).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    
    bg_col = "F8FAFC" if r_idx % 2 == 1 else "FFFFFF"
    for col_idx in range(4):
        cell_item = test_table.cell(r_idx, col_idx)
        set_cell_background(cell_item, bg_col)
        set_font(cell_item.paragraphs[0].runs[0], size=11)

p_space2 = doc.add_paragraph()
p_space2.paragraph_format.space_after = Pt(10)

add_heading_2("6.2 Kế Hoạch Phát Triển Trong Tuần Tiếp Theo (Roadmap)")
add_body_p(
    "Dựa trên nền tảng kỹ thuật vững chắc đã hoàn thành trong Tuần 3, kế hoạch phát triển mở rộng trong tuần tiếp theo bao gồm:"
)
add_bullet_p("1. Nâng cấp Tích Hợp Cảm Biến An Toàn IoT: ", "Mở rộng hệ thống phần cứng IoT với cảm biến khói, cảm biến rò rỉ khí gas và cảm biến nhiệt độ tại các khu vực bếp chung và hành lang, kích hoạt còi báo động khẩn cấp và đẩy thông báo đẩy (Push Notification) tức thời đến ứng dụng di động của toàn bộ cư dân.")
add_bullet_p("2. Tự Động Hóa Webhook Thanh Toán Ngân Hàng: ", "Tích hợp cơ chế Webhook IPN ngân hàng tự động (nghiệm thu giao dịch chuyển khoản VietQR trong vòng dưới 3 giây mà không cần thao tác duyệt thủ công của thủ quỹ).")
add_bullet_p("3. Đóng Gói Bộ Cài Đặt (Release Build): ", "Tiến hành cấu hình chứng chỉ bảo mật (Keystore) và xuất file cài đặt Android APK/AAB hoàn chỉnh để chạy thử nghiệm trên các dòng điện thoại thông minh thực tế.")
add_bullet_p("4. Hoàn Thiện Báo Cáo Tổng Kết & Slide Báo Cáo Đồ Án: ", "Biên soạn quyển báo cáo tổng kết đồ án chuyên ngành theo chuẩn quy định của Nhà trường và chuẩn bị bộ Slide thuyết trình bảo vệ đề tài trước Hội đồng chuyên môn.")

doc.save(DOC_PATH)
print("Successfully generated", DOC_PATH)
