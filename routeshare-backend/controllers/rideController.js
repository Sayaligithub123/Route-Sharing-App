const Ride = require("../models/Ride");
const Request = require("../models/Request");
const User = require("../models/User");

// Start a ride (driver creates a ride listing)
exports.startRide = async (req, res) => {
  try {
    const { driverId, source, destination, availableSeats } = req.body;

    // Validate inputs
    if (!driverId || !source || !destination || !availableSeats) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const newRide = new Ride({
      driverId,
      source,
      destination,
      availableSeats,
    });

    await newRide.save();
    res.status(201).json({ message: "Ride started successfully", ride: newRide });
  } catch (error) {
    res.status(500).json({ error: "Failed to start ride", details: error.message });
  }
};

// Search rides — includes both active and in_progress rides with available seats
exports.searchRides = async (req, res) => {
  try {
    const { source, destination } = req.query;

    const query = { status: { $in: ["active", "in_progress"] }, availableSeats: { $gt: 0 } };
    if (source) query.source = new RegExp(source, "i");
    if (destination) query.destination = new RegExp(destination, "i");

    const rides = await Ride.find(query)
      .populate("driverId", "name email phone vehicleName vehicleNumber")
      .populate("passengers", "name phone");

    // Add currentPassengerCount to each ride in the response
    const ridesWithCount = rides.map(ride => {
      const rideObj = ride.toObject();
      rideObj.currentPassengerCount = ride.passengers ? ride.passengers.length : 0;
      return rideObj;
    });

    res.status(200).json(ridesWithCount);
  } catch (error) {
    res.status(500).json({ error: "Failed to search rides", details: error.message });
  }
};

// Request to join a ride
exports.requestToJoin = async (req, res) => {
  try {
    const { rideId, passengerId, pickupLocation, dropLocation } = req.body;

    if (!rideId || !passengerId) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const ride = await Ride.findById(rideId).populate("passengers", "name phone");
    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    if (ride.availableSeats <= 0) {
      return res.status(400).json({ error: "No available seats" });
    }

    const existingRequest = await Request.findOne({ rideId, passengerId, status: { $in: ["pending", "accepted"] } });
    if (existingRequest) {
      return res.status(400).json({ error: "You have already requested to join this ride" });
    }

    const newRequest = new Request({
      rideId,
      passengerId,
      pickupLocation: pickupLocation || "",
      dropLocation: dropLocation || "",
    });

    await newRequest.save();

    // Fetch the requesting passenger's name for notifications
    const requestingUser = await User.findById(passengerId);
    const requesterName = requestingUser ? requestingUser.name : "A passenger";

    // Emit event to the driver
    if (req.io) {
      const driverRoom = `driver_${ride.driverId}`;
      const roomSockets = req.io.sockets.adapter.rooms.get(driverRoom);
      console.log(`[requestToJoin] Emitting new_request to room: ${driverRoom}`);
      console.log(`[requestToJoin] Sockets in room "${driverRoom}": ${roomSockets ? roomSockets.size : 0}`);
      
      // Log all active rooms for debugging
      const allRooms = Array.from(req.io.sockets.adapter.rooms.keys()).filter(r => r.startsWith('driver_'));
      console.log(`[requestToJoin] All active driver rooms: ${JSON.stringify(allRooms)}`);

      req.io.to(driverRoom).emit("new_request", {
        message: "You have a new ride request",
        request: newRequest,
      });

      // Emit co-ride request to all existing passengers in the ride
      if (ride.passengers && ride.passengers.length > 0) {
        ride.passengers.forEach(passenger => {
          const pId = passenger._id ? passenger._id.toString() : passenger.toString();
          req.io.to(`passenger_${pId}`).emit("coride_request", {
            message: `${requesterName} wants to share your ride`,
            requesterName: requesterName,
            dropLocation: dropLocation || "",
            requestId: newRequest._id,
          });
        });
      }
    } else {
      console.log("[requestToJoin] WARNING: req.io is undefined! Socket.IO not available.");
    }

    res.status(201).json({ message: "Request sent successfully", request: newRequest });
  } catch (error) {
    res.status(500).json({ error: "Failed to send request", details: error.message });
  }
};

