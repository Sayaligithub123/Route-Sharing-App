const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
require("dotenv").config();

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*", // Adjust this in production
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

  // Clients emit this to join their respective room
  socket.on("join_room", ({ userId, role }) => {
    if (role === "Driver") {
      socket.join(`driver_${userId}`);
      console.log(`User ${userId} joined room driver_${userId}`);
    } else if (role === "Passenger") {
      socket.join(`passenger_${userId}`);
      console.log(`User ${userId} joined room passenger_${userId}`);
    }
  });

  // Driver emits live location via socket (alternative to REST)
  socket.on("driver_location_update", ({ rideId, lat, lng, passengerIds }) => {
    console.log(`Driver location update for ride ${rideId}: ${lat}, ${lng}`);
    if (passengerIds && Array.isArray(passengerIds)) {
      passengerIds.forEach(passengerId => {
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
app.use("/api/rides", rideRoutes); // Mount ride routes

// Connect DB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected"))
  .catch(err => console.log(err));

server.listen(process.env.PORT || 5000, () => {
  console.log(`Server running on port ${process.env.PORT || 5000}`);
});