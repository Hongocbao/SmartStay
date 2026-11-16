using System.Collections.Concurrent;
using Microsoft.AspNetCore.SignalR;

namespace SmartStay.Web.Hubs;

public class CallPresenceEntry
{
    public string ClientId { get; set; } = string.Empty;
    public string ConnectionId { get; set; } = string.Empty;
    public string Role { get; set; } = "CuDan";
    public string DisplayName { get; set; } = "Người dùng";
    public string RoomCode { get; set; } = string.Empty;
    public DateTime LastSeenUtc { get; set; } = DateTime.UtcNow;
}

public class CallSignalPacket
{
    public long Seq { get; set; }
    public string CallId { get; set; } = string.Empty;
    public string SignalType { get; set; } = string.Empty; // initiate_call, call_accepted, call_rejected, call_ended, webrtc_offer, webrtc_answer, webrtc_ice
    public string FromClientId { get; set; } = string.Empty;
    public string FromName { get; set; } = string.Empty;
    public string FromRole { get; set; } = "CuDan";
    public string FromRoom { get; set; } = string.Empty;
    public string TargetClientId { get; set; } = string.Empty;
    public string TargetRole { get; set; } = string.Empty;
    public string TargetName { get; set; } = string.Empty;
    public string CallMode { get; set; } = "Video";
    public object? Payload { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public static class CallSignalingEngine
{
    private static long _seqCounter = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
    private static readonly ConcurrentQueue<CallSignalPacket> _signals = new();
    private static readonly ConcurrentDictionary<string, CallPresenceEntry> _presenceByClient = new(StringComparer.OrdinalIgnoreCase);
    private static readonly ConcurrentDictionary<string, List<CallSignalPacket>> _sessionHandshakeCache = new(StringComparer.OrdinalIgnoreCase);

    public static string NormalizeRole(string? rawRole)
    {
        var r = (rawRole ?? string.Empty).Trim().ToLowerInvariant();
        if (r.Contains("admin") || r.Contains("quản trị") || r.Contains("quan tri")) return "Admin";
        if (r.Contains("quanly") || r.Contains("quản lý") || r.Contains("quan ly")) return "QuanLy";
        if (r.Contains("kythuat") || r.Contains("kỹ thuật") || r.Contains("ky thuat")) return "KyThuat";
        return "CuDan";
    }

    public static void UpsertPresence(string? clientId, string? role, string? displayName, string? roomCode, string? connectionId = null)
    {
        if (string.IsNullOrWhiteSpace(clientId)) return;
        var normRole = NormalizeRole(role);
        _presenceByClient.AddOrUpdate(
            clientId.Trim(),
            _ => new CallPresenceEntry
            {
                ClientId = clientId.Trim(),
                ConnectionId = connectionId ?? string.Empty,
                Role = normRole,
                DisplayName = string.IsNullOrWhiteSpace(displayName) ? normRole : displayName.Trim(),
                RoomCode = roomCode?.Trim() ?? string.Empty,
                LastSeenUtc = DateTime.UtcNow
            },
            (_, existing) =>
            {
                existing.Role = normRole;
                if (!string.IsNullOrWhiteSpace(displayName)) existing.DisplayName = displayName.Trim();
                if (!string.IsNullOrWhiteSpace(roomCode)) existing.RoomCode = roomCode.Trim();
                if (!string.IsNullOrWhiteSpace(connectionId)) existing.ConnectionId = connectionId;
                existing.LastSeenUtc = DateTime.UtcNow;
                return existing;
            });
        PruneStalePresence();
    }

    public static void RemoveConnection(string connectionId)
    {
        if (string.IsNullOrWhiteSpace(connectionId)) return;
        foreach (var kv in _presenceByClient)
        {
            if (kv.Value.ConnectionId == connectionId)
            {
                kv.Value.ConnectionId = string.Empty;
            }
        }
    }

    private static void PruneStalePresence()
    {
        var cutoff = DateTime.UtcNow.AddSeconds(-90);
        foreach (var kv in _presenceByClient)
        {
            if (kv.Value.LastSeenUtc < cutoff)
            {
                _presenceByClient.TryRemove(kv.Key, out _);
            }
        }
    }

