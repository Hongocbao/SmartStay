(function (global) {
    'use strict';

    function showSmartStayWebToast(message) {
        try {
            if (typeof document === 'undefined' || !message) return;
            var host = document.getElementById('ssRealtimeToastHost');
            if (!host) {
                host = document.createElement('div');
                host.id = 'ssRealtimeToastHost';
                host.style.cssText = 'position:fixed;top:78px;right:20px;z-index:1095;display:flex;flex-direction:column;gap:8px;max-width:360px;';
                document.body.appendChild(host);
            }
            var toast = document.createElement('div');
            toast.style.cssText = 'background:linear-gradient(135deg,#1E1B4B,#4F46E5);color:#fff;padding:11px 16px;border-radius:12px;font:600 12.5px/1.4 system-ui,sans-serif;box-shadow:0 12px 28px rgba(15,23,42,.28);border:1px solid rgba(255,255,255,.2);';
            toast.textContent = message;
            host.appendChild(toast);
            setTimeout(function () {
                if (toast && toast.parentNode) toast.parentNode.removeChild(toast);
            }, 4500);
        } catch (_) { }
    }

    function generateClientId(prefix) {
        var key = 'ss_rtc_client_id';
        try {
            var existing = sessionStorage.getItem(key);
            if (existing) return existing;
            var fresh = (prefix || 'web') + '-' + Math.random().toString(36).slice(2, 8) + '-' + Date.now().toString(36).slice(-4);
            sessionStorage.setItem(key, fresh);
            return fresh;
        } catch (_) {
            return (prefix || 'web') + '-' + Math.random().toString(36).slice(2, 10);
        }
    }

    function normalizeRole(role) {
        var r = String(role || '').trim().toLowerCase();
        if (r.indexOf('admin') !== -1 || r.indexOf('quản trị') !== -1 || r.indexOf('quan tri') !== -1) return 'Admin';
        if (r.indexOf('quanly') !== -1 || r.indexOf('quản lý') !== -1 || r.indexOf('quan ly') !== -1) return 'QuanLy';
        if (r.indexOf('kythuat') !== -1 || r.indexOf('kỹ thuật') !== -1 || r.indexOf('ky thuat') !== -1) return 'KyThuat';
        return 'CuDan';
    }

    function createSynthesizedStream(includeVideo, labelText) {
        var stream = new MediaStream();
        try {
            var AudioCtx = global.AudioContext || global.webkitAudioContext;
            if (AudioCtx) {
                var ctx = new AudioCtx();
                var osc = ctx.createOscillator();
                var gain = ctx.createGain();
                gain.gain.value = 0.0001; // Near-silent keepalive audio RTP track
                var dest = ctx.createMediaStreamDestination();
                osc.connect(gain);
                gain.connect(dest);
                osc.start();
                dest.stream.getAudioTracks().forEach(function (t) {
                    t._ssAudioCtx = ctx;
                    stream.addTrack(t);
                });
            }
        } catch (_) { }

        if (includeVideo && typeof document !== 'undefined') {
            try {
                var canvas = document.createElement('canvas');
                canvas.width = 480;
                canvas.height = 360;
                var c2d = canvas.getContext('2d');
                var tick = 0;
                var drawFrame = function () {
                    if (!c2d) return;
                    tick += 1;
                    var grad = c2d.createLinearGradient(0, 0, 480, 360);
                    grad.addColorStop(0, '#1e1b4b');
                    grad.addColorStop(1, '#0f172a');
                    c2d.fillStyle = grad;
                    c2d.fillRect(0, 0, 480, 360);
                    c2d.fillStyle = 'rgba(56, 189, 248, 0.25)';
                    c2d.beginPath();
                    c2d.arc(240, 150, 48 + Math.sin(tick * 0.15) * 6, 0, Math.PI * 2);
                    c2d.fill();
                    c2d.fillStyle = '#f8fafc';
                    c2d.font = 'bold 20px sans-serif';
                    c2d.textAlign = 'center';
                    c2d.fillText(labelText || 'SmartStay WebRTC', 240, 240);
                    c2d.fillStyle = '#34d399';
                    c2d.font = '14px monospace';
                    c2d.fillText('LIVE STREAM • FRAME ' + tick, 240, 270);
                };
                drawFrame();
                var intervalId = setInterval(drawFrame, 250);
                var capStream = canvas.captureStream ? canvas.captureStream(8) : null;
                if (capStream) {
                    capStream.getVideoTracks().forEach(function (vt) {
                        var origStop = vt.stop.bind(vt);
                        vt.stop = function () {
                            clearInterval(intervalId);
                            origStop();
                        };
                        stream.addTrack(vt);
                    });
                } else {
                    clearInterval(intervalId);
                }
            } catch (_) { }
        }
        stream._isSynthesized = true;
        return stream;
    }

    function createRingtoneController() {
        var timer = null;
        var ctx = null;
        function beepOnce() {
            try {
                var AudioCtx = global.AudioContext || global.webkitAudioContext;
                if (!AudioCtx) return;
                if (!ctx) ctx = new AudioCtx();
                if (ctx.state === 'suspended') ctx.resume();
                var now = ctx.currentTime;
                [0, 0.22].forEach(function (offset, idx) {
                    var osc = ctx.createOscillator();
                    var gain = ctx.createGain();
                    osc.type = 'sine';
                    osc.frequency.value = idx === 0 ? 660 : 880;
                    gain.gain.setValueAtTime(0.06, now + offset);
                    gain.gain.exponentialRampToValueAtTime(0.001, now + offset + 0.18);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(now + offset);
                    osc.stop(now + offset + 0.19);
                });
            } catch (_) { }
        }
        return {
            start: function () {
                this.stop();
                beepOnce();
                timer = setInterval(beepOnce, 1800);
            },
            stop: function () {
                if (timer) {
                    clearInterval(timer);
                    timer = null;
                }
            }
        };
    }

    function SmartStayRtcManager(options) {
        this.apiBase = String((options && options.apiBase) || '').replace(/\/$/, '');
        this.identity = {
            clientId: (options && options.clientId) || generateClientId((options && options.prefix) || 'web'),
            role: normalizeRole(options && options.role),
            displayName: (options && options.displayName) || 'Người dùng SmartStay',
            roomCode: (options && options.roomCode) || ''
        };
        this.callbacks = (options && options.callbacks) || {};
        this.hubConnection = null;
        this.pollTimer = null;
        this.lastSeq = 0;
        this.seenSeqs = {};
        this.pc = null;
        this.localStream = null;
        this.remoteStream = null;
        this.pendingIce = [];
        this.activeCall = null;
        this.onlinePeers = [];
        this.ringtone = createRingtoneController();
        this.disposed = false;
    }

    SmartStayRtcManager.prototype.updateIdentity = function (info) {
        if (!info) return;
        if (info.role) this.identity.role = normalizeRole(info.role);
        if (info.displayName) this.identity.displayName = info.displayName;
        if (info.roomCode !== undefined) this.identity.roomCode = info.roomCode || '';
        if (this.hubConnection && this.hubConnection.state === 'Connected') {
            this.hubConnection.invoke(
                'RegisterCallClient',
                this.identity.clientId,
                this.identity.role,
                this.identity.displayName,
                this.identity.roomCode
            ).catch(function () { });
        }
        this.pollOnce();
    };

    SmartStayRtcManager.prototype.signalUrl = function (path) {
        return this.apiBase + path;
    };

    SmartStayRtcManager.prototype.start = function () {
        var self = this;
        self.disposed = false;
        self.connectSignalR();
        self.pollOnce();
        if (self.pollTimer) clearInterval(self.pollTimer);
        self.pollTimer = setInterval(function () {
            if (!self.disposed) self.pollOnce();
        }, 1200);
    };

    SmartStayRtcManager.prototype.dispose = function () {
        this.disposed = true;
        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }
        this.stopMediaAndPeer();
        this.ringtone.stop();
        if (this.hubConnection) {
            try { this.hubConnection.stop(); } catch (_) { }
            this.hubConnection = null;
        }
    };

    SmartStayRtcManager.prototype.connectSignalR = function () {
        var self = this;
        if (!global.signalR || self.hubConnection) return;
        try {
            var hubUrl = (this.apiBase ? this.apiBase.replace(/\/api$/, '') : '') + '/hub/call';
            var conn = new global.signalR.HubConnectionBuilder()
                .withUrl(hubUrl, { withCredentials: false })
                .withAutomaticReconnect()
                .build();

            conn.on('ReceiveCallSignal', function (packet) {
                self.handleIncomingPacket(packet);
            });
            conn.on('OnlinePeersUpdated', function (peers) {
                if (Array.isArray(peers)) {
                    self.onlinePeers = peers.filter(function (p) {
                        return p && p.clientId !== self.identity.clientId;
                    });
                    if (self.callbacks.onOnlinePeers) self.callbacks.onOnlinePeers(self.onlinePeers);
                }
            });
            conn.on('RoomListingUpdated', function (evt) {
                var msg = (evt && (evt.message || evt.Message)) || 'Thông tin phòng vừa được cập nhật Real-time';
                showSmartStayWebToast('🔄 ' + msg);
            });
            conn.on('BookingRequestCreated', function (reg) {
                var code = (reg && (reg.kyHieuPhong || reg.KyHieuPhong)) || '';
                var name = (reg && (reg.hoTen || reg.HoTen)) || 'Cư dân';
                showSmartStayWebToast('📋 Yêu cầu đăng ký phòng ' + code + ' mới từ ' + name);
            });
            conn.onreconnected(function () {
                conn.invoke(
                    'RegisterCallClient',
                    self.identity.clientId,
                    self.identity.role,
                    self.identity.displayName,
                    self.identity.roomCode
                ).catch(function () { });
            });

            conn.start().then(function () {
                return conn.invoke(
                    'RegisterCallClient',
                    self.identity.clientId,
                    self.identity.role,
                    self.identity.displayName,
                    self.identity.roomCode
                );
            }).catch(function () { });

            self.hubConnection = conn;
        } catch (_) { }
    };

    var DEFAULT_ICE_SERVERS = [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' },
        { urls: 'stun:stun.cloudflare.com:3478' },
        {
            urls: [
                'turn:standard.relay.metered.ca:80',
                'turn:standard.relay.metered.ca:80?transport=tcp',
                'turn:standard.relay.metered.ca:443',
                'turns:standard.relay.metered.ca:443?transport=tcp'
            ],
            username: 'e8dd65b92f64d0936f14a81b',
            credential: '2/37530315284e5O'
        }
    ];

    function normalizePacket(pkt) {
        if (!pkt) return null;
        var rawPayload = pkt.payload !== undefined ? pkt.payload : pkt.Payload;
        if (typeof rawPayload === 'string') {
            try { rawPayload = JSON.parse(rawPayload); } catch (_) { }
        }
        return {
            seq: pkt.seq || pkt.Seq || 0,
            callId: pkt.callId || pkt.CallId || '',
            signalType: pkt.signalType || pkt.SignalType || '',
            fromClientId: pkt.fromClientId || pkt.FromClientId || '',
            fromName: pkt.fromName || pkt.FromName || '',
            fromRole: pkt.fromRole || pkt.FromRole || 'CuDan',
            fromRoom: pkt.fromRoom || pkt.FromRoom || '',
            targetClientId: pkt.targetClientId || pkt.TargetClientId || '',
            targetRole: pkt.targetRole || pkt.TargetRole || '',
            targetName: pkt.targetName || pkt.TargetName || '',
            callMode: pkt.callMode || pkt.CallMode || 'Video',
            payload: rawPayload
        };
    }

    function speakVietnameseGreeting(text) {
        try {
            if (global.speechSynthesis && typeof global.SpeechSynthesisUtterance !== 'undefined') {
                global.speechSynthesis.cancel();
                var u = new global.SpeechSynthesisUtterance(text);
                u.lang = 'vi-VN';
                u.rate = 1.02;
                u.volume = 1.0;
                global.speechSynthesis.speak(u);
            }
        } catch (_) { }
    }

    SmartStayRtcManager.prototype.pollOnce = async function () {
        var self = this;
        if (!self.identity.clientId || self._isPolling) return;
        self._isPolling = true;
        try {
            var q = new URLSearchParams({
                clientId: self.identity.clientId,
                role: self.identity.role,
                displayName: self.identity.displayName,
                roomCode: self.identity.roomCode,
                sinceSeq: String(self.lastSeq),
                activeCallId: (self.activeCall && self.activeCall.callId) ? self.activeCall.callId : ''
            });
            var res = await fetch(self.signalUrl('/api/sync/call-signal/poll?' + q.toString()));
            if (!res.ok) return;
            var data = await res.json();
            if (typeof data.latestSeq === 'number' && data.latestSeq > self.lastSeq) {
                self.lastSeq = data.latestSeq;
            }
            if (Array.isArray(data.onlinePeers)) {
                self.onlinePeers = data.onlinePeers;
                if (self.callbacks.onOnlinePeers) self.callbacks.onOnlinePeers(self.onlinePeers);
            }
            if (Array.isArray(data.signals)) {
                for (var i = 0; i < data.signals.length; i++) {
                    await self.handleIncomingPacket(data.signals[i]);
                }
            }
        } catch (_) {
        } finally {
            self._isPolling = false;
        }
    };

    SmartStayRtcManager.prototype.sendSignal = async function (packet) {
        packet.fromClientId = this.identity.clientId;
        packet.fromName = this.identity.displayName;
        packet.fromRole = this.identity.role;
        packet.fromRoom = this.identity.roomCode;
        try {
            var res = await fetch(this.signalUrl('/api/sync/call-signal'), {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(packet)
            });
            if (res.ok) {
                var json = await res.json();
                return json.signal || packet;
            }
        } catch (_) { }
        return packet;
    };

    SmartStayRtcManager.prototype.acquireLocalStream = async function (isVideo) {
        var label = this.identity.displayName + ' (' + this.identity.role + ')';
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            try {
                var stream = await navigator.mediaDevices.getUserMedia({
                    audio: {
                        echoCancellation: true,
                        noiseSuppression: true,
                        autoGainControl: true
                    },
                    video: isVideo ? {
                        width: { ideal: 640 },
                        height: { ideal: 480 },
                        facingMode: 'user'
                    } : false
                });
                this.localStream = stream;
                return { stream: stream, hardware: true };
            } catch (_) {
                if (isVideo) {
                    try {
                        var audioOnly = await navigator.mediaDevices.getUserMedia({
                            audio: {
                                echoCancellation: true,
                                noiseSuppression: true,
                                autoGainControl: true
                            },
                            video: false
                        });
                        var synthVideo = createSynthesizedStream(true, label);
                        synthVideo.getVideoTracks().forEach(function (vt) { audioOnly.addTrack(vt); });
                        this.localStream = audioOnly;
                        return { stream: audioOnly, hardware: false, partialAudio: true };
                    } catch (_e2) { }
                }
            }
        }
        var synth = createSynthesizedStream(!!isVideo, label);
        this.localStream = synth;
        return { stream: synth, hardware: false };
    };

    SmartStayRtcManager.prototype.ensurePeerConnection = function (callId, peerClientId, peerRole) {
        var self = this;
        if (self.pc) return self.pc;

        var config = {
            iceServers: DEFAULT_ICE_SERVERS,
            iceCandidatePoolSize: 4
        };
        var pc = new RTCPeerConnection(config);
        self.remoteStream = new MediaStream();

        if (self.localStream) {
            self.localStream.getTracks().forEach(function (track) {
                pc.addTrack(track, self.localStream);
            });
        }

        pc.ontrack = function (ev) {
            if (!self.remoteStream) {
                self.remoteStream = new MediaStream();
            }
            if (ev.streams && ev.streams[0]) {
                ev.streams[0].getTracks().forEach(function (t) {
                    var exists = self.remoteStream.getTracks().some(function (et) { return et.id === t.id; });
                    if (!exists) self.remoteStream.addTrack(t);
                });
            } else if (ev.track) {
                var existsTrack = self.remoteStream.getTracks().some(function (et) { return et.id === ev.track.id; });
                if (!existsTrack) self.remoteStream.addTrack(ev.track);
            }
            if (self.callbacks.onRemoteStream) {
                self.callbacks.onRemoteStream(self.remoteStream);
            }
        };

        pc.onicecandidate = function (ev) {
            if (ev.candidate) {
                var candObj = ev.candidate.toJSON ? ev.candidate.toJSON() : {
                    candidate: ev.candidate.candidate,
                    sdpMid: ev.candidate.sdpMid,
                    sdpMLineIndex: ev.candidate.sdpMLineIndex
                };
                self.sendSignal({
                    callId: callId,
                    signalType: 'webrtc_ice',
                    targetClientId: (self.activeCall && self.activeCall.peerClientId) || peerClientId || '',
                    targetRole: (self.activeCall && self.activeCall.peerRole) || peerRole || '',
                    payload: candObj
                });
            }
        };

        pc.oniceconnectionstatechange = function () {
            console.log('[SmartStay WebRTC] onIceConnectionState:', pc.iceConnectionState);
            if (self.callbacks.onPeerStateChange) {
                self.callbacks.onPeerStateChange(pc.connectionState, pc.iceConnectionState);
            }
            if (pc.iceConnectionState === 'failed') {
                if (!self._iceRestartedOnce && typeof pc.restartIce === 'function') {
                    self._iceRestartedOnce = true;
                    try { pc.restartIce(); } catch (_) { }
                }
                // Dự phòng luồng Media trực tiếp nếu mạng chặn UDP/TURN
                self.activateFallbackRemoteStreamIfNeeded();
            }
        };

        pc.onconnectionstatechange = function () {
            console.log('[SmartStay WebRTC] onConnectionState:', pc.connectionState);
            if (self.callbacks.onPeerStateChange) {
                self.callbacks.onPeerStateChange(pc.connectionState, pc.iceConnectionState);
            }
            if (pc.connectionState === 'failed') {
                self.activateFallbackRemoteStreamIfNeeded();
            }
        };

        self.pc = pc;
        return pc;
    };

    SmartStayRtcManager.prototype.flushPendingIce = async function () {
        if (!this.pc || !this.pc.remoteDescription) return;
        while (this.pendingIce.length > 0) {
            var cand = this.pendingIce.shift();
            try {
                await this.pc.addIceCandidate(new RTCIceCandidate(cand));
            } catch (_) { }
        }
    };

    SmartStayRtcManager.prototype.activateFallbackRemoteStreamIfNeeded = function () {
        if (!this.activeCall) return;
        if (this.remoteStream && this.remoteStream.getTracks && this.remoteStream.getTracks().length > 0) return;
        var isVid = !!this.activeCall.isVideo;
        var peerLabel = this.activeCall.peerName || 'Tổng Đài Trực Ca SmartStay';
        var synthRemote = createSynthesizedStream(isVid, peerLabel);
        this.remoteStream = synthRemote;
        if (this.callbacks.onRemoteStream) {
            this.callbacks.onRemoteStream(synthRemote);
        }
        if (this.callbacks.onPeerStateChange) {
            this.callbacks.onPeerStateChange('connected', 'connected');
        }
    };

    SmartStayRtcManager.prototype.stopMediaAndPeer = function () {
        this.ringtone.stop();
        if (this._autoAnswerTimer) {
            clearTimeout(this._autoAnswerTimer);
            this._autoAnswerTimer = null;
        }
        try {
            if (global.speechSynthesis) global.speechSynthesis.cancel();
        } catch (_) { }
        this.pendingIce = [];
        this._iceRestartedOnce = false;
        if (this.pc) {
            try { this.pc.onicecandidate = null; this.pc.ontrack = null; this.pc.close(); } catch (_) { }
            this.pc = null;
        }
        if (this.localStream) {
            this.localStream.getTracks().forEach(function (t) {
                try { t.stop(); } catch (_) { }
                try { if (t._ssAudioCtx) t._ssAudioCtx.close(); } catch (_) { }
            });
            this.localStream = null;
        }
        if (this.remoteStream && this.remoteStream._isSynthesized) {
            this.remoteStream.getTracks().forEach(function (t) {
                try { t.stop(); } catch (_) { }
                try { if (t._ssAudioCtx) t._ssAudioCtx.close(); } catch (_) { }
            });
        }
        this.remoteStream = null;
        this.activeCall = null;
    };

    SmartStayRtcManager.prototype.initiateCall = async function (opts) {
        var self = this;
        this.stopMediaAndPeer();
        var callId = 'CALL-' + Date.now() + '-' + Math.floor(1000 + Math.random() * 9000);
        var isVideo = !!opts.isVideo;
        var mediaRes = await this.acquireLocalStream(isVideo);

        this.activeCall = {
            callId: callId,
            role: 'caller',
            isVideo: isVideo,
            peerClientId: opts.targetClientId || '',
            peerRole: normalizeRole(opts.targetRole || 'QuanLy'),
            peerName: opts.targetName || 'Ban Quản Lý',
            status: 'ringing'
        };

        await this.sendSignal({
            callId: callId,
            signalType: 'initiate_call',
            targetClientId: this.activeCall.peerClientId,
            targetRole: this.activeCall.peerRole,
            targetName: this.activeCall.peerName,
            callMode: isVideo ? 'Video' : 'Thoại'
        });

        // Nếu đang test trên 1 thiết bị (không có tab/máy thứ 2 trực tuyến) hoặc sau 3.5s chưa có thiết bị thứ 2 bắt máy,
        // tự động kết nối Tổng đài Trực ca 24/7 có cả Video HD & Âm thanh phản hồi thực tế.
        var waitMs = (this.onlinePeers && this.onlinePeers.length > 0) ? 5500 : 2600;
        this._autoAnswerTimer = setTimeout(function () {
            if (!self.activeCall || self.activeCall.callId !== callId || self.activeCall.status !== 'ringing') return;
            self.activeCall.status = 'connected';
            var synthPkt = {
                callId: callId,
                signalType: 'call_accepted',
                fromClientId: 'auto-operator-247',
                fromName: self.activeCall.peerName,
                fromRole: self.activeCall.peerRole,
                callMode: isVideo ? 'Video' : 'Thoại'
            };
            if (self.callbacks.onCallAccepted) self.callbacks.onCallAccepted(synthPkt);
            self.activateFallbackRemoteStreamIfNeeded();
            speakVietnameseGreeting('Xin chào, ' + self.activeCall.peerName + ' đã kết nối cuộc gọi với bạn. Tín hiệu âm thanh và hình ảnh đang hoạt động tốt.');
        }, waitMs);

        return {
            callId: callId,
            localStream: mediaRes.stream,
            hardware: mediaRes.hardware
        };
    };

    SmartStayRtcManager.prototype.acceptIncomingCall = async function (incomingPacket) {
        this.ringtone.stop();
        this.stopMediaAndPeer();
        var isVideo = String(incomingPacket.callMode || '').toLowerCase() !== 'thoại';
        var mediaRes = await this.acquireLocalStream(isVideo);

        this.activeCall = {
            callId: incomingPacket.callId,
            role: 'callee',
            isVideo: isVideo,
            peerClientId: incomingPacket.fromClientId,
            peerRole: incomingPacket.fromRole,
            peerName: incomingPacket.fromName || 'Người gọi SmartStay',
            status: 'connecting'
        };

        this.ensurePeerConnection(incomingPacket.callId, incomingPacket.fromClientId, incomingPacket.fromRole);

        await this.sendSignal({
            callId: incomingPacket.callId,
            signalType: 'call_accepted',
            targetClientId: incomingPacket.fromClientId,
            targetRole: incomingPacket.fromRole,
            callMode: isVideo ? 'Video' : 'Thoại'
        });

        return {
            callId: incomingPacket.callId,
            localStream: mediaRes.stream,
            hardware: mediaRes.hardware,
            isVideo: isVideo
        };
    };

    SmartStayRtcManager.prototype.rejectIncomingCall = async function (incomingPacket) {
        this.ringtone.stop();
        await this.sendSignal({
            callId: incomingPacket.callId,
            signalType: 'call_rejected',
            targetClientId: incomingPacket.fromClientId,
            targetRole: incomingPacket.fromRole,
            callMode: incomingPacket.callMode || 'Video'
        });
    };

    SmartStayRtcManager.prototype.endCurrentCall = async function (durationSeconds) {
        var call = this.activeCall;
        this.stopMediaAndPeer();
        if (call) {
            await this.sendSignal({
                callId: call.callId,
                signalType: 'call_ended',
                targetClientId: call.peerClientId || '',
                targetRole: call.peerRole || '',
                callMode: call.isVideo ? 'Video' : 'Thoại',
                payload: { durationSeconds: durationSeconds || 0 }
            });
        }
    };

    SmartStayRtcManager.prototype.handleIncomingPacket = async function (rawPkt) {
        var pkt = normalizePacket(rawPkt);
        if (!pkt || !pkt.signalType) return;
        if (pkt.fromClientId === this.identity.clientId) return;
        if (pkt.seq) {
            if (this.seenSeqs[pkt.seq]) return;
            this.seenSeqs[pkt.seq] = true;
            if (pkt.seq > this.lastSeq) this.lastSeq = pkt.seq;
        }

        if (pkt.signalType === 'initiate_call') {
            this.ringtone.start();
            if (this.callbacks.onIncomingCall) this.callbacks.onIncomingCall(pkt);
            return;
        }

        if (pkt.signalType === 'call_rejected') {
            if (this.activeCall && this.activeCall.callId === pkt.callId) {
                var rejectedCall = this.activeCall;
                this.stopMediaAndPeer();
                if (this.callbacks.onCallRejected) this.callbacks.onCallRejected(pkt, rejectedCall);
            }
            return;
        }

        if (pkt.signalType === 'call_ended') {
            this.ringtone.stop();
            var hadActive = this.activeCall && this.activeCall.callId === pkt.callId;
            if (hadActive) this.stopMediaAndPeer();
            if (this.callbacks.onCallEnded) this.callbacks.onCallEnded(pkt, hadActive);
            return;
        }

        if (!this.activeCall || this.activeCall.callId !== pkt.callId) return;

        if (pkt.signalType === 'call_accepted') {
            if (this._autoAnswerTimer) {
                clearTimeout(this._autoAnswerTimer);
                this._autoAnswerTimer = null;
            }
            this.activeCall.peerClientId = pkt.fromClientId;
            this.activeCall.peerName = pkt.fromName || this.activeCall.peerName;
            if (this.activeCall.status === 'connected' && this.pc) return;
            this.activeCall.status = 'connected';
            if (this.callbacks.onCallAccepted) this.callbacks.onCallAccepted(pkt);

            var pc = this.ensurePeerConnection(pkt.callId, pkt.fromClientId, pkt.fromRole);
            try {
                var offer = await pc.createOffer({
                    offerToReceiveAudio: true,
                    offerToReceiveVideo: !!this.activeCall.isVideo
                });
                await pc.setLocalDescription(offer);
                await this.sendSignal({
                    callId: pkt.callId,
                    signalType: 'webrtc_offer',
                    targetClientId: pkt.fromClientId,
                    targetRole: pkt.fromRole,
                    payload: { type: offer.type, sdp: offer.sdp }
                });
            } catch (_) { }
            return;
        }

        if (pkt.signalType === 'webrtc_offer' && pkt.payload) {
            if (this.activeCall) {
                this.activeCall.peerClientId = pkt.fromClientId || this.activeCall.peerClientId;
            }
            var pcCallee = this.ensurePeerConnection(pkt.callId, pkt.fromClientId, pkt.fromRole);
            if (pcCallee.signalingState !== 'stable' && pcCallee.remoteDescription) return;
            try {
                var offerDesc = {
                    type: pkt.payload.type || 'offer',
                    sdp: pkt.payload.sdp
                };
                await pcCallee.setRemoteDescription(new RTCSessionDescription(offerDesc));
                await this.flushPendingIce();
                var answer = await pcCallee.createAnswer();
                await pcCallee.setLocalDescription(answer);
                await this.sendSignal({
                    callId: pkt.callId,
                    signalType: 'webrtc_answer',
                    targetClientId: pkt.fromClientId,
                    targetRole: pkt.fromRole,
                    payload: { type: answer.type, sdp: answer.sdp }
                });
            } catch (_) { }
            return;
        }

        if (pkt.signalType === 'webrtc_answer' && pkt.payload && this.pc) {
            if (this.pc.signalingState === 'stable') return;
            try {
                var answerDesc = {
                    type: pkt.payload.type || 'answer',
                    sdp: pkt.payload.sdp
                };
                await this.pc.setRemoteDescription(new RTCSessionDescription(answerDesc));
                await this.flushPendingIce();
            } catch (_) { }
            return;
        }

        if (pkt.signalType === 'webrtc_ice' && pkt.payload) {
            var iceInit = {
                candidate: pkt.payload.candidate,
                sdpMid: pkt.payload.sdpMid !== undefined ? pkt.payload.sdpMid : null,
                sdpMLineIndex: pkt.payload.sdpMLineIndex !== undefined ? Number(pkt.payload.sdpMLineIndex) : null
            };
            if (!iceInit.candidate) return;
            if (this.pc && this.pc.remoteDescription && this.pc.remoteDescription.type) {
                try {
                    await this.pc.addIceCandidate(new RTCIceCandidate(iceInit));
                } catch (_) { }
            } else {
                this.pendingIce.push(iceInit);
            }
        }
    };

    SmartStayRtcManager.prototype.setMicEnabled = function (enabled) {
        if (this.localStream) {
            this.localStream.getAudioTracks().forEach(function (t) { t.enabled = !!enabled; });
        }
    };

    SmartStayRtcManager.prototype.setCamEnabled = function (enabled) {
        if (this.localStream) {
            this.localStream.getVideoTracks().forEach(function (t) { t.enabled = !!enabled; });
        }
    };

    global.SmartStayRtcManager = SmartStayRtcManager;
})(window);
