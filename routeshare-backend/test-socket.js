const { io } = require("socket.io-client");
const http = require("http");

const socket = io("http://localhost:5000");

socket.on("connect", () => {
  console.log("Socket connected:", socket.id);
  
  // Create a driver to test
  createDriverAndRide();
});

const rand = Math.random().toString(36).substring(7);

function createDriverAndRide() {
  const req = http.request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/users/create',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('Driver create response:', data);
      const driver = JSON.parse(data);
      if (!driver._id) {
        console.error("Failed to create driver");
        process.exit(1);
      }
      console.log('Driver created:', driver._id);
      
      // Join socket room
      socket.emit("join_room", { userId: driver._id, role: "Driver" });
      
      socket.on("new_request", (data) => {
        console.log("RECEIVED SOCKET EVENT new_request:", data);
        process.exit(0);
      });
      
      // Start ride
      startRide(driver._id);
    });
  });
  req.write(JSON.stringify({ role: 'Driver', name: 'S Driver', phone: '123' + rand, email: rand + '@gmail.com' }));
  req.end();
}

function startRide(driverId) {
  const req = http.request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/rides/start',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('Ride start response:', data);
      const resp = JSON.parse(data);
      console.log('Ride started:', resp.ride._id);
      
      // Request ride
      requestRide(resp.ride._id, driverId);
    });
  });
  req.write(JSON.stringify({ driverId, source: 'A', destination: 'B', availableSeats: 3 }));
  req.end();
}

function requestRide(rideId, driverId) {
  // Create passenger
  const req = http.request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/users/create',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      const passenger = JSON.parse(data);
      
      // Make request
      const req2 = http.request({
        hostname: 'localhost',
        port: 5000,
        path: '/api/rides/request',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      }, (res2) => {
        let data2 = '';
        res2.on('data', chunk => data2 += chunk);
        res2.on('end', () => {
          console.log('Request sent response:', res2.statusCode, data2);
        });
      });
      req2.write(JSON.stringify({ rideId, passengerId: passenger._id }));
      req2.end();
    });
  });
  req.write(JSON.stringify({ role: 'Passenger', name: 'P', phone: '456' + rand, email: rand + '2@gmail.com' }));
  req.end();
}
