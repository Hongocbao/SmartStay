(function (global) {
    'use strict';

    var ringTimer = null;
    var ringCtx = null;
    var pc = null;
    var localStream = null;
    var remoteStream = null;
    var pendingIce = [];
    var activeMeta = null;
    var dockEl = null;

    function beepOnce() {
        try {
            var AudioCtx = global.AudioContext || global.webkitAudioContext;
            if (!AudioCtx) return;
            if (!ringCtx) ringCtx = new AudioCtx();
            if (ringCtx.state === 'suspended') ringCtx.resume();
            var now = ringCtx.currentTime;
            [0, 0.22].forEach(function (offset, idx) {
                var osc = ringCtx.createOscillator();
                var gain = ringCtx.createGain();
                osc.type = 'sine';
                osc.frequency.value = idx === 0 ? 660 : 880;
                gain.gain.setValueAtTime(0.06, now + offset);
                gain.gain.exponentialRampToValueAtTime(0.001, now + offset + 0.18);
                osc.connect(gain);
                gain.connect(ringCtx.destination);
                osc.start(now + offset);
                osc.stop(now + offset + 0.19);
            });
        } catch (_) { }
    }

    function createSynthesizedStream(includeVideo, labelText) {
        var stream = new MediaStream();
        try {
            var AudioCtx = global.AudioContext || global.webkitAudioContext;
            if (AudioCtx) {
                var ctx = new AudioCtx();
                var osc = ctx.createOscillator();
                var gain = ctx.createGain();
                gain.gain.value = 0.0001;
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
                    c2d.fillText(labelText || 'SmartStay Flutter WebRTC', 240, 240);
                    c2d.fillStyle = '#34d399';
                    c2d.font = '14px monospace';
                    c2d.fillText('LIVE STREAM • FRAME ' + tick, 240, 270);
                };
                drawFrame();
                var intervalId = setInterval(drawFrame, 250);
                var cap = canvas.captureStream ? canvas.captureStream(8) : null;
                if (cap) {
                    cap.getVideoTracks().forEach(function (vt) {
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

    function ensureVideoDock(showVideo) {
        if (typeof document === 'undefined') return null;
        if (!dockEl) {
            dockEl = document.createElement('div');
            dockEl.id = 'ssFlutterRtcVideoDock';
            dockEl.style.cssText = 'position:fixed;bottom:84px;left:18px;z-index:99999;background:#0f172a;border:2px solid #38bdf8;border-radius:14px;padding:6px;box-shadow:0 12px 32px rgba(2,6,23,.45);display:none;flex-direction:column;gap:4px;width:240px;';
            dockEl.innerHTML =
                '<div style="display:flex;justify-content:space-between;align-items:center;color:#e2e8f0;font:600 11px sans-serif;padding:0 4px;">' +
                '<span>WebRTC Live Feed</span><span id="ssFltRtcBadge" style="color:#34d399;">● LIVE</span></div>' +
                '<div style="position:relative;width:100%;height:145px;background:#020617;border-radius:10px;overflow:hidden;">' +
                '<video id="ssFltRemoteVideo" autoplay playsinline style="width:100%;height:100%;object-fit:cover;"></video>' +
                '<video id="ssFltLocalVideo" autoplay muted playsinline style="position:absolute;right:6px;bottom:6px;width:66px;height:48px;object-fit:cover;border-radius:6px;border:1px solid #fff;background:#1e293b;"></video>' +
                '<audio id="ssFltRemoteAudio" autoplay></audio>' +
                '</div>';
            document.body.appendChild(dockEl);
        }
        dockEl.style.display = showVideo ? 'flex' : 'none';
        return dockEl;
    }

    async function postSignal(payload) {
        if (!activeMeta || !activeMeta.apiBase) return;
        var url = String(activeMeta.apiBase).replace(/\/$/, '') + '/sync/call-signal';
        try {
            await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
        } catch (_) { }
    }

    function createPeerConnection() {
        if (pc) {
            try { pc.onicecandidate = null; pc.ontrack = null; pc.close(); } catch (_) { }
            pc = null;
        }
        pc = new RTCPeerConnection({
            iceServers: [
                { urls: 'stun:stun.l.google.com:19302' },
                { urls: 'stun:stun1.l.google.com:19302' },
                { urls: 'stun:stun2.l.google.com:19302' },
                { urls: 'stun:stun.cloudflare.com:3478' },
                {
                    urls: [
                        'turn:openrelay.metered.ca:80',
                        'turn:openrelay.metered.ca:443',
                        'turn:openrelay.metered.ca:443?transport=tcp'
                    ],
                    username: 'openrelayproject',
                    credential: 'openrelayproject'
                },
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
            ],
            iceCandidatePoolSize: 4
        });
        remoteStream = new MediaStream();
        if (localStream) {
            localStream.getTracks().forEach(function (track) {
                pc.addTrack(track, localStream);
            });
        }

        pc.ontrack = function (ev) {
            var incoming = (ev.streams && ev.streams[0]) ? ev.streams[0] : null;
            if (incoming) {
                remoteStream = incoming;
            } else if (ev.track) {
                remoteStream.addTrack(ev.track);
            }
            var dock = ensureVideoDock(activeMeta ? !!activeMeta.isVideo : true);
            if (dock) {
                var rVid = document.getElementById('ssFltRemoteVideo');
                var rAud = document.getElementById('ssFltRemoteAudio');
                if (rVid) {
                    rVid.srcObject = remoteStream;
                    rVid.play().catch(function () { });
                }
                if (rAud) {
                    rAud.srcObject = remoteStream;
                    rAud.play().catch(function () { });
                }
            }
        };

        pc.onicecandidate = function (ev) {
            if (ev.candidate && activeMeta) {
                postSignal({
                    callId: activeMeta.callId,
                    signalType: 'webrtc_ice',
                    fromClientId: activeMeta.fromClientId,
                    fromName: activeMeta.fromName,
                    fromRole: activeMeta.fromRole,
                    targetClientId: activeMeta.peerClientId || '',
                    targetRole: activeMeta.peerRole || '',
                    payload: ev.candidate.toJSON ? ev.candidate.toJSON() : ev.candidate
                });
            }
        };

        pc.onconnectionstatechange = function () {
            var badge = document.getElementById('ssFltRtcBadge');
            if (badge && pc) {
                badge.textContent = '● ' + String(pc.connectionState || 'live').toUpperCase();
            }
        };

        return pc;
    }

    async function flushIce() {
        if (!pc || !pc.remoteDescription) return;
        while (pendingIce.length > 0) {
            var cand = pendingIce.shift();
            try {
                await pc.addIceCandidate(new RTCIceCandidate(cand));
            } catch (_) { }
        }
    }

    global.SmartStayFlutterWebRTC = {
        startRingtone: function () {
            this.stopRingtone();
            beepOnce();
            ringTimer = setInterval(beepOnce, 1800);
        },
        stopRingtone: function () {
            if (ringTimer) {
                clearInterval(ringTimer);
                ringTimer = null;
            }
        },
        prepareLocalMedia: async function (isVideo, labelText) {
            this.stopMediaOnly();
            var hardware = false;
            if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                try {
                    localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: !!isVideo });
                    hardware = true;
                } catch (_) {
                    localStream = createSynthesizedStream(!!isVideo, labelText);
                }
            } else {
                localStream = createSynthesizedStream(!!isVideo, labelText);
            }
            var dock = ensureVideoDock(!!isVideo);
            if (dock && isVideo) {
                var lVid = document.getElementById('ssFltLocalVideo');
                if (lVid) {
                    lVid.srcObject = localStream;
                    lVid.play().catch(function () { });
                }
            }
            return hardware;
        },
        startCallerPeer: async function (metaJson) {
            var meta = typeof metaJson === 'string' ? JSON.parse(metaJson) : metaJson;
            activeMeta = meta;
            if (!localStream) {
                await this.prepareLocalMedia(!!meta.isVideo, meta.fromName);
            }
            ensureVideoDock(!!meta.isVideo);
            var peer = createPeerConnection();
            try {
                var offer = await peer.createOffer();
                await peer.setLocalDescription(offer);
                await postSignal({
                    callId: meta.callId,
                    signalType: 'webrtc_offer',
                    fromClientId: meta.fromClientId,
                    fromName: meta.fromName,
                    fromRole: meta.fromRole,
                    targetClientId: meta.peerClientId || '',
                    targetRole: meta.peerRole || '',
                    payload: { type: offer.type, sdp: offer.sdp }
                });
            } catch (_) { }
        },
        startCalleePeer: async function (metaJson) {
            var meta = typeof metaJson === 'string' ? JSON.parse(metaJson) : metaJson;
            activeMeta = meta;
            if (!localStream) {
                await this.prepareLocalMedia(!!meta.isVideo, meta.fromName);
            }
            ensureVideoDock(!!meta.isVideo);
            createPeerConnection();
        },
        handleRemoteSignal: async function (pktJson) {
            var pkt = typeof pktJson === 'string' ? JSON.parse(pktJson) : pktJson;
            if (!pkt || !activeMeta || pkt.callId !== activeMeta.callId) return;
            if (pkt.signalType === 'webrtc_offer' && pkt.payload) {
                var peer = pc || createPeerConnection();
                try {
                    await peer.setRemoteDescription(new RTCSessionDescription(pkt.payload));
                    await flushIce();
                    var answer = await peer.createAnswer();
                    await peer.setLocalDescription(answer);
                    await postSignal({
                        callId: activeMeta.callId,
                        signalType: 'webrtc_answer',
                        fromClientId: activeMeta.fromClientId,
                        fromName: activeMeta.fromName,
                        fromRole: activeMeta.fromRole,
                        targetClientId: pkt.fromClientId || activeMeta.peerClientId || '',
                        targetRole: pkt.fromRole || activeMeta.peerRole || '',
                        payload: { type: answer.type, sdp: answer.sdp }
                    });
                } catch (_) { }
            } else if (pkt.signalType === 'webrtc_answer' && pkt.payload && pc) {
                try {
                    await pc.setRemoteDescription(new RTCSessionDescription(pkt.payload));
                    await flushIce();
                } catch (_) { }
            } else if (pkt.signalType === 'webrtc_ice' && pkt.payload) {
                if (pc && pc.remoteDescription) {
                    try { await pc.addIceCandidate(new RTCIceCandidate(pkt.payload)); } catch (_) { }
                } else {
                    pendingIce.push(pkt.payload);
                }
            }
        },
        setMic: function (enabled) {
            if (localStream) {
                localStream.getAudioTracks().forEach(function (t) { t.enabled = !!enabled; });
            }
        },
        setCam: function (enabled) {
            if (localStream) {
                localStream.getVideoTracks().forEach(function (t) { t.enabled = !!enabled; });
            }
        },
        stopMediaOnly: function () {
            if (localStream) {
                localStream.getTracks().forEach(function (t) {
                    try { t.stop(); } catch (_) { }
                    try { if (t._ssAudioCtx) t._ssAudioCtx.close(); } catch (_) { }
                });
                localStream = null;
            }
        },
        hangup: function () {
            this.stopRingtone();
            pendingIce = [];
            activeMeta = null;
            if (pc) {
                try { pc.onicecandidate = null; pc.ontrack = null; pc.close(); } catch (_) { }
                pc = null;
            }
            this.stopMediaOnly();
            remoteStream = null;
            ensureVideoDock(false);
        }
    };
})(window);
