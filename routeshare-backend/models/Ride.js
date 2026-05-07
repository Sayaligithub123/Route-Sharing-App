const mongoose = require("mongoose");

const rideSchema = new mongoose.Schema({
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  source: {
    type: String,
    required: true,
  },
  destination: {
    type: String,
    required: true,
  },
  availableSeats: {
    type: Number,
    required: true,
  },
  passengers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  }],
  passengerDropLocations: [{
    passengerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    pickupLocation: String,
    dropLocation: String,
  }],
  status: {
    type: String,
    enum: ["active", "in_progress", "completed"],
    default: "active",
  },
  driverLocation: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
}, { timestamps: true });

module.exports = mongoose.model("Ride", rideSchema);
