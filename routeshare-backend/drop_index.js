const mongoose = require("mongoose");
require("dotenv").config();

async function dropIndex() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB.");

    const db = mongoose.connection.db;
    
    // Check if the collection exists
    const collections = await db.listCollections({ name: 'users' }).toArray();
    if (collections.length > 0) {
      // Try to drop the index
      try {
        await db.collection("users").dropIndex("phone_1");
        console.log("Successfully dropped index 'phone_1' from 'users' collection.");
      } catch (err) {
        if (err.codeName === 'IndexNotFound') {
          console.log("Index 'phone_1' not found, maybe already dropped.");
        } else {
          console.error("Error dropping index:", err);
        }
      }
    } else {
      console.log("Collection 'users' does not exist yet.");
    }
  } catch (err) {
    console.error("Connection error:", err);
  } finally {
    await mongoose.disconnect();
    console.log("Disconnected from MongoDB.");
  }
}

dropIndex();
