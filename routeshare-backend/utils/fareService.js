const dns = require('dns');

// Helper to convert degrees to radians
function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

// Haversine formula to compute straight-line distance between two coordinates in km
function getHaversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the Earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// 1. Geocode address using OpenStreetMap Nominatim
async function getCoordinates(address) {
  if (!address || address.trim() === "") return null;
  
  // Clean address for query
  const cleanAddress = address.trim();
  const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(cleanAddress)}&format=json&limit=1`;
  
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'RouteSharingApp/1.0' // Required by Nominatim policy
      },
      signal: AbortSignal.timeout(5000) // 5s timeout
    });
    
    if (response.ok) {
      const data = await response.json();
      if (data && data.length > 0) {
        return {
          latitude: parseFloat(data[0].lat),
          longitude: parseFloat(data[0].lon)
        };
      }
    }
  } catch (e) {
    console.error(`[FareService] Geocoding error for '${address}':`, e.message);
  }
  return null;
}

// 2. Fetch driving distance and duration from OSRM
async function getDrivingDistance(startLat, startLng, endLat, endLng) {
  const url = `https://router.project-osrm.org/route/v1/driving/${startLng},${startLat};${endLng},${endLat}?overview=false`;
  
  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(5000) // 5s timeout
    });
    
    if (response.ok) {
      const data = await response.json();
      if (data && data.routes && data.routes.length > 0) {
        return {
          distance: data.routes[0].distance / 1000.0, // convert meters to km
          duration: data.routes[0].duration / 60.0    // convert seconds to mins
        };
      }
    }
  } catch (e) {
    console.error("[FareService] OSRM routing error, falling back to Haversine:", e.message);
  }
  
  // Fallback to Haversine straight-line distance if OSRM fails
  const haversineDist = getHaversineDistance(startLat, startLng, endLat, endLng);
  // Estimate duration assuming 30 km/h average speed in city
  const estimatedDuration = (haversineDist / 30) * 60;
  return {
    distance: haversineDist,
    duration: estimatedDuration
  };
}

// 3. Main backend route service: geocode and route in one go
async function calculateRoute(sourceAddress, destinationAddress) {
  try {
    console.log(`[FareService] Calculating route from '${sourceAddress}' to '${destinationAddress}'`);
    const startCoords = await getCoordinates(sourceAddress);
    const endCoords = await getCoordinates(destinationAddress);
    
    if (startCoords && endCoords) {
      const routeInfo = await getDrivingDistance(
        startCoords.latitude, startCoords.longitude,
        endCoords.latitude, endCoords.longitude
      );
      if (routeInfo) {
        return routeInfo;
      }
    }
  } catch (e) {
    console.error("[FareService] Route calculation failed entirely:", e.message);
  }
  
  // Final fallback (e.g. if geocoding completely fails or no internet)
  // Let's assume a default route distance of 10.0 km and 25 mins
  return {
    distance: 10.0,
    duration: 25.0
  };
}

/**
 * Calculates dynamic fares and splits.
 * Base pricing: ₹40 base + ₹12/km.
 * Split discounts:
 *  - 1 passenger: 100% of solo fare
 *  - 2 passengers: 70% of solo fare (30% savings)
 *  - 3 passengers: 55% of solo fare (45% savings)
 *  - 4+ passengers: 40% of solo fare (60% savings)
 */
function calculatePassengerFare(distance, totalPassengerCount) {
  const soloFare = Math.round(40 + 12 * distance);
  let discountFactor = 1.0;
  
  if (totalPassengerCount === 2) {
    discountFactor = 0.70; // 30% discount
  } else if (totalPassengerCount === 3) {
    discountFactor = 0.55; // 45% discount
  } else if (totalPassengerCount >= 4) {
    discountFactor = 0.40; // 60% discount
  }
  
  const sharedFare = Math.round(soloFare * discountFactor);
  const savings = soloFare - sharedFare;
  
  return {
    distance,
    soloFare,
    sharedFare,
    savings
  };
}

/**
 * Dynamic recalculation of all fares inside a ride
 */
async function recalculateRideFares(ride) {
  const passengersCount = ride.passengers ? ride.passengers.length : 0;
  console.log(`[FareService] Recalculating fares for ride ${ride._id}. Passengers count: ${passengersCount}`);
  
  let totalFares = 0;
  
  // 1. Recalculate each passenger's distance and fares
  for (let i = 0; i < ride.passengerDropLocations.length; i++) {
    const drop = ride.passengerDropLocations[i];
    
    // If distance is not yet computed, compute it
    if (!drop.distance || drop.distance === 0) {
      const route = await calculateRoute(drop.pickupLocation, drop.dropLocation);
      drop.distance = parseFloat(route.distance.toFixed(2));
    }
    
    // Compute split fare based on the current active passenger count
    const fareDetails = calculatePassengerFare(drop.distance, passengersCount);
    drop.soloFare = fareDetails.soloFare;
    drop.sharedFare = fareDetails.sharedFare;
    drop.savings = fareDetails.savings;
    
    totalFares += drop.sharedFare;
  }
  
  // 2. Compute driver earnings & platform commission (90% driver, 10% platform)
  ride.totalFaresCollected = totalFares;
  ride.driverEarnings = Math.round(totalFares * 0.90);
  ride.platformCommission = Math.round(totalFares * 0.10);
  
  return ride;
}

module.exports = {
  calculateRoute,
  calculatePassengerFare,
  recalculateRideFares
};
