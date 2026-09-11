const mongoose = require('mongoose');

// Selaras dengan lib/models/user_profile.dart di frontend Flutter
const userSchema = new mongoose.Schema(
  {
    name: { type: String, default: 'Pengguna CookMate' },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },

    gender: { type: String, enum: ['Pria', 'Wanita', null], default: null },
    age: { type: Number, default: null },
    customMedicalCondition: { type: String, default: null },
    customAllergy: { type: String, default: null },
    dietGoal: { type: String, default: null },

    medicalConditions: { type: [String], default: [] },
    foodAllergies: { type: [String], default: [] },
    dietGoals: { type: [String], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
