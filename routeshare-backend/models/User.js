const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  role: {
    type: String,
    enum: ["Passenger", "Driver"],
    required: true,
  },
  name: String,
  email: String,
  phone: String,

  // Driver-specific
  vehicleName: String,
  vehicleNumber: String,
  license: String,
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);