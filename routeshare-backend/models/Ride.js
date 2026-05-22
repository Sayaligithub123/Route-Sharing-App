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
    distance: { type: Number, default: 0 },
    soloFare: { type: Number, default: 0 },
    sharedFare: { type: Number, default: 0 },
    savings: { type: Number, default: 0 }
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
  totalFaresCollected: { type: Number, default: 0 },
  driverEarnings: { type: Number, default: 0 },
  platformCommission: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model("Ride", rideSchema);
