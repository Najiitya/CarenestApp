require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const authRoutes = require("./routes/auth");
const dashboardRoutes = require("./routes/dashboard");
const caregiverRoutes = require("./routes/caregivers");
const userRoutes = require("./routes/users");
const bookingRoutes = require("./routes/bookings");
const notificationRoutes = require("./routes/notifications");
const errorHandler = require("./middleware/errorHandler");

const app = express();

// Trust proxy for Render deployment
app.set('trust proxy', 1);

// Security headers
app.use(helmet({ contentSecurityPolicy: false }));

// Rate limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: "Too many requests, please try again later." },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10, // Stricter limit for auth endpoints
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: "Too many login attempts, please try again later." },
});

// Middleware
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(",")
  : ["http://localhost:3000"];

app.use(cors({ origin: allowedOrigins, credentials: true }));
app.use(express.json({ limit: "10kb" }));

// Routes
app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/dashboard", apiLimiter, dashboardRoutes);
app.use("/api/caregivers", apiLimiter, caregiverRoutes);
app.use("/api/users", apiLimiter, userRoutes);
app.use("/api/bookings", apiLimiter, bookingRoutes);
app.use("/api/notifications", apiLimiter, notificationRoutes);

// Health check
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Serve React frontend in production
const path = require("path");
const clientBuildPath = path.join(__dirname, "..", "build");

app.use(express.static(clientBuildPath));

// Any route not matching /api/* serves the React app
app.get(/^(?!\/api).*/, (req, res) => {
  res.sendFile(path.join(clientBuildPath, "index.html"));
});

// Error handler (must be last)
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
