import os
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = r"e:\DAN_ChuyenNganh\docs\screenshots"
os.makedirs(OUTPUT_DIR, exist_ok=True)

WIDTH = 750
HEIGHT = 1450

def get_font(size, bold=False):
    # Try system fonts on Windows
    font_names = [
        "C:\\Windows\\Fonts\\segoeui.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\tahoma.ttf",
    ]
    if bold:
        font_names = [
            "C:\\Windows\\Fonts\\segouib.ttf",
            "C:\\Windows\\Fonts\\arialbd.ttf",
            "C:\\Windows\\Fonts\\tahomabd.ttf",
        ]
    for path in font_names:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()

def draw_device_frame(draw, title, role="Cư dân"):
    # Status bar
    draw.rectangle([0, 0, WIDTH, 50], fill=(241, 245, 249))
    draw.text((30, 15), "09:41", fill=(15, 23, 42), font=get_font(20, bold=True))
    draw.text((WIDTH - 110, 15), "5G  100%", fill=(15, 23, 42), font=get_font(18, bold=True))
    
    # App Bar
    draw.rectangle([0, 50, WIDTH, 130], fill=(255, 255, 255))
    draw.line([0, 130, WIDTH, 130], fill=(226, 232, 240), width=1)
    draw.text((30, 75), title, fill=(15, 23, 42), font=get_font(28, bold=True))
    
    # Role Switcher Pill
    role_color = (37, 99, 235) if role == "Cư dân" else ((139, 92, 246) if "Quản lý" in role else (16, 185, 129))
    draw.rounded_rectangle([WIDTH - 170, 70, WIDTH - 30, 110], radius=20, fill=role_color)
    draw.text((WIDTH - 150, 78), f"Vai trò: {role}", fill=(255, 255, 255), font=get_font(16, bold=True))

def draw_bottom_nav(draw, active_idx=0, is_admin=False):
    draw.rectangle([0, HEIGHT - 100, WIDTH, HEIGHT], fill=(255, 255, 255))
    draw.line([0, HEIGHT - 100, WIDTH, HEIGHT - 100], fill=(226, 232, 240), width=1)
    
    items = ["Trang chủ", "Hóa đơn", "Sự cố", "Bảng tin", "Cá nhân"] if not is_admin else ["Điều hành", "Sơ đồ phòng", "Kanban", "Tài chính", "Khóa IoT"]
    w = WIDTH / len(items)
    for i, it in enumerate(items):
        cx = i * w + w / 2
        color = (37, 99, 235) if (i == active_idx and not is_admin) else ((139, 92, 246) if (i == active_idx and is_admin) else (148, 163, 184))
        draw.ellipse([cx - 15, HEIGHT - 85, cx + 15, HEIGHT - 55], fill=color)
        draw.text((cx - len(it)*5, HEIGHT - 45), it, fill=color, font=get_font(15, bold=(i==active_idx)))

