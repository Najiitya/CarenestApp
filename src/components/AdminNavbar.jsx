import {
  Avatar,
  Badge,
  Box,
  Divider,
  IconButton,
  Typography,
} from "@mui/material";
import { NotificationsNoneOutlined } from "@mui/icons-material";

const navItems = [
  { label: "Dashboard", active: true },
  { label: "Caregiver Verification", active: false },
  { label: "Users", active: false },
  { label: "Bookings", active: false },
];

function AdminNavbar() {
  return (
    <Box>
      {/* Top bar */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          px: 5,
          py: 2,
        }}
      >
        {/* Left - Brand + Primary Nav */}
        <Box sx={{ display: "flex", alignItems: "center", gap: 6 }}>
          <Typography
            sx={{
              fontWeight: 700,
              fontSize: "1.7rem",
              color: "#1565c0",
              letterSpacing: -0.5,
            }}
          >
            CareNest.lk
          </Typography>
          <Box sx={{ display: "flex", gap: 0.5 }}>
            {navItems.map((item) => (
              <Box
                key={item.label}
                sx={{
                  px: 2,
                  py: 1.2,
                  cursor: "pointer",
                  position: "relative",
                  borderBottom: item.active
                    ? "2.5px solid #1565c0"
                    : "2.5px solid transparent",
                  transition: "border-color 0.2s",
                  "&:hover": {
                    borderBottom: item.active
                      ? "2.5px solid #1565c0"
                      : "2.5px solid #ccc",
                  },
                }}
              >
                <Typography
                  sx={{
                    fontSize: "0.9rem",
                    fontWeight: item.active ? 600 : 400,
                    color: item.active ? "#1565c0" : "#777",
                  }}
                >
                  {item.label}
                </Typography>
              </Box>
            ))}
          </Box>
        </Box>

        {/* Right - Notifications + Avatar */}
        <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
          <IconButton sx={{ color: "#555" }}>
            <Badge variant="dot" color="error">
              <NotificationsNoneOutlined sx={{ fontSize: 26 }} />
            </Badge>
          </IconButton>
          <Avatar
            src="https://i.pravatar.cc/40?img=12"
            sx={{
              width: 42,
              height: 42,
              border: "2px solid #e0e0e0",
              cursor: "pointer",
            }}
          />
        </Box>
      </Box>
      <Divider sx={{ borderColor: "#f0f0f0" }} />
    </Box>
  );
}

export default AdminNavbar;
