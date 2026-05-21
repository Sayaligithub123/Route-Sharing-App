require('dns').setDefaultResultOrder('ipv4first');
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');
dns.setServers(['8.8.8.8', '8.8.4.4']); // Use Google DNS to fix querySrv ECONNREFUSED

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
require("dotenv").config();

const app = express();
const server = http.createServer(app);

// Use PORT from .env or fallback
const PORT = process.env.PORT || 5001;

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Pass io to controllers via middleware
app.use((req, res, next) => {
  req.io = io;
  next();
});

app.use(cors());
app.use(express.json());

// Socket.IO Connection Logic
io.on("connection", (socket) => {
  console.log("A user connected:", socket.id);

  socket.on("join_room", ({ userId, role }) => {

    if (role === "Driver") {

      socket.join(`driver_${userId}`);

      const roomSize =
        io.sockets.adapter.rooms.get(`driver_${userId}`)?.size || 0;

      console.log(
        `[join_room] Driver ${userId} joined room driver_${userId} (${roomSize} socket(s))`
      );

    } else if (role === "Passenger") {

      socket.join(`passenger_${userId}`);

      const roomSize =
        io.sockets.adapter.rooms.get(`passenger_${userId}`)?.size || 0;

      console.log(
        `[join_room] Passenger ${userId} joined room passenger_${userId} (${roomSize} socket(s))`
      );
    }
  });

  // Driver live location update
  socket.on("driver_location_update", ({ rideId, lat, lng, passengerIds }) => {

    console.log(`Driver location update: ${lat}, ${lng}`);

    if (passengerIds && Array.isArray(passengerIds)) {

      passengerIds.forEach((passengerId) => {

        io.to(`passenger_${passengerId}`).emit("location_update", {
          rideId,
          location: { lat, lng },
        });

      });
    }
  });

  socket.on("disconnect", () => {
    console.log("A user disconnected:", socket.id);
  });
});

// Routes
const userRoutes = require("./routes/userRoutes");
const rideRoutes = require("./routes/rideRoutes");

app.use("/api/users", userRoutes);
app.use("/api/rides", rideRoutes);

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB Connected");

    // Start server only after DB connection
    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });

  })
  .catch((err) => {
    console.log("MongoDB Connection Error:");
    console.log(err);
  });