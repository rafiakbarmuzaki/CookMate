const mongoose = require('mongoose');

// Selaras dengan lib/models/recipe.dart -> class ChatMessage & enum ChatRole
const chatMessageSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: ['user', 'bot'], required: true },
    text: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
  },
  { timestamps: false }
);

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