// Respond to request
exports.respondToRequest = async (req, res) => {
  try {
    const { requestId, status } = req.body;

    if (!requestId || !["accepted", "rejected"].includes(status)) {
      return res.status(400).json({ error: "Invalid status or missing requestId" });
    }

    const request = await Request.findById(requestId);
    if (!request) {
      return res.status(404).json({ error: "Request not found" });
    }

    if (request.status !== "pending") {
      return res.status(400).json({ error: "Request has already been processed" });
    }

    const ride = await Ride.findById(request.rideId);
    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    if (status === "accepted") {
      if (ride.availableSeats <= 0) {
        return res.status(400).json({ error: "No available seats left" });
      }
      ride.availableSeats -= 1;
      ride.passengers.push(request.passengerId);

      // Save the passenger's drop location info
      ride.passengerDropLocations.push({
        passengerId: request.passengerId,
        pickupLocation: request.pickupLocation || "",
        dropLocation: request.dropLocation || "",
      });

      await ride.save();

      // Fetch updated ride with populated passengers for the notification
      const updatedRide = await Ride.findById(ride._id)
        .populate("passengers", "name phone")
        .populate("passengerDropLocations.passengerId", "name phone");

      // Notify ALL passengers (including the newly added one) that a co-rider joined
      if (req.io && updatedRide.passengers) {
        const newPassenger = await User.findById(request.passengerId);
        const newPassengerName = newPassenger ? newPassenger.name : "A passenger";

        updatedRide.passengers.forEach(passenger => {
          const pId = passenger._id ? passenger._id.toString() : passenger.toString();
          // Don't send "coride_accepted" to the passenger who just joined — they get "request_accepted"
          if (pId !== request.passengerId.toString()) {
            req.io.to(`passenger_${pId}`).emit("coride_accepted", {
              message: `${newPassengerName} has joined your shared ride`,
              newPassengerName: newPassengerName,
              dropLocation: request.dropLocation || "",
              totalPassengers: updatedRide.passengers.length,
              passengers: updatedRide.passengers.map(p => ({
                _id: p._id,
                name: p.name,
                phone: p.phone,
              })),
            });
          }
        });
      }
    }

    request.status = status;
    await request.save();

    // Emit event to the passenger who requested
    if (req.io) {
      req.io.to(`passenger_${request.passengerId}`).emit(`request_${status}`, {
        message: `Your request has been ${status}`,
        rideId: ride._id,
      });
    }

    res.status(200).json({ message: `Request ${status} successfully`, request });
  } catch (error) {
    res.status(500).json({ error: "Failed to respond to request", details: error.message });
  }
};

// Get request status
exports.getRequestStatus = async (req, res) => {
  try {
    const { id } = req.params;

    const request = await Request.findById(id).populate("rideId", "source destination status driverId");
    if (!request) {
      return res.status(404).json({ error: "Request not found" });
    }

    res.status(200).json(request);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch request status", details: error.message });
  }
};

// Get ride details
exports.getRideDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const ride = await Ride.findById(id)
      .populate("driverId", "name email phone vehicleName vehicleNumber")
      .populate("passengers", "name phone");

    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    res.status(200).json(ride);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch ride details", details: error.message });
  }
};

// Get ride passengers with drop locations — used by shared ride view
exports.getRidePassengers = async (req, res) => {
  try {
    const { id } = req.params;

    const ride = await Ride.findById(id)
      .populate("passengers", "name phone")
      .populate("driverId", "name phone vehicleName vehicleNumber")
      .populate("passengerDropLocations.passengerId", "name phone");

    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    // Build a combined passenger list with drop locations
    const passengersWithDrops = ride.passengers.map((passenger, index) => {
      const dropInfo = ride.passengerDropLocations.find(
        d => d.passengerId && d.passengerId._id.toString() === passenger._id.toString()
      );
      return {
        _id: passenger._id,
        name: passenger.name,
        phone: passenger.phone,
        pickupLocation: dropInfo ? dropInfo.pickupLocation : "",
        dropLocation: dropInfo ? dropInfo.dropLocation : "",
        dropOrder: index + 1,
      };
    });

    res.status(200).json({
      rideId: ride._id,
      source: ride.source,
      destination: ride.destination,
      status: ride.status,
      availableSeats: ride.availableSeats,
      driver: ride.driverId,
      passengers: passengersWithDrops,
      totalPassengers: passengersWithDrops.length,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch ride passengers", details: error.message });
  }
};

// Start trip (driver begins driving)
exports.startTrip = async (req, res) => {
  try {
    const { rideId } = req.body;

    if (!rideId) {
      return res.status(400).json({ error: "Missing rideId" });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    if (ride.status !== "active") {
      return res.status(400).json({ error: "Ride is not in active state" });
    }

    ride.status = "in_progress";
    await ride.save();

    // Notify all passengers that the ride has started
    if (req.io) {
      ride.passengers.forEach(passengerId => {
        req.io.to(`passenger_${passengerId}`).emit("ride_started", {
          message: "Your ride has started!",
          rideId: ride._id,
        });
      });
    }

    res.status(200).json({ message: "Trip started successfully", ride });
  } catch (error) {
    res.status(500).json({ error: "Failed to start trip", details: error.message });
  }
};

// Complete ride
exports.completeRide = async (req, res) => {
  try {
    const { rideId } = req.body;

    if (!rideId) {
      return res.status(400).json({ error: "Missing rideId" });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    ride.status = "completed";
    await ride.save();

    // Notify all passengers that the ride is completed
    if (req.io) {
      ride.passengers.forEach(passengerId => {
        req.io.to(`passenger_${passengerId}`).emit("ride_completed", {
          message: "Your ride has been completed!",
          rideId: ride._id,
        });
      });
    }

    res.status(200).json({ message: "Ride completed successfully", ride });
  } catch (error) {
    res.status(500).json({ error: "Failed to complete ride", details: error.message });
  }
};

// Update driver location
exports.updateLocation = async (req, res) => {
  try {
    const { rideId, lat, lng } = req.body;

    if (!rideId || lat === undefined || lng === undefined) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    // Persist driver location to DB
    ride.driverLocation = { lat, lng };
    await ride.save();

    // Emit location update to all passengers in this ride
    if (req.io) {
      ride.passengers.forEach(passengerId => {
        req.io.to(`passenger_${passengerId}`).emit("location_update", {
          rideId,
          location: { lat, lng },
        });
      });
    }

    res.status(200).json({ message: "Location updated successfully" });
  } catch (error) {
    res.status(500).json({ error: "Failed to update location", details: error.message });
  }
};
