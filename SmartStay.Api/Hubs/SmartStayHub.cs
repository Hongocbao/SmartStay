using Microsoft.AspNetCore.SignalR;

namespace SmartStay.Api.Hubs;

public class SmartStayHub : Hub
{
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
