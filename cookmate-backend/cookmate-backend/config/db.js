const mongoose = require('mongoose');

async function connectDB() {
  try {
    const uri = process.env.MONGODB_URI;
    if (!uri) {
      throw new Error('MONGODB_URI belum diatur di file .env');
    }

    await mongoose.connect(uri);
    console.log(`MongoDB Atlas terhubung: ${mongoose.connection.host}`);
  } catch (error) {
    console.error(`Gagal konek ke MongoDB Atlas: ${error.message}`);
    process.exit(1);
  }
}

module.exports = connectDB;
