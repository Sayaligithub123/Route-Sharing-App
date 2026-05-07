const express = require("express");
const router = express.Router();
const rideController = require("../controllers/rideController");

// Ride Routes
router.post("/start", rideController.startRide);
router.get("/search", rideController.searchRides);
router.post("/request", rideController.requestToJoin);
router.post("/respond", rideController.respondToRequest);
router.get("/request-status/:id", rideController.getRequestStatus);
router.post("/update-location", rideController.updateLocation);

// New routes for ride lifecycle
router.get("/ride/:id", rideController.getRideDetails);
router.get("/ride/:id/passengers", rideController.getRidePassengers);
router.post("/start-trip", rideController.startTrip);
router.post("/complete-ride", rideController.completeRide);

module.exports = router;