# SCREEN 1: RESIDENT HOME
def make_screen_resident_home():
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    draw_device_frame(draw, "SmartStay Cư Dân", "Cư dân")
    
    # Welcome card
    draw.rounded_rectangle([30, 150, WIDTH - 30, 270], radius=16, fill=(37, 99, 235))
    draw.text((55, 175), "Xin chào, Hồ Ngọc Bảo (MSSV: 2380600133)", fill=(255, 255, 255), font=get_font(24, bold=True))
    draw.text((55, 215), "Phòng P.305 • Tòa nhà A • Co-Living SmartStay", fill=(219, 234, 254), font=get_font(18))
    
    # Quick Status Card
    draw.rounded_rectangle([30, 290, WIDTH - 30, 480], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((55, 315), "HÓA ĐƠN THÁNG 10/2026", fill=(100, 116, 139), font=get_font(16, bold=True))
    draw.text((55, 345), "4.159.000 đ", fill=(220, 38, 38), font=get_font(38, bold=True))
    draw.text((55, 400), "Hạn thanh toán: 05/11/2026 • Đã phát hành mã VietQR", fill=(71, 85, 105), font=get_font(16))
    
    draw.rounded_rectangle([55, 430, 260, 465], radius=8, fill=(37, 99, 235))
    draw.text((75, 437), "Thanh toán VietQR ngay >", fill=(255, 255, 255), font=get_font(15, bold=True))
    
    # Active ticket card
    draw.rounded_rectangle([30, 500, WIDTH - 30, 650], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((55, 520), "SỰ CỐ ĐANG XỬ LÝ (SC-2026-089)", fill=(100, 116, 139), font=get_font(16, bold=True))
    draw.text((55, 550), "Máy lạnh Inverter phòng 305 không mát, kêu to", fill=(15, 23, 42), font=get_font(20, bold=True))
    draw.rounded_rectangle([55, 595, 165, 630], radius=8, fill=(239, 246, 255))
    draw.text((70, 603), "ĐANG SỬA", fill=(37, 99, 235), font=get_font(14, bold=True))
    draw.text((180, 603), "KTV: Trần Văn Tuấn (Phụ trách)", fill=(100, 116, 139), font=get_font(15))
    
    # Community & Features Grid
    draw.text((30, 680), "Tiện Ích & Dịch Vụ", fill=(15, 23, 42), font=get_font(22, bold=True))
    features = [
        ("Hóa Đơn & VietQR", "Biểu giá 4 bậc điện, 3 bậc nước", (37, 99, 235)),
        ("Báo Hỏng 3 Bước", "Gửi ảnh trước/sau sửa chữa", (139, 92, 246)),
        ("Trợ Lý AI Gemini", "Hỗ trợ nội quy, kỹ thuật 24/7", (16, 185, 129)),
        ("Hợp Đồng Điện Tử", "Biên bản bàn giao 5 tài sản", (217, 119, 6)),
    ]
    for i, (f_title, f_desc, color) in enumerate(features):
        x = 30 if i % 2 == 0 else WIDTH / 2 + 10
        y = 720 + (i // 2) * 160
        draw.rounded_rectangle([x, y, x + WIDTH/2 - 40, y + 140], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=1)
        draw.rounded_rectangle([x + 15, y + 15, x + 55, y + 55], radius=10, fill=color)
        draw.text((x + 15, y + 68), f_title, fill=(15, 23, 42), font=get_font(18, bold=True))
        draw.text((x + 15, y + 96), f_desc, fill=(100, 116, 139), font=get_font(13))
        
    # AI banner
    draw.rounded_rectangle([30, 1080, WIDTH - 30, 1220], radius=16, fill=(240, 249, 255), outline=(186, 230, 253), width=2)
    draw.text((55, 1105), "🤖 Trợ lý ảo SmartStay Gemini 24/7", fill=(3, 105, 161), font=get_font(20, bold=True))
    draw.text((55, 1140), "Cần tra cứu biểu giá điện nước bậc thang, quy định giờ giấc\nhay hỏi tiến độ xử lý bảo trì? Bấm để trò chuyện ngay!", fill=(14, 116, 144), font=get_font(15))
    
    draw_bottom_nav(draw, 0, False)
    img.save(os.path.join(OUTPUT_DIR, "screen_01_resident_home.png"))

# SCREEN 2: INVOICE & VIETQR
def make_screen_invoice_detail():
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    draw_device_frame(draw, "Chi Tiết Hóa Đơn Kỳ 10/2026", "Cư dân")
    
    # Card Header
    draw.rounded_rectangle([30, 150, WIDTH - 30, 310], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.text((55, 175), "Mã hóa đơn: HD-2026-10-305", fill=(100, 116, 139), font=get_font(16))
    draw.text((55, 205), "4.159.000 đ", fill=(220, 38, 38), font=get_font(36, bold=True))
    draw.rounded_rectangle([WIDTH - 190, 170, WIDTH - 55, 205], radius=6, fill=(254, 242, 242))
    draw.text((WIDTH - 175, 178), "CHỜ THANH TOÁN", fill=(220, 38, 38), font=get_font(13, bold=True))
    draw.text((55, 260), "Hạn chót: 05/11/2026 • Phòng P.305 (Hồ Ngọc Bảo)", fill=(71, 85, 105), font=get_font(16))
    
    # Tiered pricing breakdown table
    draw.text((30, 335), "Bóc Tách Biểu Giá Lũy Tiến Bậc Thang", fill=(15, 23, 42), font=get_font(20, bold=True))
    draw.rounded_rectangle([30, 370, WIDTH - 30, 680], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    
    rows = [
        ("Tiền thuê phòng Co-Living P.305", "1 tháng", "3.500.000 đ"),
        ("⚡ Điện Bậc 1 (0 - 50 kWh)", "50 kWh x 1.800 đ", "90.000 đ"),
        ("⚡ Điện Bậc 2 (51 - 100 kWh)", "50 kWh x 2.200 đ", "110.000 đ"),
        ("⚡ Điện Bậc 3 (101 - 120 kWh)", "20 kWh x 2.700 đ", "54.000 đ"),
        ("💧 Nước Bậc 1 (0 - 5 m³)", "5 m³ x 12.000 đ", "60.000 đ"),
        ("💧 Nước Bậc 2 (6 - 8 m³)", "3 m³ x 15.000 đ", "45.000 đ"),
        ("Dịch vụ cố định (Wifi, rác, thang máy)", "1 tháng", "300.000 đ"),
    ]
    y = 390
    for title, formula, amt in rows:
        draw.text((55, y), title, fill=(15, 23, 42), font=get_font(16, bold=True))
        draw.text((55, y + 22), formula, fill=(100, 116, 139), font=get_font(14))
        draw.text((WIDTH - 190, y + 10), amt, fill=(37, 99, 235), font=get_font(16, bold=True))
        draw.line([55, y + 48, WIDTH - 55, y + 48], fill=(241, 245, 249), width=1)
        y += 50
        
    # Dynamic VietQR NAPAS 247 section
    draw.text((30, 705), "Mã VietQR NAPAS 247 Thanh Toán Tức Thì", fill=(15, 23, 42), font=get_font(20, bold=True))
    draw.rounded_rectangle([30, 740, WIDTH - 30, 1180], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    
    # Simulated QR Code box
    draw.rounded_rectangle([WIDTH/2 - 120, 765, WIDTH/2 + 120, 1005], radius=12, fill=(248, 250, 252), outline=(148, 163, 184), width=2)
    # Draw QR pattern
    draw.rectangle([WIDTH/2 - 95, 790, WIDTH/2 - 35, 850], fill=(15, 23, 42))
    draw.rectangle([WIDTH/2 - 80, 805, WIDTH/2 - 50, 835], fill=(255, 255, 255))
    draw.rectangle([WIDTH/2 + 35, 790, WIDTH/2 + 95, 850], fill=(15, 23, 42))
    draw.rectangle([WIDTH/2 + 50, 805, WIDTH/2 + 80, 835], fill=(255, 255, 255))
    draw.rectangle([WIDTH/2 - 95, 920, WIDTH/2 - 35, 980], fill=(15, 23, 42))
    draw.rectangle([WIDTH/2 - 80, 935, WIDTH/2 - 50, 965], fill=(255, 255, 255))
    draw.text((WIDTH/2 - 30, 880), "NAPAS", fill=(37, 99, 235), font=get_font(16, bold=True))
    
    draw.text((55, 1025), "Ngân hàng: MB Bank (Napas 247) • STK: 0901234567", fill=(15, 23, 42), font=get_font(16, bold=True))
    draw.text((55, 1055), "Chủ TK: SMARTSTAY CO-LIVING ECOSYSTEM", fill=(71, 85, 105), font=get_font(15))
    draw.text((55, 1085), "Số tiền: 4.159.000 đ • Cú pháp: HD 2026 10 305", fill=(220, 38, 38), font=get_font(16, bold=True))
    
    # Upload receipt button
    draw.rounded_rectangle([55, 1120, WIDTH - 55, 1165], radius=10, fill=(16, 185, 129))
    draw.text((WIDTH/2 - 120, 1132), "Tải Lên Ảnh Biên Lai Đối Soát", fill=(255, 255, 255), font=get_font(16, bold=True))
    
    draw_bottom_nav(draw, 1, False)
    img.save(os.path.join(OUTPUT_DIR, "screen_02_invoice_vietqr.png"))

# SCREEN 3: ADMIN ROOM MATRIX
def make_screen_room_matrix():
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    draw_device_frame(draw, "Sơ Đồ Phòng Trực Quan (Room Matrix)", "Quản lý")
    
    # Floor selector bar
    draw.rectangle([0, 131, WIDTH, 195], fill=(255, 255, 255))
    floors = ["Tất cả", "Tầng 1", "Tầng 2", "Tầng 3 (P.305)", "Tầng 4", "Tầng 5"]
    fx = 30
    for i, fl in enumerate(floors):
        sel = (i == 3)
        bg = (37, 99, 235) if sel else (241, 245, 249)
        tc = (255, 255, 255) if sel else (71, 85, 105)
        draw.rounded_rectangle([fx, 145, fx + len(fl)*12 + 25, 180], radius=18, fill=bg)
        draw.text((fx + 12, 153), fl, fill=tc, font=get_font(14, bold=sel))
        fx += len(fl)*12 + 35
        
    # Legend
    draw.rectangle([0, 196, WIDTH, 240], fill=(255, 255, 255))
    draw.line([0, 240, WIDTH, 240], fill=(226, 232, 240), width=1)
    legends = [("Đang ở", (37, 99, 235)), ("Trống", (16, 185, 129)), ("Bảo trì", (239, 68, 68)), ("Đã cọc", (245, 158, 11))]
    lx = 40
    for name, col in legends:
        draw.ellipse([lx, 210, lx + 14, 224], fill=col)
        draw.text((lx + 20, 209), name, fill=(71, 85, 105), font=get_font(14))
        lx += 170
        
    # Matrix 2 columns grid
    rooms = [
        ("P.301", "Studio VIP", "Đang ở", "Vũ Minh Đức", (37, 99, 235), "1600 kWh", "Pin 96%"),
        ("P.302", "Co-Living Đơn", "Trống", "Sẵn sàng đón khách", (16, 185, 129), "0 kWh", "Pin 82%"),
        ("P.305", "Co-Living Ban Công", "Đang ở", "Hồ Ngọc Bảo", (37, 99, 235), "1200 kWh", "Pin 92%"),
        ("P.306", "Co-Living Ban Công", "Bảo trì", "Bảo trì máy lạnh", (239, 68, 68), "980 kWh", "Pin 74%"),
        ("P.401", "Co-Living Đơn", "Đang ở", "Bùi Thị Hà", (37, 99, 235), "890 kWh", "Pin 97%"),
        ("P.402", "Co-Living Đơn", "Trống", "Sẵn sàng đón khách", (16, 185, 129), "0 kWh", "Pin 90%"),
        ("P.501", "Penthouse Sky", "Đang ở", "Đoàn Hải Nam", (37, 99, 235), "2100 kWh", "Pin 98%"),
        ("P.504", "Sky View", "Bảo trì", "Sửa khóa cửa", (239, 68, 68), "1250 kWh", "Pin 65%"),
    ]
    
    for i, (rcode, rtype, status, resident, col, meter, battery) in enumerate(rooms):
        col_idx = i % 2
        row_idx = i // 2
        rx = 30 if col_idx == 0 else WIDTH / 2 + 10
        ry = 260 + row_idx * 210
        rw = WIDTH / 2 - 40
        rh = 195
        
        draw.rounded_rectangle([rx, ry, rx + rw, ry + rh], radius=16, fill=(255, 255, 255), outline=col, width=2)
        draw.text((rx + 15, ry + 15), rcode, fill=(15, 23, 42), font=get_font(22, bold=True))
        
        # Badge
        draw.rounded_rectangle([rx + rw - 85, ry + 15, rx + rw - 15, ry + 40], radius=6, fill=col)
        draw.text((rx + rw - 75, ry + 20), status, fill=(255, 255, 255), font=get_font(12, bold=True))
        
        draw.text((rx + 15, ry + 48), rtype, fill=(100, 116, 139), font=get_font(14))
        draw.line([rx + 15, ry + 72, rx + rw - 15, ry + 72], fill=(241, 245, 249), width=1)
        
        draw.text((rx + 15, ry + 82), resident, fill=(15, 23, 42), font=get_font(15, bold=True))
        draw.text((rx + 15, ry + 108), f"Điện: {meter}", fill=(71, 85, 105), font=get_font(13))
        draw.text((rx + 15, ry + 130), f"Khóa IoT: {battery} • Online", fill=(16, 185, 129), font=get_font(13, bold=True))
        
        # Action button
        btn_text = "Thủ tục Check-in" if status == "Trống" else "Ghi số / Mở khóa"
        draw.rounded_rectangle([rx + 15, ry + 155, rx + rw - 15, ry + 185], radius=6, fill=(241, 245, 249))
        draw.text((rx + 30, ry + 162), btn_text, fill=(37, 99, 235), font=get_font(13, bold=True))
        
    draw_bottom_nav(draw, 1, True)
    img.save(os.path.join(OUTPUT_DIR, "screen_03_room_matrix.png"))

# SCREEN 4: KANBAN MAINTENANCE
def make_screen_kanban():
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    draw_device_frame(draw, "Kanban Quản Lý Bảo Trì & Sự Cố", "Quản lý")
    
    # 3 tabs header
    draw.rectangle([0, 131, WIDTH, 195], fill=(255, 255, 255))
    tabs = [("Chờ Xử Lý (2)", (220, 38, 38)), ("Đang Sửa (3)", (37, 99, 235)), ("Hoàn Thành (8)", (16, 185, 129))]
    tw = WIDTH / 3
    for i, (t_text, t_col) in enumerate(tabs):
        cx = i * tw
        draw.text((cx + 35, 150), t_text, fill=t_col, font=get_font(17, bold=(i==1)))
        if i == 1:
            draw.line([cx + 20, 193, cx + tw - 20, 193], fill=t_col, width=3)
            
    # Tickets cards
    tickets = [
        ("SC-2026-089", "P.305", "Máy lạnh không mát, kêu to", "Khẩn cấp", "KTV: Trần Văn Tuấn", "Đang tháo dàn lạnh kiểm tra gas", (37, 99, 235)),
        ("SC-2026-092", "P.104", "Vòi rửa lavabo bị rò rỉ nước", "Cao", "KTV: Lê Minh Khang", "Đang thay roăng cao su mới", (139, 92, 246)),
        ("SC-2026-095", "P.306", "Khóa cửa thông minh chập chờn vân tay", "Cao", "KTV: Trần Văn Tuấn", "Đã reset module Zigbee", (217, 119, 6)),
    ]
    
    y = 220
    for code, room, title, pri, ktv, note, col in tickets:
        draw.rounded_rectangle([30, y, WIDTH - 30, y + 270], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
        
        # Tags
        draw.rounded_rectangle([55, y + 20, 180, y + 50], radius=6, fill=(241, 245, 249))
        draw.text((70, y + 26), f"{code} • {room}", fill=(71, 85, 105), font=get_font(14, bold=True))
        
        draw.rounded_rectangle([WIDTH - 150, y + 20, WIDTH - 55, y + 50], radius=6, fill=(254, 242, 242))
        draw.text((WIDTH - 140, y + 26), pri, fill=(220, 38, 38), font=get_font(13, bold=True))
        
        draw.text((55, y + 65), title, fill=(15, 23, 42), font=get_font(20, bold=True))
        draw.text((55, y + 98), f"Phụ trách: {ktv}", fill=(37, 99, 235), font=get_font(15, bold=True))
        draw.text((55, y + 128), f"Tiến độ: {note}", fill=(100, 116, 139), font=get_font(14))
        
        draw.line([55, y + 165, WIDTH - 55, y + 165], fill=(241, 245, 249), width=1)
        
        # Action buttons on card
        draw.rounded_rectangle([55, y + 185, 280, y + 235], radius=8, fill=(241, 245, 249))
        draw.text((85, y + 198), "Đổi Kỹ Thuật Viên", fill=(71, 85, 105), font=get_font(14, bold=True))
        
        draw.rounded_rectangle([300, y + 185, WIDTH - 55, y + 235], radius=8, fill=(16, 185, 129))
        draw.text((WIDTH/2 + 25, y + 198), "Xác Nhận Hoàn Thành", fill=(255, 255, 255), font=get_font(15, bold=True))
        
        y += 295
        
    draw_bottom_nav(draw, 2, True)
    img.save(os.path.join(OUTPUT_DIR, "screen_04_kanban.png"))

# SCREEN 5: IOT SMART LOCKS
def make_screen_iot():
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    draw_device_frame(draw, "Khóa Thông Minh IoT & Kiểm Soát Cửa", "Quản lý")
    
    # Gateway Hub Card
    draw.rounded_rectangle([30, 150, WIDTH - 30, 280], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    draw.rounded_rectangle([55, 175, 115, 235], radius=12, fill=(239, 246, 255))
    draw.text((70, 188), "📶", font=get_font(30))
    draw.text((135, 180), "Cổng Kết Nối IoT Gateway Tầng 3", fill=(15, 23, 42), font=get_font(20, bold=True))
    draw.text((135, 215), "Mạng Zigbee 3.0 • 20 Khóa Đang Trực Tuyến • Tín hiệu: 98%", fill=(100, 116, 139), font=get_font(14))
    draw.rounded_rectangle([WIDTH - 150, 175, WIDTH - 55, 205], radius=6, fill=(240, 253, 244))
    draw.text((WIDTH - 135, 182), "ONLINE", fill=(16, 185, 129), font=get_font(13, bold=True))
    
    # Real-time Locks list
    draw.text((30, 310), "Trạng Thái Khóa Thông Minh Theo Phòng", fill=(15, 23, 42), font=get_font(20, bold=True))
    locks = [
        ("P.305", "Hồ Ngọc Bảo", "Pin 92%", "Đóng cửa (Locked)", (16, 185, 129)),
        ("P.301", "Vũ Minh Đức", "Pin 96%", "Đóng cửa (Locked)", (16, 185, 129)),
        ("P.306", "Bảo trì kỹ thuật", "Pin 74%", "Mở khóa phục vụ sửa chữa", (239, 68, 68)),
        ("P.101", "Nguyễn Văn An", "Pin 88%", "Đóng cửa (Locked)", (16, 185, 129)),
    ]
    
    y = 350
    for room, person, bat, l_status, col in locks:
        draw.rounded_rectangle([30, y, WIDTH - 30, y + 105], radius=14, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
        draw.text((55, y + 20), room, fill=(15, 23, 42), font=get_font(20, bold=True))
        draw.text((140, y + 22), f"• {person}", fill=(71, 85, 105), font=get_font(16))
        draw.text((55, y + 55), f"Tình trạng: {l_status}", fill=col, font=get_font(15, bold=True))
        draw.text((320, y + 55), f"• Nguồn: {bat}", fill=(100, 116, 139), font=get_font(15))
        
        # Remote unlock button
        draw.rounded_rectangle([WIDTH - 180, y + 25, WIDTH - 55, y + 75], radius=8, fill=(2, 132, 199))
        draw.text((WIDTH - 165, y + 38), "Mở Khóa Từ Xa", fill=(255, 255, 255), font=get_font(13, bold=True))
        y += 125
        
    # Access Audit Log
    draw.text((30, 875), "Nhật Ký Quẹt Thẻ / Vân Tay Mới Nhất", fill=(15, 23, 42), font=get_font(20, bold=True))
    draw.rounded_rectangle([30, 915, WIDTH - 30, 1300], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=2)
    
    logs = [
        ("P.305", "Hồ Ngọc Bảo", "Vân tay cửa chính", "09:32 (Vừa xong)", True),
        ("P.305", "Trần Văn Tuấn (Kỹ thuật)", "Thẻ từ RFID Master", "08:15", True),
        ("P.101", "Nguyễn Văn An", "Mở từ xa qua App", "07:40", True),
        ("P.201", "Người lạ (Sai dấu vân tay)", "Vân tay - Báo động", "06:10", False),
        ("P.501", "Đoàn Hải Nam", "Mã PIN cá nhân", "05:55", True),
    ]
    ly = 940
    for room, person, method, time_str, success in logs:
        dot_col = (16, 185, 129) if success else (220, 38, 38)
        draw.ellipse([55, ly + 5, 69, ly + 19], fill=dot_col)
        draw.text((85, ly), f"{room} • {person}", fill=(15, 23, 42), font=get_font(16, bold=True))
        draw.text((85, ly + 25), f"Phương thức: {method}", fill=(100, 116, 139), font=get_font(14))
        draw.text((WIDTH - 170, ly + 10), time_str, fill=(148, 163, 184), font=get_font(14))
        draw.line([55, ly + 55, WIDTH - 55, ly + 55], fill=(241, 245, 249), width=1)
        ly += 65
        
    draw_bottom_nav(draw, 4, True)
    img.save(os.path.join(OUTPUT_DIR, "screen_05_iot_smartlock.png"))

# SCREEN 6: AI GEMINI CHAT
def make_screen_ai_chat():
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    draw_device_frame(draw, "Trợ Lý AI SmartStay 24/7", "Cư dân")
    
    # Bot intro bubble
    draw.rounded_rectangle([30, 160, WIDTH - 120, 310], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=1)
    draw.text((50, 180), "🤖 SmartStay AI Copilot", fill=(37, 99, 235), font=get_font(16, bold=True))
    draw.text((50, 215), "Xin chào bạn Bảo (P.305)! Mình là Trợ lý ảo AI\nhỗ trợ bạn 24/7. Bạn có thể hỏi mình về biểu giá điện nước,\ncách thanh toán VietQR hay tiến độ xử lý bảo trì nhé!", fill=(15, 23, 42), font=get_font(15))
    
    # User question bubble
    draw.rounded_rectangle([WIDTH - 380, 340, WIDTH - 30, 420], radius=16, fill=(37, 99, 235))
    draw.text((WIDTH - 360, 360), "Hóa đơn tháng 10 của phòng mình\ntính tiền điện nước như thế nào vậy AI?", fill=(255, 255, 255), font=get_font(16))
    
    # Bot answer bubble with tiered explanation
    draw.rounded_rectangle([30, 450, WIDTH - 80, 830], radius=16, fill=(255, 255, 255), outline=(226, 232, 240), width=1)
    draw.text((50, 470), "🤖 SmartStay AI Copilot", fill=(37, 99, 235), font=get_font(16, bold=True))
    ans = (
        "Chào bạn Bảo! Hóa đơn tháng 10 của phòng P.305\n"
        "được hệ thống tính tự động theo biểu giá bậc thang lũy tiến:\n\n"
        "⚡ Tiền điện (120 kWh tiêu thụ):\n"
        " • Bậc 1 (0 - 50 kWh): 50 x 1.800 đ = 90.000 đ\n"
        " • Bậc 2 (51 - 100 kWh): 50 x 2.200 đ = 110.000 đ\n"
        " • Bậc 3 (101 - 120 kWh): 20 x 2.700 đ = 54.000 đ\n"
        " => Tổng tiền điện: 254.000 đ\n\n"
        "💧 Tiền nước (8 m³ tiêu thụ):\n"
        " • Bậc 1 (0 - 5 m³): 5 x 12.000 đ = 60.000 đ\n"
        " • Bậc 2 (6 - 8 m³): 3 x 15.000 đ = 45.000 đ\n"
        " => Tổng tiền nước: 105.000 đ\n\n"
        "Cộng tiền phòng 3.500.000 đ và phí dịch vụ 300.000 đ,\n"
        "tổng hóa đơn của bạn là 4.159.000 đ bạn nhé!"
    )
    draw.text((50, 505), ans, fill=(15, 23, 42), font=get_font(14))
    
    # Chat Input bar
    draw.rectangle([0, HEIGHT - 180, WIDTH, HEIGHT - 100], fill=(255, 255, 255))
    draw.line([0, HEIGHT - 180, WIDTH, HEIGHT - 180], fill=(226, 232, 240), width=1)
    draw.rounded_rectangle([30, HEIGHT - 165, WIDTH - 110, HEIGHT - 115], radius=24, fill=(241, 245, 249))
    draw.text((55, HEIGHT - 148), "Hỏi SmartStay AI bất cứ điều gì...", fill=(148, 163, 184), font=get_font(15))
    draw.rounded_rectangle([WIDTH - 90, HEIGHT - 165, WIDTH - 30, HEIGHT - 115], radius=24, fill=(37, 99, 235))
    draw.text((WIDTH - 67, HEIGHT - 150), "➤", fill=(255, 255, 255), font=get_font(18))
    
    draw_bottom_nav(draw, 0, False)
    img.save(os.path.join(OUTPUT_DIR, "screen_06_ai_chat.png"))

if __name__ == "__main__":
    print("Generating report screenshot assets...")
    make_screen_resident_home()
    make_screen_invoice_detail()
    make_screen_room_matrix()
    make_screen_kanban()
    make_screen_iot()
    make_screen_ai_chat()
    print("Done! All 6 screenshots generated in", OUTPUT_DIR)
