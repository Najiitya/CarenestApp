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
  CheckCircle,
  Cancel,
  Description,
  Phone,
  Email,
  Badge,
  CalendarMonth,
  WorkHistory,
  MedicalServices,
} from "@mui/icons-material";
import Navbar from "../components/Navbar";
import API_BASE, { getAuthHeaders } from "../services/api";

const getStatusChipProps = (status) => {
  switch (status) {
    case "Pending":
      return { bgcolor: "#fff3e0", color: "#e65100" };
    case "Approved":
      return { bgcolor: "#e8f5e9", color: "#2e7d32" };
    case "Rejected":
      return { bgcolor: "#ffebee", color: "#c62828" };
    default:
      return { bgcolor: "#f5f5f5", color: "#555" };
  }
};

function CaregiverVerification() {
  const [applications, setApplications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("Pending");
  const [selectedCaregiver, setSelectedCaregiver] = useState(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [rejectMode, setRejectMode] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  const fetchApplications = async () => {
    try {
      const params = new URLSearchParams();
      if (statusFilter !== "All") params.append("status", statusFilter);
      if (searchQuery) params.append("search", searchQuery);

      const res = await fetch(`${API_BASE}/caregivers/applications?${params}`, {
        headers: getAuthHeaders(),
      });
      const data = await res.json();
      if (data.success) setApplications(data.data);
    } catch (err) {
      console.error("Failed to fetch applications:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchApplications();
  }, [statusFilter, searchQuery]);

  const handleView = (caregiver) => {
    setSelectedCaregiver(caregiver);
    setDetailOpen(true);
    setRejectMode(false);
    setRejectReason("");
  };

  const handleClose = () => {
    setDetailOpen(false);
    setSelectedCaregiver(null);
    setRejectMode(false);
    setRejectReason("");
  };

  const handleApprove = async () => {
    if (!selectedCaregiver) return;
    setActionLoading(true);
    try {
      const res = await fetch(
        `${API_BASE}/caregivers/applications/${selectedCaregiver.id}/approve`,
        { method: "PATCH", headers: getAuthHeaders() }
      );
      const data = await res.json();
      if (data.success) {
        setApplications((prev) =>
          prev.map((app) =>
            app.id === selectedCaregiver.id ? { ...app, status: "Approved" } : app
          )
        );
        setSelectedCaregiver((prev) => ({ ...prev, status: "Approved" }));
        setRejectMode(false);
      }
    } catch (err) {
      console.error("Failed to approve:", err);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!rejectReason.trim() || !selectedCaregiver) return;
    setActionLoading(true);
    try {
      const res = await fetch(
        `${API_BASE}/caregivers/applications/${selectedCaregiver.id}/reject`,
        {
          method: "PATCH",
          headers: getAuthHeaders(),
          body: JSON.stringify({ reason: rejectReason }),
        }
      );
      const data = await res.json();
      if (data.success) {
        setApplications((prev) =>
          prev.map((app) =>
            app.id === selectedCaregiver.id ? { ...app, status: "Rejected" } : app
          )
        );
        setSelectedCaregiver((prev) => ({ ...prev, status: "Rejected" }));
        setRejectMode(false);
        setRejectReason("");
      }
    } catch (err) {
      console.error("Failed to reject:", err);
    } finally {
      setActionLoading(false);
    }
  };

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
              Caregiver Verification
            </Typography>
            <Typography sx={{ fontSize: "0.95rem", color: "#888" }}>
              Review documents and approve caregiver profiles.
            </Typography>
          </Box>

          {/* Search & Filter Card */}
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
              placeholder="Search by name, email, or NIC..."
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
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              size="small"
              sx={{
                minWidth: 160,
                borderRadius: "10px",
                fontSize: "0.88rem",
                bgcolor: "#fff",
              }}
            >
              <MenuItem value="All">All Statuses</MenuItem>
              <MenuItem value="Pending">Pending</MenuItem>
              <MenuItem value="Approved">Approved</MenuItem>
              <MenuItem value="Rejected">Rejected</MenuItem>
            </Select>
            <Typography sx={{ fontSize: "0.82rem", color: "#888", ml: 1 }}>
              {applications.length} result{applications.length !== 1 ? "s" : ""}
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
                    {["Caregiver", "Submitted Date", "NIC", "Status", "Action"].map(
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
                  {applications.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} sx={{ textAlign: "center", py: 6 }}>
                        <Typography sx={{ color: "#aaa", fontSize: "0.9rem" }}>
                          No applications found.
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    applications.map((row, i) => {
                      const chipProps = getStatusChipProps(row.status);
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
                          <TableCell
                            sx={{
                              fontSize: "0.83rem",
                              color: "#666",
                              borderBottom: "1px solid #f5f5f5",
                            }}
                          >
                            {row.submitted_date}
                          </TableCell>
                          <TableCell
                            sx={{
                              fontSize: "0.83rem",
                              color: "#444",
                              fontWeight: 500,
                              borderBottom: "1px solid #f5f5f5",
                            }}
                          >
                            {row.nic}
                          </TableCell>
                          <TableCell sx={{ borderBottom: "1px solid #f5f5f5" }}>
                            <Chip
                              label={row.status}
                              size="small"
                              sx={{
                                bgcolor: chipProps.bgcolor,
                                color: chipProps.color,
                                fontWeight: 600,
                                fontSize: "0.7rem",
                                height: 26,
                              }}
                            />
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
        {selectedCaregiver && (
          <>
            {/* Dialog Header */}
            <Box
              sx={{
                background: "linear-gradient(135deg, #1565c0 0%, #0d47a1 100%)",
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
                  {selectedCaregiver.name}
                </Typography>
                <Typography sx={{ fontSize: "0.85rem", color: "rgba(255,255,255,0.7)" }}>
                  Application #{selectedCaregiver.id}
                </Typography>
              </Box>
              <Chip
                label={selectedCaregiver.status}
                size="small"
                sx={{
                  bgcolor: "rgba(255,255,255,0.2)",
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
              {/* Contact Info */}
              <Typography
                sx={{ fontSize: "0.75rem", fontWeight: 700, color: "#999", textTransform: "uppercase", letterSpacing: 1, mb: 1.5 }}
              >
                Contact Information
              </Typography>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5, mb: 3 }}>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <Email sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    {selectedCaregiver.email}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <Phone sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    {selectedCaregiver.phone}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <Badge sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    NIC: {selectedCaregiver.nic}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
                  <CalendarMonth sx={{ fontSize: 18, color: "#1565c0" }} />
                  <Typography sx={{ fontSize: "0.9rem", color: "#444" }}>
                    Submitted: {selectedCaregiver.submitted_date}
                  </Typography>
                </Box>
              </Box>

              <Divider sx={{ mb: 3 }} />

              {/* Skills & Experience */}
              <Typography
                sx={{ fontSize: "0.75rem", fontWeight: 700, color: "#999", textTransform: "uppercase", letterSpacing: 1, mb: 1.5 }}
              >
                Skills & Experience
              </Typography>
              <Box sx={{ display: "flex", alignItems: "flex-start", gap: 1.5, mb: 1.5 }}>
                <MedicalServices sx={{ fontSize: 18, color: "#1565c0", mt: 0.3 }} />
                <Typography sx={{ fontSize: "0.88rem", color: "#444" }}>
                  {selectedCaregiver.skills}
                </Typography>
              </Box>
              <Box sx={{ display: "flex", alignItems: "flex-start", gap: 1.5, mb: 3 }}>
                <WorkHistory sx={{ fontSize: 18, color: "#1565c0", mt: 0.3 }} />
                <Typography sx={{ fontSize: "0.88rem", color: "#444" }}>
                  {selectedCaregiver.experience}
                </Typography>
              </Box>

              <Divider sx={{ mb: 3 }} />

              {/* Documents */}
              <Typography
                sx={{ fontSize: "0.75rem", fontWeight: 700, color: "#999", textTransform: "uppercase", letterSpacing: 1, mb: 1.5 }}
              >
                Uploaded Documents
              </Typography>
              <Box sx={{ display: "flex", gap: 2, flexWrap: "wrap", mb: 3 }}>
                {[
                  { label: "NIC Front", file: selectedCaregiver.doc_nic_front },
                  { label: "NIC Back", file: selectedCaregiver.doc_nic_back },
                  { label: "Certificate", file: selectedCaregiver.doc_certificate },
                ].map((doc) => {
                  if (!doc.file) return null;
                  const isPdf = doc.file.toLowerCase().includes(".pdf");
                  return (
                    <Box
                      key={doc.label}
                      sx={{
                        width: 180,
                        border: "1px solid #e0e0e0",
                        borderRadius: "12px",
                        bgcolor: "#fafbfc",
                        overflow: "hidden",
                        transition: "all 0.15s",
                        "&:hover": { borderColor: "#1565c0", boxShadow: "0 2px 12px rgba(21,101,192,0.12)" },
                      }}
                    >
                      <Box
                        component="a"
                        href={doc.file}
                        target="_blank"
                        rel="noopener noreferrer"
                        sx={{ textDecoration: "none", display: "block" }}
                      >
                        {isPdf ? (
                          <Box sx={{ height: 130, display: "flex", alignItems: "center", justifyContent: "center", bgcolor: "#f0f4f8" }}>
                            <Description sx={{ fontSize: 48, color: "#1565c0" }} />
                          </Box>
                        ) : (
                          <Box
                            component="img"
                            src={doc.file}
                            alt={doc.label}
                            sx={{
                              width: "100%",
                              height: 130,
                              objectFit: "cover",
                              display: "block",
                              bgcolor: "#f0f4f8",
                            }}
                          />
                        )}
                        <Box sx={{ px: 1.5, py: 1 }}>
                          <Typography sx={{ fontSize: "0.8rem", fontWeight: 600, color: "#333" }}>
                            {doc.label}
                          </Typography>
                          <Typography sx={{ fontSize: "0.68rem", color: "#1565c0" }}>
                            Click to view full size
                          </Typography>
                        </Box>
                      </Box>
                    </Box>
                  );
                })}
              </Box>

              {/* Reject Reason Field */}
              {rejectMode && (
                <Box sx={{ mb: 2 }}>
                  <TextField
                    label="Rejection Reason"
                    placeholder="Please provide a reason for rejection..."
                    multiline
                    rows={3}
                    fullWidth
                    required
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    sx={{
                      "& .MuiOutlinedInput-root": {
                        borderRadius: "12px",
                        fontSize: "0.88rem",
                      },
                    }}
                  />
                </Box>
              )}
            </DialogContent>

            {/* Actions */}
            {selectedCaregiver.status === "Pending" && (
              <DialogActions sx={{ px: 3.5, pb: 3, pt: 0, gap: 1.5 }}>
                {!rejectMode ? (
                  <>
                    <Button
                      onClick={() => setRejectMode(true)}
                      variant="outlined"
                      color="error"
                      startIcon={<Cancel />}
                      disabled={actionLoading}
                      sx={{
                        borderRadius: "10px",
                        textTransform: "none",
                        fontWeight: 600,
                        fontSize: "0.88rem",
                        px: 3,
                      }}
                    >
                      Reject
                    </Button>
                    <Button
                      onClick={handleApprove}
                      variant="contained"
                      startIcon={actionLoading ? <CircularProgress size={16} color="inherit" /> : <CheckCircle />}
                      disabled={actionLoading}
                      sx={{
                        borderRadius: "10px",
                        textTransform: "none",
                        fontWeight: 600,
                        fontSize: "0.88rem",
                        px: 3,
                        bgcolor: "#1565c0",
                        "&:hover": { bgcolor: "#0d47a1" },
                      }}
                    >
                      Approve
                    </Button>
                  </>
                ) : (
                  <>
                    <Button
                      onClick={() => {
                        setRejectMode(false);
                        setRejectReason("");
                      }}
                      disabled={actionLoading}
                      sx={{
                        borderRadius: "10px",
                        textTransform: "none",
                        fontWeight: 500,
                        fontSize: "0.88rem",
                        color: "#666",
                      }}
                    >
                      Cancel
                    </Button>
                    <Button
                      onClick={handleReject}
                      variant="contained"
                      color="error"
                      disabled={!rejectReason.trim() || actionLoading}
                      startIcon={actionLoading ? <CircularProgress size={16} color="inherit" /> : null}
                      sx={{
                        borderRadius: "10px",
                        textTransform: "none",
                        fontWeight: 600,
                        fontSize: "0.88rem",
                        px: 3,
                      }}
                    >
                      Confirm Rejection
                    </Button>
                  </>
                )}
              </DialogActions>
            )}
          </>
        )}
      </Dialog>
    </Box>
  );
}

export default CaregiverVerification;