    public static List<CallPresenceEntry> GetOnlinePeers(string? excludeClientId = null)
    {
        PruneStalePresence();
        return _presenceByClient.Values
            .Where(p => string.IsNullOrWhiteSpace(excludeClientId) || !string.Equals(p.ClientId, excludeClientId, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(p => p.LastSeenUtc)
            .ToList();
    }

    public static long CurrentSeq => Interlocked.Read(ref _seqCounter);

    public static CallSignalPacket EnqueueSignal(CallSignalPacket packet)
    {
        packet.Seq = Interlocked.Increment(ref _seqCounter);
        packet.CreatedAt = DateTime.UtcNow;
        packet.FromRole = NormalizeRole(packet.FromRole);
        if (!string.IsNullOrWhiteSpace(packet.TargetRole))
        {
            packet.TargetRole = NormalizeRole(packet.TargetRole);
        }
        if (string.IsNullOrWhiteSpace(packet.CallId))
        {
            packet.CallId = $"CALL-{packet.Seq}";
        }

        _signals.Enqueue(packet);
        while (_signals.Count > 2000)
        {
            _signals.TryDequeue(out _);
        }

        if (!string.IsNullOrWhiteSpace(packet.CallId))
        {
            var list = _sessionHandshakeCache.GetOrAdd(packet.CallId, _ => new List<CallSignalPacket>());
            lock (list)
            {
                list.Add(packet);
                if (list.Count > 200)
                {
                    list.RemoveAt(0);
                }
            }
            if (_sessionHandshakeCache.Count > 100)
            {
                var oldestKey = _sessionHandshakeCache.Keys.FirstOrDefault();
                if (oldestKey != null) _sessionHandshakeCache.TryRemove(oldestKey, out _);
            }
        }
        return packet;
    }

    public static List<CallSignalPacket> GetSessionHandshakes(string callId, string? excludeClientId = null)
    {
        if (string.IsNullOrWhiteSpace(callId)) return new List<CallSignalPacket>();
        if (_sessionHandshakeCache.TryGetValue(callId, out var list))
        {
            lock (list)
            {
                return list
                    .Where(s => string.IsNullOrWhiteSpace(excludeClientId) || !string.Equals(s.FromClientId, excludeClientId, StringComparison.OrdinalIgnoreCase))
                    .OrderBy(s => s.Seq)
                    .ToList();
            }
        }
        return new List<CallSignalPacket>();
    }

    public static List<CallSignalPacket> PollSignals(string clientId, string? myRole, long sinceSeq)
    {
        var normalizedMyRole = NormalizeRole(myRole);
        var effectiveSince = sinceSeq <= 0
            ? Math.Max(0, CurrentSeq - 50)
            : sinceSeq;

        return _signals
            .Where(s => s.Seq > effectiveSince)
            .Where(s => sinceSeq > 0 || s.CreatedAt >= DateTime.UtcNow.AddSeconds(-45))
            .Where(s => !string.Equals(s.FromClientId, clientId, StringComparison.OrdinalIgnoreCase))
            .Where(s =>
                (!string.IsNullOrWhiteSpace(s.TargetClientId) &&
                 string.Equals(s.TargetClientId, clientId, StringComparison.OrdinalIgnoreCase))
                || (!string.IsNullOrWhiteSpace(s.TargetRole) &&
                    string.Equals(s.TargetRole, normalizedMyRole, StringComparison.OrdinalIgnoreCase))
                || (string.IsNullOrWhiteSpace(s.TargetClientId) && string.IsNullOrWhiteSpace(s.TargetRole)))
            .OrderBy(s => s.Seq)
            .ToList();
    }

    public static async Task BroadcastPacketAsync(IHubClients<IClientProxy> clients, CallSignalPacket packet)
    {
        var eventName = packet.SignalType switch
        {
            "initiate_call" => "IncomingCall",
            "call_accepted" => "CallAccepted",
            "call_rejected" => "CallRejected",
            "call_ended" => "CallEnded",
            "webrtc_offer" or "webrtc_answer" or "webrtc_ice" => "ReceiveWebRtcSignal",
            _ => "ReceiveCallSignal"
        };

        if (!string.IsNullOrWhiteSpace(packet.TargetClientId))
        {
            await clients.Group($"client_{packet.TargetClientId}").SendAsync("ReceiveCallSignal", packet);
            await clients.Group($"client_{packet.TargetClientId}").SendAsync(eventName, packet);
            if (!string.IsNullOrWhiteSpace(packet.TargetRole))
            {
                await clients.Group($"role_{packet.TargetRole}").SendAsync("ReceiveCallSignal", packet);
                await clients.Group($"role_{packet.TargetRole}").SendAsync(eventName, packet);
            }
        }
        else if (!string.IsNullOrWhiteSpace(packet.TargetRole))
        {
            await clients.Group($"role_{packet.TargetRole}").SendAsync("ReceiveCallSignal", packet);
            await clients.Group($"role_{packet.TargetRole}").SendAsync(eventName, packet);
        }
        else
        {
            await clients.All.SendAsync("ReceiveCallSignal", packet);
            await clients.All.SendAsync(eventName, packet);
        }
    }
}

public class SmartStayHub : Hub
{
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        CallSignalingEngine.RemoveConnection(Context.ConnectionId);
        await Clients.All.SendAsync("OnlinePeersUpdated", CallSignalingEngine.GetOnlinePeers());
        await base.OnDisconnectedAsync(exception);
    }

    public async Task RegisterCallClient(string clientId, string role, string displayName, string? roomCode = null)
    {
        var normRole = CallSignalingEngine.NormalizeRole(role);
        CallSignalingEngine.UpsertPresence(clientId, normRole, displayName, roomCode, Context.ConnectionId);
        if (!string.IsNullOrWhiteSpace(clientId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"client_{clientId.Trim()}");
        }
        await Groups.AddToGroupAsync(Context.ConnectionId, $"role_{normRole}");
        await Clients.All.SendAsync("OnlinePeersUpdated", CallSignalingEngine.GetOnlinePeers());
    }

    public async Task DispatchCallSignal(CallSignalPacket packet)
    {
        CallSignalingEngine.UpsertPresence(packet.FromClientId, packet.FromRole, packet.FromName, packet.FromRoom, Context.ConnectionId);
        var saved = CallSignalingEngine.EnqueueSignal(packet);
        await CallSignalingEngine.BroadcastPacketAsync(Clients, saved);
    }

    public Task InitiateCall(CallSignalPacket packet)
    {
        packet.SignalType = "initiate_call";
        return DispatchCallSignal(packet);
    }

    public Task AnswerCall(CallSignalPacket packet)
    {
        packet.SignalType = "call_accepted";
        return DispatchCallSignal(packet);
    }

    public Task RejectCall(CallSignalPacket packet)
    {
        packet.SignalType = "call_rejected";
        return DispatchCallSignal(packet);
    }

    public Task EndCall(CallSignalPacket packet)
    {
        packet.SignalType = "call_ended";
        return DispatchCallSignal(packet);
    }

    public Task SendWebRtcSignal(CallSignalPacket packet)
    {
        if (string.IsNullOrWhiteSpace(packet.SignalType))
        {
            packet.SignalType = "webrtc_offer";
        }
        return DispatchCallSignal(packet);
    }

    // Real-time broadcast cho sơ đồ phòng (Room Matrix)
    public async Task BroadcastRoomStatusChanged(int roomId, string newStatus)
    {
        await Clients.All.SendAsync("RoomStatusChanged", new { RoomId = roomId, Status = newStatus });
    }

    // Real-time broadcast cho bảng Kanban Sự cố
    public async Task BroadcastTicketUpdated(int ticketId, string newStatus, string? technicianName)
    {
        await Clients.All.SendAsync("TicketUpdated", new
        {
            TicketId = ticketId,
            Status = newStatus,
            TechnicianName = technicianName,
            UpdatedAt = DateTime.UtcNow
        });
    }
}
