import carenestLogo from "../assets/carenest_logo.png";
import { useState, useEffect } from "react";
import {
  Avatar,
  Box,
  Button,
  Card,
  Chip,
  CircularProgress,
  Dialog,
  DialogContent,
  DialogActions,
  Divider,
  IconButton,
  InputAdornment,
  MenuItem,
  Select,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import {
  Search,
  Close,
  FilterAltOff,
  Email,
  Phone,
  Badge,
  CalendarMonth,
  LocationOn,
  Star,
  PersonOutline,
  Block,
  CheckCircle,
} from "@mui/icons-material";
import Navbar from "../components/Navbar";
import API_BASE, { getAuthHeaders } from "../services/api";

const getStatusChipProps = (status) => {
  switch (status) {
    case "Active":
      return { bgcolor: "#e8f5e9", color: "#2e7d32" };
    case "Suspended":
      return { bgcolor: "#ffebee", color: "#c62828" };
    default:
      return { bgcolor: "#f5f5f5", color: "#555" };
  }
};

const getRoleChipProps = (role) => {
  switch (role) {
    case "Family":
      return { bgcolor: "#e3f2fd", color: "#1565c0" };
    case "Caregiver":
      return { bgcolor: "#f3e5f5", color: "#7b1fa2" };
    default:
      return { bgcolor: "#f5f5f5", color: "#555" };
  }
};

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [roleFilter, setRoleFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");
  const [selectedUser, setSelectedUser] = useState(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchUsers = async () => {
    try {
      const params = new URLSearchParams();
      if (roleFilter !== "All") params.append("role", roleFilter);
      if (statusFilter !== "All") params.append("status", statusFilter);
      if (searchQuery) params.append("search", searchQuery);

      const res = await fetch(`${API_BASE}/users?${params}`, {
        headers: getAuthHeaders(),
      });
      const data = await res.json();
      if (data.success) setUsers(data.data);
    } catch (err) {
      console.error("Failed to fetch users:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [roleFilter, statusFilter, searchQuery]);

  const handleView = (user) => {
    setSelectedUser(user);
    setDetailOpen(true);
  };

  const handleClose = () => {
    setDetailOpen(false);
    setSelectedUser(null);
  };

  const handleToggleStatus = async () => {
    if (!selectedUser) return;
    setActionLoading(true);
    try {
      const res = await fetch(`${API_BASE}/users/${selectedUser.id}/status`, {
        method: "PATCH",
        headers: getAuthHeaders(),
        body: JSON.stringify({ role: selectedUser.role }),
      });
      const data = await res.json();
      if (data.success) {
        const newStatus = data.data.status;
        setUsers((prev) =>
          prev.map((u) =>
            u.id === selectedUser.id ? { ...u, status: newStatus } : u
          )
        );
        setSelectedUser((prev) => ({ ...prev, status: newStatus }));
      }
    } catch (err) {
      console.error("Failed to toggle status:", err);
    } finally {
      setActionLoading(false);
    }
  };

  const clearFilters = () => {
    setSearchQuery("");
    setRoleFilter("All");
    setStatusFilter("All");
  };

  const hasFilters =
    searchQuery !== "" || roleFilter !== "All" || statusFilter !== "All";

  if (loading) {
    return (
      <Box
        sx={{
          width: "100vw",
          minHeight: "100vh",
          bgcolor: "#e8ecf0",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <CircularProgress sx={{ color: "#1565c0" }} />
      </Box>
    );
  }

  return (
    <Box
      sx={{
        width: "100vw",
        minHeight: "100vh",
        bgcolor: "#e8ecf0",
        p: "20px",
        boxSizing: "border-box",
      }}
    >
      <Box
        sx={{
          width: "100%",
          minHeight: "calc(100vh - 40px)",
          bgcolor: "#fff",
          borderRadius: "24px",
          boxShadow: "0 8px 40px rgba(0,0,0,0.08)",
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
        }}
      >
        <Navbar />

        <Box sx={{ flex: 1, px: 5, py: 4, overflow: "auto" }}>
          {/* Header */}
          <Box sx={{ textAlign: "center", mb: 4 }}>
            <Typography
              sx={{ fontSize: "2rem", fontWeight: 700, color: "#1a1a2e", mb: 0.5 }}
            >
              Users
            </Typography>
            <Typography sx={{ fontSize: "0.95rem", color: "#888" }}>
              View and manage platform users.
            </Typography>
          </Box>

          {/* Filter / Search Card */}
          <Card
            elevation={0}
            sx={{
              display: "flex",
              alignItems: "center",
              gap: 2,
              px: 3,
              py: 2,
              mb: 3,
              border: "1px solid #ebebeb",
              borderRadius: "14px",
              bgcolor: "#fafbfc",
            }}
          >
            <TextField
              placeholder="Search by name, email, or phone..."
              size="small"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{
                flex: 1,
                "& .MuiOutlinedInput-root": {
                  borderRadius: "10px",
                  fontSize: "0.88rem",
                  bgcolor: "#fff",
                },
              }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search sx={{ color: "#aaa", fontSize: 20 }} />
                  </InputAdornment>
                ),
              }}
            />
            <Select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              size="small"
              sx={{
                minWidth: 140,
                borderRadius: "10px",
                fontSize: "0.88rem",
                bgcolor: "#fff",
              }}
            >
              <MenuItem value="All">All Roles</MenuItem>
              <MenuItem value="Family">Family</MenuItem>
              <MenuItem value="Caregiver">Caregiver</MenuItem>
            </Select>
            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              size="small"
              sx={{
                minWidth: 140,
                borderRadius: "10px",
                fontSize: "0.88rem",
                bgcolor: "#fff",
              }}
            >
              <MenuItem value="All">All Statuses</MenuItem>
              <MenuItem value="Active">Active</MenuItem>
              <MenuItem value="Suspended">Suspended</MenuItem>
            </Select>
            {hasFilters && (
              <Button
                size="small"
                startIcon={<FilterAltOff sx={{ fontSize: 16 }} />}
                onClick={clearFilters}
                sx={{
                  textTransform: "none",
                  fontSize: "0.82rem",
                  fontWeight: 500,
                  color: "#999",
                  borderRadius: "10px",
                  border: "1px solid #e0e0e0",
                  px: 2,
                  "&:hover": { bgcolor: "#f5f5f5", borderColor: "#ccc" },
                }}
              >
                Clear
              </Button>
            )}
            <Typography sx={{ fontSize: "0.82rem", color: "#888", ml: 1, whiteSpace: "nowrap" }}>
              {users.length} result{users.length !== 1 ? "s" : ""}
            </Typography>
          </Card>

          {/* Table Card */}
          <Card
            elevation={0}
            sx={{
              border: "1px solid #ebebeb",
              borderRadius: "18px",
              p: 3,
              display: "flex",
              flexDirection: "column",
              height: 520,
            }}
          >
            <TableContainer sx={{ flex: 1, overflowY: "auto" }}>
              <Table size="small" stickyHeader>
                <TableHead>
                  <TableRow>
                    {["User", "Role", "Phone", "Status", "Created Date", "Action"].map(
                      (h) => (
                        <TableCell
                          key={h}
                          sx={{
                            fontWeight: 700,
                            fontSize: "0.78rem",
                            color: "#888",
                            borderBottom: "2px solid #f0f0f0",
                            py: 1.5,
                            bgcolor: "#fff",
                          }}
                        >
                          {h}
                        </TableCell>
                      )
                    )}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {users.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} sx={{ textAlign: "center", py: 6 }}>
                        <Typography sx={{ color: "#aaa", fontSize: "0.9rem" }}>
                          No users found.
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    users.map((row, i) => {
                      const statusProps = getStatusChipProps(row.status);
                      const roleProps = getRoleChipProps(row.role);
                      return (
                        <TableRow
                          key={row.id}
                          sx={{ "&:hover": { bgcolor: "#fafbfc" } }}
                        >
                          <TableCell sx={{ py: 2, borderBottom: "1px solid #f5f5f5" }}>
                            <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                              <Avatar
                                src={carenestLogo} sx={{ bgcolor: "#16A394" }}
                                sx={{ width: 36, height: 36 }}
                              />
                              <Box>
                                <Typography
                                  sx={{ fontSize: "0.88rem", fontWeight: 600, color: "#1a1a2e" }}
                                >
                                  {row.name}
                                </Typography>
                                <Typography sx={{ fontSize: "0.75rem", color: "#999" }}>
                                  {row.email}
                                </Typography>
                              </Box>
                            </Box>
                          </TableCell>
                          <TableCell sx={{ borderBottom: "1px solid #f5f5f5" }}>
                            <Chip
                              label={row.role}
                              size="small"
                              sx={{
                                bgcolor: roleProps.bgcolor,
                                color: roleProps.color,
                                fontWeight: 600,
                                fontSize: "0.7rem",
                                height: 26,
                              }}
                            />
                          </TableCell>
                          <TableCell
                            sx={{
                              fontSize: "0.83rem",
                              color: "#666",
                              borderBottom: "1px solid #f5f5f5",
                            }}
                          >
                            {row.phone}
                          </TableCell>
                          <TableCell sx={{ borderBottom: "1px solid #f5f5f5" }}>
                            <Chip
                              label={row.status}
                              size="small"
                              sx={{
                                bgcolor: statusProps.bgcolor,
                                color: statusProps.color,
                                fontWeight: 600,
                                fontSize: "0.7rem",
                                height: 26,
                              }}
                            />
                          </TableCell>
                          <TableCell
                            sx={{
                              fontSize: "0.83rem",
                              color: "#666",
                              borderBottom: "1px solid #f5f5f5",
                            }}
                          >
                            {row.created_at}
                          </TableCell>
                          <TableCell sx={{ borderBottom: "1px solid #f5f5f5" }}>
                            <Button
                              size="small"
                              onClick={() => handleView(row)}
                              sx={{
                                fontSize: "0.78rem",
                                color: "#1565c0",
                                textTransform: "none",
                                fontWeight: 600,
                                minWidth: 0,
                                px: 2,
                                py: 0.5,
                                borderRadius: "8px",
                                border: "1px solid #e0e0e0",
                                "&:hover": {
                                  bgcolor: "rgba(21,101,192,0.04)",
                                  borderColor: "#1565c0",
                                },
                              }}
                            >
                              View
                            </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Card>
        </Box>
      </Box>

      {/* Detail Dialog */}
      <Dialog
        open={detailOpen}
        onClose={handleClose}
        maxWidth="sm"
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: "20px",
            p: 0,
            overflow: "hidden",
          },
        }}
      >
        {selectedUser && (
          <>
            {/* Dialog Header */}
            <Box
              sx={{
                background:
                  selectedUser.role === "Caregiver"
                    ? "linear-gradient(135deg, #7b1fa2 0%, #4a148c 100%)"
                    : "linear-gradient(135deg, #1565c0 0%, #0d47a1 100%)",
                px: 3.5,
                py: 3,
                display: "flex",
                alignItems: "center",
                gap: 2,
              }}
            >
              <Avatar
                src={carenestLogo} sx={{ bgcolor: "#16A394" }}
                sx={{ width: 56, height: 56, border: "3px solid rgba(255,255,255,0.3)" }}
              />
              <Box sx={{ flex: 1 }}>
                <Typography
                  sx={{ fontSize: "1.25rem", fontWeight: 700, color: "#fff" }}
                >
                  {selectedUser.name}
                </Typography>
                <Typography sx={{ fontSize: "0.85rem", color: "rgba(255,255,255,0.7)" }}>
                  User #{selectedUser.id}
                </Typography>
              </Box>
              <Chip
                label={selectedUser.role}
                size="small"
                sx={{
                  bgcolor: "rgba(255,255,255,0.2)",
                  color: "#fff",
                  fontWeight: 600,
                  fontSize: "0.75rem",
                }}
              />
              <Chip
                label={selectedUser.status}
                size="small"
                sx={{
                  bgcolor:
                    selectedUser.status === "Active"
                      ? "rgba(76,175,80,0.3)"
                      : "rgba(244,67,54,0.3)",
                  color: "#fff",
                  fontWeight: 600,
                  fontSize: "0.75rem",
                }}
              />
              <IconButton onClick={handleClose} sx={{ color: "rgba(255,255,255,0.7)" }}>
                <Close />
              </IconButton>
            </Box>

            <DialogContent sx={{ px: 3.5, py: 3 }}>
              {/* Basic Info */}
              <Typography
                sx={{
                  fontSize: "0.75rem",
                  fontWeight: 700,
                  color: "#999",
                  textTransform: "uppercase",
                  letterSpacing: 1,
                  mb: 1.5,
                }}
              >
                Contact Information
              </Typography>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5, mb: 3 }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <Email sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    {selectedUser.email}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <Phone sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    {selectedUser.phone}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <PersonOutline sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    Role: {selectedUser.role}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <CalendarMonth sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    Joined: {selectedUser.created_at}
                  </Typography>
                </Box>
                {selectedUser.location && (
                  <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                    <LocationOn sx={{ fontSize: 18, color: "#1565c0" }} />
                    <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                      {selectedUser.location}
                    </Typography>
                  </Box>
                )}
              </Box>

              {/* Caregiver-specific fields */}
              {selectedUser.role === "Caregiver" && (
                <>
                  <Divider sx={{ mb: 3 }} />
                  <Typography
                    sx={{
                      fontSize: "0.75rem",
                      fontWeight: 700,
                      color: "#999",
                      textTransform: "uppercase",
                      letterSpacing: 1,
                      mb: 1.5,
                    }}
                  >
                    Caregiver Details
                  </Typography>
                  <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5, mb: 3 }}>
                    {selectedUser.nic && (
                      <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                        <Badge sx={{ fontSize: 18, color: "#7b1fa2" }} />
                        <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                          NIC: {selectedUser.nic}
                        </Typography>
                      </Box>
                    )}
                    {selectedUser.rating != null && (
                      <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                        <Star sx={{ fontSize: 18, color: "#f9a825" }} />
                        <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                          Rating: {selectedUser.rating} / 5.0
                        </Typography>
                        <Box
                          sx={{
                            ml: 1,
                            px: 1.5,
                            py: 0.3,
                            borderRadius: "8px",
                            bgcolor:
                              selectedUser.rating >= 4.5
                                ? "#e8f5e9"
                                : selectedUser.rating >= 3.5
                                ? "#fff3e0"
                                : "#ffebee",
                            color:
                              selectedUser.rating >= 4.5
                                ? "#2e7d32"
                                : selectedUser.rating >= 3.5
                                ? "#e65100"
                                : "#c62828",
                            fontSize: "0.72rem",
                            fontWeight: 600,
                          }}
                        >
                          {selectedUser.rating >= 4.5
                            ? "Excellent"
                            : selectedUser.rating >= 3.5
                            ? "Good"
                            : "Needs Improvement"}
                        </Box>
                      </Box>
                    )}
                  </Box>
                </>
              )}
            </DialogContent>

            {/* Actions */}
            <DialogActions sx={{ px: 3.5, pb: 3, pt: 0, gap: 1.5 }}>
              {selectedUser.status === "Active" ? (
                <Button
                  onClick={handleToggleStatus}
                  variant="outlined"
                  color="error"
                  startIcon={actionLoading ? <CircularProgress size={16} color="inherit" /> : <Block />}
                  disabled={actionLoading}
                  sx={{
                    borderRadius: "10px",
                    textTransform: "none",
                    fontWeight: 600,
                    fontSize: "0.88rem",
                    px: 3,
                  }}
                >
                  Suspend User
                </Button>
              ) : (
                <Button
                  onClick={handleToggleStatus}
                  variant="contained"
                  startIcon={actionLoading ? <CircularProgress size={16} color="inherit" /> : <CheckCircle />}
                  disabled={actionLoading}
                  sx={{
                    borderRadius: "10px",
                    textTransform: "none",
                    fontWeight: 600,
                    fontSize: "0.88rem",
                    px: 3,
                    bgcolor: "#2e7d32",
                    "&:hover": { bgcolor: "#1b5e20" },
                  }}
                >
                  Activate User
                </Button>
              )}
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
}

export default Users;
