const mongoose = require('mongoose');

// Join collection: resep mana yang disimpan/favoritkan oleh user mana
const favoriteSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    recipeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe', required: true },
  },
  { timestamps: true }
);

// Satu user tidak bisa memfavoritkan resep yang sama dua kali
favoriteSchema.index({ userId: 1, recipeId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);
