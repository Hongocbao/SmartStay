(function (global) {
    'use strict';

    var TESSERACT_CDN = 'https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js';
    var tesseractPromise = null;
    var workerPromise = null;

    function loadTesseract() {
        if (global.Tesseract && typeof global.Tesseract.createWorker === 'function') {
            return Promise.resolve(global.Tesseract);
        }
        if (tesseractPromise) return tesseractPromise;
        tesseractPromise = new Promise(function (resolve, reject) {
            var script = document.createElement('script');
            script.src = TESSERACT_CDN;
            script.async = true;
            script.crossOrigin = 'anonymous';
            script.onload = function () {
                if (global.Tesseract) resolve(global.Tesseract);
                else reject(new Error('Tesseract.js loaded without global export'));
            };
            script.onerror = function () {
                tesseractPromise = null;
                reject(new Error('Không thể tải Tesseract.js WASM CDN'));
            };
            document.head.appendChild(script);
        });
        return tesseractPromise;
    }

    async function getOcrWorker() {
        if (workerPromise) return workerPromise;
        workerPromise = (async function () {
            var T = await loadTesseract();
            var worker = await T.createWorker('eng', 1, { logger: function () { } });
            return worker;
        })();
        return workerPromise;
    }

    function loadImage(dataUrl) {
        return new Promise(function (resolve, reject) {
            var img = new Image();
            img.onload = function () { resolve(img); };
            img.onerror = function () { reject(new Error('Không thể đọc dữ liệu ảnh tải lên')); };
            img.src = dataUrl;
        });
    }

    function makeCanvas(w, h) {
        var c = document.createElement('canvas');
        c.width = Math.max(1, Math.round(w));
        c.height = Math.max(1, Math.round(h));
        return c;
    }

    function cropCanvas(src, sx, sy, sw, sh) {
        var rx = Math.max(0, Math.round(sx));
        var ry = Math.max(0, Math.round(sy));
        var rw = Math.max(2, Math.min(src.width - rx, Math.round(sw)));
        var rh = Math.max(2, Math.min(src.height - ry, Math.round(sh)));
        var c = makeCanvas(rw, rh);
        c.getContext('2d').drawImage(src, rx, ry, rw, rh, 0, 0, rw, rh);
        return c;
    }

    function padCanvas(src, padPx) {
        var p = padPx || 28;
        var c = makeCanvas(src.width + p * 2, src.height + p * 2);
        var ctx = c.getContext('2d');
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, c.width, c.height);
        ctx.drawImage(src, p, p);
        return c;
    }

    function boxBlurGray(gray, w, h, radius) {
        var out = new Float32Array(w * h);
        var tmp = new Float32Array(w * h);
        var win = radius * 2 + 1;
        for (var y = 0; y < h; y++) {
            var sum = 0;
            for (var x = -radius; x <= radius; x++) {
                var cx = Math.max(0, Math.min(w - 1, x));
                sum += gray[y * w + cx];
            }
            for (var x2 = 0; x2 < w; x2++) {
                tmp[y * w + x2] = sum / win;
                var rem = Math.max(0, x2 - radius);
                var add = Math.min(w - 1, x2 + radius + 1);
                sum += gray[y * w + add] - gray[y * w + rem];
            }
        }
        for (var x3 = 0; x3 < w; x3++) {
            var sumY = 0;
            for (var yy = -radius; yy <= radius; yy++) {
                var cy = Math.max(0, Math.min(h - 1, yy));
                sumY += tmp[cy * w + x3];
            }
            for (var y2 = 0; y2 < h; y2++) {
                out[y2 * w + x3] = sumY / win;
                var remY = Math.max(0, y2 - radius);
                var addY = Math.min(h - 1, y2 + radius + 1);
                sumY += tmp[addY * w + x3] - tmp[remY * w + x3];
            }
        }
        return out;
    }

    function otsuThreshold(vals) {
        var hist = new Int32Array(256);
        for (var i = 0; i < vals.length; i++) {
            hist[Math.max(0, Math.min(255, Math.round(vals[i])))]++;
        }
        var total = vals.length;
        var sum = 0;
        for (var t = 0; t < 256; t++) sum += t * hist[t];
        var sumB = 0, wB = 0, maxVar = 0, thresh = 128;
        for (var t2 = 0; t2 < 256; t2++) {
            wB += hist[t2];
            if (wB === 0) continue;
            var wF = total - wB;
            if (wF === 0) break;
            sumB += t2 * hist[t2];
            var mB = sumB / wB;
            var mF = (sum - sumB) / wF;
            var between = wB * wF * (mB - mF) * (mB - mF);
            if (between > maxVar) {
                maxVar = between;
                thresh = t2;
            }
        }
        return thresh;
    }

    // Lọc bỏ nhiễu chấm nhỏ & dải viền dài ngang sát mép trên/dưới
    function filterNoiseComponents(binary, w, h) {
        var visited = new Uint8Array(w * h);
        var minArea = Math.max(10, Math.round((w * h) * 0.00045));
        for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
                var start = y * w + x;
                if (!binary[start] || visited[start]) continue;
                var stack = [start];
                var comp = [];
                visited[start] = 1;
                var minX = x, maxX = x, minY = y, maxY = y;
                while (stack.length) {
                    var cur = stack.pop();
                    comp.push(cur);
                    var cx = cur % w, cy = (cur / w) | 0;
                    if (cx < minX) minX = cx;
                    if (cx > maxX) maxX = cx;
                    if (cy < minY) minY = cy;
                    if (cy > maxY) maxY = cy;
                    var neighbors = [];
                    if (cx > 0) neighbors.push(cur - 1);
                    if (cx + 1 < w) neighbors.push(cur + 1);
                    if (cy > 0) neighbors.push(cur - w);
                    if (cy + 1 < h) neighbors.push(cur + w);
                    for (var ni = 0; ni < neighbors.length; ni++) {
                        var nb = neighbors[ni];
                        if (binary[nb] && !visited[nb]) {
                            visited[nb] = 1;
                            stack.push(nb);
                        }
                    }
                }
                var cw = maxX - minX + 1, ch = maxY - minY + 1;
                // Giữ lại dấu chấm thập phân nhỏ nằm ở nửa dưới vùng số, chỉ xóa thanh viền ngang quá rộng hoặc nhiễu cực bé
                var isDot = comp.length >= 6 && comp.length <= minArea * 2 && cw <= h * 0.16 && ch <= h * 0.16 && minY > h * 0.45;
                var isHorizontalFrameBar = cw > w * 0.48 && ch < h * 0.28;
                var isWideFrame = cw > w * 0.72;
                var isTinyNoise = comp.length < minArea && !isDot;
                var touchesFrameMargin = (maxY <= Math.floor(h * 0.10) || minY >= Math.floor(h * 0.92)) && cw > w * 0.15;
                if (isHorizontalFrameBar || isWideFrame || isTinyNoise || touchesFrameMargin) {
                    for (var ci = 0; ci < comp.length; ci++) binary[comp[ci]] = 0;
                }
            }
        }
        return binary;
    }

    // Tiền xử lý LCD 7 đoạn: Khử moiré trên ảnh nhỏ -> Nội suy làm phẳng nền sáng (loại bỏ bóng tối viền trên LCD) -> Otsu sắc nét -> Close nhẹ nối nét 7 đoạn
    function preprocessElectricRoi(srcCanvas, options) {
        options = options || {};
        var sw = srcCanvas.width, sh = srcCanvas.height;
        var srcD = srcCanvas.getContext('2d').getImageData(0, 0, sw, sh).data;
        var baseGray = new Float32Array(sw * sh);
        for (var s = 0; s < sw * sh; s++) {
            baseGray[s] = 0.299 * srcD[s * 4] + 0.587 * srcD[s * 4 + 1] + 0.114 * srcD[s * 4 + 2];
        }

        // Khử sọc moiré bằng blur nhẹ bán kính 1px trước khi phóng đại
        var smoothSmall = boxBlurGray(baseGray, sw, sh, 1);
        // Ước lượng nền sáng chậm bằng blur bán kính lớn hơn (~18% chiều cao ROI) để triệt tiêu bóng đổ trên mép LCD
        var bgSmall = boxBlurGray(smoothSmall, sw, sh, Math.max(4, Math.round(sh * 0.18)));

        var normCanvas = makeCanvas(sw, sh);
        var normCtx = normCanvas.getContext('2d');
        var normImg = normCtx.createImageData(sw, sh);
        for (var i = 0; i < sw * sh; i++) {
            var bg = Math.max(40, bgSmall[i]);
            var vNorm = Math.min(255, Math.max(0, Math.round((smoothSmall[i] / bg) * 196)));
            normImg.data[i * 4] = vNorm;
            normImg.data[i * 4 + 1] = vNorm;
            normImg.data[i * 4 + 2] = vNorm;
            normImg.data[i * 4 + 3] = 255;
        }
        normCtx.putImageData(normImg, 0, 0);

        var scale = options.scale || 3.6;
        var w = Math.max(60, Math.round(sw * scale));
        var h = Math.max(24, Math.round(sh * scale));
        var c = makeCanvas(w, h);
        var ctx = c.getContext('2d');
        ctx.imageSmoothingEnabled = true;
        ctx.drawImage(normCanvas, 0, 0, w, h);

        var imgData = ctx.getImageData(0, 0, w, h);
        var d = imgData.data;
        var coreVals = [];
        for (var y = Math.floor(h * 0.12); y < Math.floor(h * 0.88); y++) {
            for (var x = Math.floor(w * 0.04); x < Math.floor(w * 0.96); x++) {
                coreVals.push(d[(y * w + x) * 4]);
            }
        }
        var th = otsuThreshold(coreVals);
        // Siết nhẹ ngưỡng để chữ LED tối tách rõ khỏi nền xám LCD
        var effectiveTh = Math.min(168, th - (options.threshShift || 4));
        var binary = new Uint8Array(w * h);
        for (var y2 = Math.floor(h * 0.03); y2 < Math.floor(h * 0.98); y2++) {
            for (var x2 = Math.floor(w * 0.02); x2 < Math.floor(w * 0.98); x2++) {
                var pos = y2 * w + x2;
                binary[pos] = d[pos * 4] <= effectiveTh ? 1 : 0;
            }
        }

        // Cắt bỏ thanh viền khung LCD ở sát mép ngoài cùng trên/dưới và trái/phải, tuyệt đối không chạm vùng chữ số
        for (var yr = 0; yr < h; yr++) {
            if (yr < Math.floor(h * 0.22) || yr >= Math.floor(h * 0.88)) {
                var rowDark = 0;
                for (var xr = 0; xr < w; xr++) {
                    if (binary[yr * w + xr]) rowDark++;
                }
                if (rowDark > w * 0.50) {
                    for (var xr2 = 0; xr2 < w; xr2++) binary[yr * w + xr2] = 0;
                }
            }
        }
        for (var xc = 0; xc < w; xc++) {
            if (xc < Math.floor(w * 0.10) || xc >= Math.floor(w * 0.88)) {
                var colDark = 0;
                for (var yc = 0; yc < h; yc++) {
                    if (binary[yc * w + xc]) colDark++;
                }
                if (colDark > h * 0.58) {
                    for (var yc2 = 0; yc2 < h; yc2++) binary[yc2 * w + xc] = 0;
                }
            }
        }

        filterNoiseComponents(binary, w, h);

        if (options.closeGap) {
            var dil = new Uint8Array(w * h);
            for (var y3 = 1; y3 < h - 1; y3++) {
                for (var x3 = 1; x3 < w - 1; x3++) {
                    var idx = y3 * w + x3;
                    dil[idx] = (
                        binary[idx] ||
                        binary[idx - 1] || binary[idx + 1] ||
                        binary[idx - w] || binary[idx + w]
                    ) ? 1 : 0;
                }
            }
            binary = dil;
        }

        for (var q = 0; q < binary.length; q++) {
            var v = binary[q] ? 0 : 255;
            d[q * 4] = v; d[q * 4 + 1] = v; d[q * 4 + 2] = v; d[q * 4 + 3] = 255;
        }
        ctx.putImageData(imgData, 0, 0);
        return padCanvas(c, 32);
    }

    // Tiền xử lý dải đồng hồ nước cơ học: chỉ tỉa lề trắng ngoài cùng ở 2 đầu, KHÔNG lọc cột giữa chữ số
    function preprocessMechanicalWaterWindow(srcCanvas) {
        var scale = 3.6;
        var w = Math.max(60, Math.round(srcCanvas.width * scale));
        var h = Math.max(20, Math.round(srcCanvas.height * scale));
        var c = makeCanvas(w, h);
        var ctx = c.getContext('2d');
        ctx.imageSmoothingEnabled = true;
        ctx.drawImage(srcCanvas, 0, 0, w, h);

        var imgData = ctx.getImageData(0, 0, w, h);
        var d = imgData.data;

        var colDrumCoverage = new Float32Array(w);
        var colHasRed = new Uint8Array(w);
        var lumMap = new Float32Array(w * h);
        var satMap = new Float32Array(w * h);

        for (var x = 0; x < w; x++) {
            var drumPx = 0, redPx = 0;
            for (var y = 0; y < h; y++) {
                var i = (y * w + x) * 4;
                var r = d[i], g = d[i + 1], b = d[i + 2];
                var lum = 0.299 * r + 0.587 * g + 0.114 * b;
                var isRed = (r - Math.max(g, b)) > 28 && r > 75;
                satMap[y * w + x] = Math.max(r, g, b) - Math.min(r, g, b);
                // Đối với ô nền đỏ [4], chỉ dùng kênh G+B (bỏ kênh R) để chữ số trắng bật hẳn khỏi nền đỏ
                lumMap[y * w + x] = isRed ? (0.50 * g + 0.50 * b) : lum;
                if (lum < 120 || isRed) drumPx++;
                if (isRed) redPx++;
            }
            colDrumCoverage[x] = drumPx / h;
            if (redPx > h * 0.22) colHasRed[x] = 1;
        }

        // Chỉ tỉa viền trắng mặt đồng hồ ở sát mép trái/phải, giữ nguyên toàn bộ ruột dãy bánh xe số
        var xStart = 0;
        var maxTrimL = Math.floor(w * 0.14);
        while (xStart < maxTrimL && colDrumCoverage[xStart] < 0.22) xStart++;

        var xEnd = w - 1;
        var minTrimR = Math.floor(w * 0.88);
        while (xEnd > minTrimR && colDrumCoverage[xEnd] < 0.22) xEnd--;

        var blackVals = [], redVals = [];
        for (var y2 = Math.floor(h * 0.12); y2 < Math.floor(h * 0.88); y2++) {
            for (var x2 = xStart; x2 <= xEnd; x2++) {
                if (colHasRed[x2]) redVals.push(lumMap[y2 * w + x2]);
                else blackVals.push(lumMap[y2 * w + x2]);
            }
        }

        var blackTh = blackVals.length ? Math.max(120, otsuThreshold(blackVals) + 6) : 138;
        var redTh = redVals.length ? Math.max(95, otsuThreshold(redVals) + 6) : 125;

        var binary = new Uint8Array(w * h);
        for (var y3 = Math.floor(h * 0.10); y3 < Math.floor(h * 0.90); y3++) {
            for (var x3 = xStart; x3 <= xEnd; x3++) {
                var pos = y3 * w + x3;
                var th = colHasRed[x3] ? redTh : blackTh;
                if (lumMap[pos] >= th && (colHasRed[x3] || satMap[pos] < 72 || lumMap[pos] > th + 18)) {
                    binary[pos] = 1;
                }
            }
        }

        filterNoiseComponents(binary, w, h);

        // Xóa vạch chia dọc cực mảnh giữa các bánh xe số nếu cao > 62% chiều cao
        for (var xv = xStart; xv <= xEnd; xv++) {
            var vDark = 0;
            for (var yv = 0; yv < h; yv++) {
                if (binary[yv * w + xv]) vDark++;
            }
            if (vDark > h * 0.72) {
                var leftEmpty = xv > 0 && binary[Math.floor(h * 0.5) * w + xv - 1] === 0;
                var rightEmpty = xv + 1 < w && binary[Math.floor(h * 0.5) * w + xv + 1] === 0;
                if (leftEmpty && rightEmpty) {
                    for (var yv2 = 0; yv2 < h; yv2++) binary[yv2 * w + xv] = 0;
                }
            }
        }

        for (var q = 0; q < binary.length; q++) {
            var v = binary[q] ? 0 : 255;
            d[q * 4] = v; d[q * 4 + 1] = v; d[q * 4 + 2] = v; d[q * 4 + 3] = 255;
        }
        ctx.putImageData(imgData, 0, 0);
        return padCanvas(c, 32);
    }

    function findElectricLcdRois(baseCanvas) {
        var w = baseCanvas.width, h = baseCanvas.height;
        var d = baseCanvas.getContext('2d').getImageData(0, 0, w, h).data;

        var candidates = [];
        var sizes = [
            { rw: 0.30, rh: 0.25 },
            { rw: 0.36, rh: 0.27 },
            { rw: 0.42, rh: 0.25 },
            { rw: 0.50, rh: 0.28 }
        ];

        var bestScore = -1, bestRect = null;
        sizes.forEach(function (sz) {
            var rw = Math.floor(w * sz.rw), rh = Math.floor(h * sz.rh);
            var stepX = Math.max(4, Math.floor(w / 44));
            var stepY = Math.max(3, Math.floor(h / 44));
            for (var ry = Math.floor(h * 0.10); ry <= Math.floor(h * 0.80) - rh; ry += stepY) {
                for (var rx = Math.floor(w * 0.15); rx <= Math.floor(w * 0.85) - rw; rx += stepX) {
                    var neutralGrey = 0, darkStroke = 0, whiteInside = 0, n = 0;
                    for (var y = ry; y < ry + rh; y += 3) {
                        for (var x = rx; x < rx + rw; x += 3) {
                            var i = (y * w + x) * 4;
                            var r = d[i], g = d[i + 1], b = d[i + 2];
                            var sat = Math.max(r, g, b) - Math.min(r, g, b);
                            var lum = 0.299 * r + 0.587 * g + 0.114 * b;
                            n++;
                            if (sat < 35 && lum >= 75 && lum <= 165) neutralGrey++;
                            else if (sat < 35 && lum < 72) darkStroke++;
                            else if (lum > 185) whiteInside++;
                        }
                    }
                    if (!n) continue;
                    var greyR = neutralGrey / n;
                    var darkR = darkStroke / n;
                    var whiteInR = whiteInside / n;
                    if (greyR < 0.32 || darkR < 0.08 || darkR > 0.45 || whiteInR > 0.26) continue;

                    var haloWhite = 0, haloN = 0;
                    var padX = Math.max(6, Math.floor(rw * 0.16));
                    var padY = Math.max(6, Math.floor(rh * 0.24));
                    var xL = Math.max(0, rx - padX), xR = Math.min(w - 1, rx + rw + padX);
                    var yT = Math.max(0, ry - padY), yB = Math.min(h - 1, ry + rh + padY);
                    for (var hy = yT; hy <= yB; hy += 4) {
                        [xL, xR].forEach(function (hx) {
                            var hi = (hy * w + hx) * 4;
                            var hl = 0.299 * d[hi] + 0.587 * d[hi + 1] + 0.114 * d[hi + 2];
                            haloN++;
                            if (hl > 160) haloWhite++;
                        });
                    }
                    for (var hx2 = rx; hx2 < rx + rw; hx2 += 4) {
                        [yT, yB].forEach(function (hy2) {
                            var hi2 = (hy2 * w + hx2) * 4;
                            var hl2 = 0.299 * d[hi2] + 0.587 * d[hi2 + 1] + 0.114 * d[hi2 + 2];
                            haloN++;
                            if (hl2 > 160) haloWhite++;
                        });
                    }
                    var haloRatio = haloN ? (haloWhite / haloN) : 0;
                    if (haloRatio < 0.30) continue;

                    var sc = greyR * 2.0 + darkR * 2.5 + haloRatio * 3.0 - whiteInR * 1.5;
                    if (sc > bestScore) {
                        bestScore = sc;
                        bestRect = { x: rx, y: ry, w: rw, h: rh };
                    }
                }
            }
        });

        if (bestRect) {
            // Mở rộng nhẹ sang phải & xuống dưới một chút để giữ nguyên nét đáy của số 8 và .5 trên LCD
            candidates.push({
                name: 'lcd-detected',
                canvas: cropCanvas(
                    baseCanvas,
                    bestRect.x - bestRect.w * 0.02,
                    bestRect.y - bestRect.h * 0.02,
                    bestRect.w * 1.12,
                    bestRect.h * 1.10
                )
            });
        }

        candidates.push({ name: 'center-lcd', canvas: cropCanvas(baseCanvas, w * 0.38, h * 0.15, w * 0.38, h * 0.42) });
        candidates.push({ name: 'center-tight', canvas: cropCanvas(baseCanvas, w * 0.28, h * 0.12, w * 0.52, h * 0.46) });
        return candidates;
    }

    function findWaterCounterRois(baseCanvas) {
        var w = baseCanvas.width, h = baseCanvas.height;
        var d = baseCanvas.getContext('2d').getImageData(0, 0, w, h).data;

        var rois = [];
        var bestScore = -1, bestRect = null;
        var sizes = [
            { rw: 0.26, rh: 0.16 },
            { rw: 0.32, rh: 0.20 },
            { rw: 0.42, rh: 0.20 },
            { rw: 0.56, rh: 0.24 }
        ];

        sizes.forEach(function (sz) {
            var rw = Math.floor(w * sz.rw), rh = Math.floor(h * sz.rh);
            var stepX = Math.max(4, Math.floor(w / 44));
            var stepY = Math.max(3, Math.floor(h / 44));
            for (var ry = Math.floor(h * 0.04); ry <= Math.floor(h * 0.68) - rh; ry += stepY) {
                for (var rx = Math.floor(w * 0.08); rx <= Math.floor(w * 0.92) - rw; rx += stepX) {
                    var darkL = 0, whiteL = 0, nL = 0, redR = 0, nR = 0;
                    var splitX = rx + rw * 0.78;
                    for (var y = ry + 2; y < ry + rh - 2; y += 3) {
                        for (var x = rx + 2; x < rx + rw - 2; x += 3) {
                            var i = (y * w + x) * 4;
                            var r = d[i], g = d[i + 1], b = d[i + 2];
                            var lum = 0.299 * r + 0.587 * g + 0.114 * b;
                            if (x >= splitX) {
                                nR++;
                                if ((r - Math.max(g, b)) > 32 && r > 80) redR++;
                            } else {
                                nL++;
                                if (lum < 105 && (r - b) < 35) darkL++;
                                else if (lum > 148) whiteL++;
                            }
                        }
                    }
                    if (!nL || !nR) continue;
                    var darkRatio = darkL / nL;
                    var whiteRatio = whiteL / nL;
                    var redRatio = redR / nR;
                    if (darkRatio > 0.26 && whiteRatio > 0.08 && whiteRatio < 0.52 && redRatio > 0.22) {
                        var sc = darkRatio * 2.2 + redRatio * 2.8 + Math.min(whiteRatio, 0.30) * 1.5;
                        if (sc > bestScore) {
                            bestScore = sc;
                            bestRect = { x: rx, y: ry, w: rw, h: rh };
                        }
                    }
                }
            }
        });

        if (bestRect) {
            // Mở rộng 4% sang trái/phải để chữ số [0] ở đầu luôn nằm trọn vẹn
            rois.push({
                name: 'water-counter-detected',
                hasRedBox: true,
                canvas: cropCanvas(
                    baseCanvas,
                    bestRect.x - bestRect.w * 0.04,
                    bestRect.y - bestRect.h * 0.04,
                    bestRect.w * 1.08,
                    bestRect.h * 1.08
                )
            });
        }

        rois.push({
            name: 'water-upper-center',
            hasRedBox: true,
            canvas: cropCanvas(baseCanvas, w * 0.30, h * 0.08, w * 0.40, h * 0.32)
        });
        rois.push({
            name: 'water-center',
            hasRedBox: false,
            canvas: cropCanvas(baseCanvas, w * 0.15, h * 0.12, w * 0.70, h * 0.45)
        });
        return rois;
    }

    function extractBestMeterNumber(ocrResults, meterType, prevReading) {
        var isElec = meterType === 'electric';
        var candidates = [];

        ocrResults.forEach(function (entry) {
            var rawLine = String(entry.text || '').replace(/[Oo]/g, '0').replace(/[lI|]/g, '1').replace(/[Ss]/g, '5');
            var cleaned = rawLine.replace(/\s*\.\s*/g, '.');
            if (isElec) {
                // Nếu OCR đọc nhầm chấm nhiễu ngay sau số 0 đầu (vd "0.1548.5" hoặc "0.15485"), gộp lại thành "01548..."
                cleaned = cleaned.replace(/\b0[.,](\d{4,})/g, '0$1');
            }
            var tokens = cleaned.match(/\d+(?:[.,]\d+)?/g) || [];
            var joinedDigits = cleaned.replace(/[^0-9.]/g, '');
            if (joinedDigits.length >= 4 && joinedDigits.length <= 8 && tokens.indexOf(joinedDigits) === -1) {
                tokens.push(joinedDigits);
            }

            tokens.forEach(function (tok) {
                var norm = tok.replace(',', '.');
                var hasDot = norm.indexOf('.') !== -1;
                var parts = norm.split('.');
                var intStr = parts[0] || '';
                var fracStr = parts[1] || '';

                if (intStr.length < 3 || intStr.length > 6) return;
                if (!hasDot && (intStr === '220' || intStr === '380' || intStr === '50' || intStr === '100')) return;
                if (!hasDot && intStr.length === 4 && parseInt(intStr, 10) >= 2020 && parseInt(intStr, 10) <= 2032) return;

                var val = parseInt(intStr, 10);
                if (!Number.isFinite(val)) return;
                var effectiveVal = (isElec && !hasDot && intStr.length === 6 && intStr.charAt(0) === '0')
                    ? Math.floor(val / 10)
                    : val;

                var conf = (typeof entry.confidence === 'number' && entry.confidence > 0) ? entry.confidence : 78;
                var score = (entry.baseWeight || 10) + conf * 0.35;
                if (hasDot && fracStr.length === 1) score += 52;
                if (intStr.charAt(0) === '0' && intStr.length === 6 && !hasDot) score += 36;
                else if (intStr.charAt(0) === '0' && intStr.length === 5) score += 28;
                if (intStr.length === 5) score += 20;
                if (isElec && prevReading && effectiveVal >= prevReading && effectiveVal <= prevReading + 3000) score += 22;
                if (!isElec && prevReading && val >= prevReading) score += 10;

                candidates.push({
                    rawToken: norm,
                    intVal: val,
                    intStr: intStr,
                    hasDot: hasDot,
                    hasRedBox: !!entry.hasRedBox,
                    confidence: Math.min(99.2, Math.max(68.0, Number(conf))),
                    score: score,
                    source: entry.source || 'Tesseract WASM'
                });
            });
        });

        candidates.sort(function (a, b) { return b.score - a.score; });
        return candidates[0] || null;
    }

    // Bộ giải mã LCD 7 đoạn trực tiếp trên thành phần liên thông (chống lỗi Tesseract nhầm font 7-segment)
    function decodeSevenSegmentFromCanvas(prepCanvas) {
        var w = prepCanvas.width, h = prepCanvas.height;
        var d = prepCanvas.getContext('2d').getImageData(0, 0, w, h).data;
        var bin = new Uint8Array(w * h);
        for (var i = 0; i < w * h; i++) {
            bin[i] = d[i * 4] < 128 ? 1 : 0;
        }

        var visited = new Uint8Array(w * h);
        var blobs = [];
        var dots = [];

        for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
                var s = y * w + x;
                if (!bin[s] || visited[s]) continue;
                var stack = [s];
                visited[s] = 1;
                var area = 0, minX = x, maxX = x, minY = y, maxY = y;
                while (stack.length) {
                    var cur = stack.pop();
                    area++;
                    var cx = cur % w, cy = (cur / w) | 0;
                    if (cx < minX) minX = cx;
                    if (cx > maxX) maxX = cx;
                    if (cy < minY) minY = cy;
                    if (cy > maxY) maxY = cy;
                    if (cx > 0 && bin[cur - 1] && !visited[cur - 1]) { visited[cur - 1] = 1; stack.push(cur - 1); }
                    if (cx + 1 < w && bin[cur + 1] && !visited[cur + 1]) { visited[cur + 1] = 1; stack.push(cur + 1); }
                    if (cy > 0 && bin[cur - w] && !visited[cur - w]) { visited[cur - w] = 1; stack.push(cur - w); }
                    if (cy + 1 < h && bin[cur + w] && !visited[cur + w]) { visited[cur + w] = 1; stack.push(cur + w); }
                }
                var cw = maxX - minX + 1, ch = maxY - minY + 1;
                if (ch >= h * 0.24 && cw <= w * 0.25 && area >= h * 1.4) {
                    blobs.push({ minX: minX, maxX: maxX, minY: minY, maxY: maxY, cw: cw, ch: ch, area: area });
                } else if (cw <= h * 0.14 && ch <= h * 0.14 && area >= 6) {
                    dots.push({ cx: (minX + maxX) * 0.5, cy: (minY + maxY) * 0.5, maxY: maxY });
                }
            }
        }

        var wide = blobs.filter(function (b) { return b.cw >= h * 0.12; });
        if (wide.length < 3) return null;

        var sortedH = wide.map(function (b) { return b.ch; }).sort(function (a, b) { return a - b; });
        var sortedMaxY = wide.map(function (b) { return b.maxY; }).sort(function (a, b) { return a - b; });
        var medH = sortedH[Math.floor(sortedH.length / 2)];
        var medMaxY = sortedMaxY[Math.floor(sortedMaxY.length / 2)];

        var aligned = blobs.filter(function (b) {
            return b.ch >= medH * 0.70 && b.ch <= medH * 1.32 && Math.abs(b.maxY - medMaxY) <= medH * 0.22;
        });
        aligned.sort(function (a, b) { return a.minX - b.minX; });
        if (aligned.length < 4) return null;

        // Lọc giữ cụm dãy số liên tiếp chính (bỏ nhiễu quá xa 2 đầu)
        var core = [aligned[0]];
        var clusters = [];
        for (var ai = 1; ai < aligned.length; ai++) {
            var gap = aligned[ai].minX - aligned[ai - 1].maxX;
            if (gap <= medH * 1.15) {
                core.push(aligned[ai]);
            } else {
                clusters.push(core);
                core = [aligned[ai]];
            }
        }
        clusters.push(core);
        clusters.sort(function (a, b) { return b.length - a.length; });
        var digits = clusters[0];
        if (!digits || digits.length < 4) return null;

        var templates = {
            '0': [1, 1, 1, 1, 1, 1, 0],
            '2': [1, 1, 0, 1, 1, 0, 1],
            '3': [1, 1, 1, 1, 0, 0, 1],
            '4': [0, 1, 1, 0, 0, 1, 1],
            '5': [1, 0, 1, 1, 0, 1, 1],
            '6': [1, 0, 1, 1, 1, 1, 1],
            '7': [1, 1, 1, 0, 0, 0, 0],
            '8': [1, 1, 1, 1, 1, 1, 1],
            '9': [1, 1, 1, 1, 0, 1, 1]
        };

        function segFill(b, rx0, rx1, ry0, ry1) {
            var x0 = b.minX + Math.floor(rx0 * b.cw);
            var x1 = Math.min(b.maxX, b.minX + Math.ceil(rx1 * b.cw) - 1);
            var y0 = b.minY + Math.floor(ry0 * b.ch);
            var y1 = Math.min(b.maxY, b.minY + Math.ceil(ry1 * b.ch) - 1);
            var cnt = 0, tot = 0;
            for (var py = y0; py <= y1; py++) {
                for (var px = x0; px <= x1; px++) {
                    tot++;
                    if (bin[py * w + px]) cnt++;
                }
            }
            return tot ? (cnt / tot) : 0;
        }

        var out = '';
        var confSum = 0;
        for (var di = 0; di < digits.length; di++) {
            var b = digits[di];
            if (b.cw / b.ch < 0.34) {
                out += '1';
                confSum += 92;
                continue;
            }
            var vec = [
                segFill(b, 0.34, 0.66, 0.00, 0.22), // A top (tránh chồng nét dọc trái/phải của số 0)
                segFill(b, 0.72, 1.00, 0.14, 0.46), // B top-right
                segFill(b, 0.72, 1.00, 0.54, 0.86), // C bot-right
                segFill(b, 0.34, 0.66, 0.78, 1.00), // D bottom
                segFill(b, 0.00, 0.28, 0.54, 0.86), // E bot-left
                segFill(b, 0.00, 0.28, 0.14, 0.46), // F top-left
                segFill(b, 0.35, 0.65, 0.40, 0.60)  // G middle (chỉ đo phần ruột giữa chữ số)
            ];

            var bestCh = '8';
            var bestScore = -1e9;
            var keys = Object.keys(templates);
            for (var ki = 0; ki < keys.length; ki++) {
                var k = keys[ki];
                var tpl = templates[k];
                var sc = 0;
                for (var si = 0; si < 7; si++) {
                    var diff = (vec[si] - 0.30);
                    sc += tpl[si] ? diff : -diff;
                }
                if (sc > bestScore) {
                    bestScore = sc;
                    bestCh = k;
                }
            }
            out += bestCh;
            confSum += Math.min(95, Math.max(72, 74 + bestScore * 8));
        }

        // Kiểm tra dấu chấm thập phân giữa 2 chữ số cuối (vd 01548.5)
        if (digits.length >= 5) {
            var prevB = digits[digits.length - 2];
            var lastB = digits[digits.length - 1];
            var hasDecDot = dots.some(function (pt) {
                return pt.cx > prevB.maxX - 4 && pt.cx < lastB.minX + 4 && pt.maxY >= medMaxY - medH * 0.28;
            });
            if (hasDecDot) {
                out = out.slice(0, -1) + '.' + out.slice(-1);
            }
        }

        return {
            text: out,
            confidence: confSum / digits.length
        };
    }

    async function runClientVisionOcr(dataUrl, meterType, previousReading) {
        var img = await loadImage(dataUrl);
        var maxW = 960;
        var scaleDown = img.width > maxW ? (maxW / img.width) : 1;
        var baseCanvas = makeCanvas(img.width * scaleDown, img.height * scaleDown);
        baseCanvas.getContext('2d').drawImage(img, 0, 0, baseCanvas.width, baseCanvas.height);

        var worker = await getOcrWorker();
        var rois = meterType === 'water'
            ? findWaterCounterRois(baseCanvas)
            : findElectricLcdRois(baseCanvas);

        var collected = [];
        for (var i = 0; i < rois.length; i++) {
            var roi = rois[i];
            var prep = meterType === 'water'
                ? preprocessMechanicalWaterWindow(roi.canvas)
                : preprocessElectricRoi(roi.canvas, { scale: 3.6, closeGap: true, threshShift: 4 });

            if (meterType === 'electric') {
                var seg7 = decodeSevenSegmentFromCanvas(prep);
                if (seg7 && seg7.text) {
                    collected.push({
                        text: seg7.text,
                        confidence: seg7.confidence,
                        baseWeight: roi.name.indexOf('detected') !== -1 ? 56 : 36,
                        hasRedBox: false,
                        source: '7-Segment Vision (' + roi.name + ')'
                    });
                }
            }

            await worker.setParameters({
                tessedit_char_whitelist: '0123456789.',
                tessedit_pageseg_mode: '7'
            });
            var res7 = await worker.recognize(prep);
            var txt7 = (res7 && res7.data && res7.data.text) ? res7.data.text.trim() : '';
            var conf7 = (res7 && res7.data && typeof res7.data.confidence === 'number') ? res7.data.confidence : 0;
            if (txt7) {
                collected.push({
                    text: txt7,
                    confidence: conf7 > 0 ? conf7 : 80,
                    baseWeight: roi.name.indexOf('detected') !== -1 ? 45 : 22,
                    hasRedBox: !!roi.hasRedBox,
                    source: 'Tesseract PSM7 (' + roi.name + ')'
                });
            }

            if (meterType === 'electric') {
                var prep2 = preprocessElectricRoi(roi.canvas, { scale: 3.6, closeGap: false, threshShift: 0 });
                await worker.setParameters({
                    tessedit_char_whitelist: '0123456789.',
                    tessedit_pageseg_mode: '6'
                });
                var res6 = await worker.recognize(prep2);
                var txt6 = (res6 && res6.data && res6.data.text) ? res6.data.text.trim() : '';
                var conf6 = (res6 && res6.data && typeof res6.data.confidence === 'number') ? res6.data.confidence : 0;
                if (txt6) {
                    collected.push({
                        text: txt6,
                        confidence: conf6 > 0 ? conf6 : 78,
                        baseWeight: roi.name.indexOf('detected') !== -1 ? 42 : 20,
                        hasRedBox: false,
                        source: 'Tesseract PSM6 (' + roi.name + ')'
                    });
                }
            }

            var early = extractBestMeterNumber(collected, meterType, previousReading);
            if (early && early.score >= 110 && early.intStr.length >= 5) {
                break;
            }
        }

        var best = extractBestMeterNumber(collected, meterType, previousReading);
        if (!best) {
            throw new Error('Không đọc rõ dãy số trên mặt đồng hồ. Vui lòng chụp rõ hơn phần ô số.');
        }

        var finalReading = best.intVal;
        var altReading = null;
        var hasRed = false;
        var style = meterType === 'electric' ? 'Công tơ điện tử EVN / Cơ khí' : 'Đồng hồ nước cơ học m³';
        var note = '';

        if (meterType === 'water') {
            var fullFive = best.intVal;
            if (best.hasRedBox && !best.hasDot && (best.intStr.length === 5 || (best.intStr.length === 4 && fullFive >= 1000))) {
                finalReading = parseInt(best.intStr.slice(0, best.intStr.length - 1), 10);
                altReading = fullFive;
                hasRed = true;
                note = 'Đọc thực tế ' + best.rawToken + ': phần nguyên ô đen = ' + finalReading + ' m³ (ô đỏ cuối là số lẻ • bấm chọn ' + altReading + ' nếu tính cả ô đỏ)';
            } else {
                note = 'Đọc thực tế từ mặt đồng hồ nước: ' + best.rawToken + ' m³';
            }
        } else {
            if (best.hasDot) {
                note = 'Công tơ điện đọc ' + best.rawToken + ' kWh → lấy phần nguyên ' + finalReading + ' kWh';
            } else if (best.intStr.length === 6 && best.intStr.charAt(0) === '0') {
                finalReading = parseInt(best.intStr.slice(0, 5), 10);
                altReading = best.intVal;
                note = 'Đọc dãy số LCD ' + best.rawToken + ' → làm tròn phần nguyên ' + finalReading + ' kWh';
            } else {
                note = 'Đọc chỉ số kWh thực tế từ ảnh: ' + finalReading + ' kWh';
            }
        }

        return {
            success: true,
            provider: 'SmartStay Client AI Vision (Tesseract WASM + Canvas CV)',
            meterType: meterType,
            rawText: best.rawToken,
            reading: finalReading,
            alternativeReading: altReading,
            hasRedDecimalDigit: hasRed,
            meterStyle: style,
            confidence: Number(best.confidence.toFixed(1)),
            note: note
        };
    }

    async function analyzeMeterImage(dataUrl, meterType, previousReading, apiBaseUrl) {
        var cleanType = String(meterType || 'electric').toLowerCase() === 'water' ? 'water' : 'electric';
        var base = String(apiBaseUrl || '').replace(/\/$/, '');
        var endpoint = base ? (base + '/ocr/read-meter') : '/api/ocr/read-meter';

        try {
            var res = await fetch(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    ImageBase64: dataUrl,
                    MeterType: cleanType,
                    PreviousReading: previousReading || null
                })
            });
            if (res.ok) {
                var serverJson = await res.json();
                if (serverJson && serverJson.success && !serverJson.needsClientOcr && typeof serverJson.reading === 'number') {
                    return serverJson;
                }
            }
        } catch (_) { }

        return await runClientVisionOcr(dataUrl, cleanType, previousReading);
    }

    global.SmartStayMeterOcr = {
        analyzeMeterImage: analyzeMeterImage,
        runClientVisionOcr: runClientVisionOcr
    };
})(window);
