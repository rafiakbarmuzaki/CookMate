const mongoose = require('mongoose');

// Selaras dengan lib/models/recipe.dart di frontend Flutter
const ingredientSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    amount: { type: String, default: '' },
  },
  { _id: false }
);

const nutritionSchema = new mongoose.Schema(
  {
    calories: { type: String, default: '-' },
    protein: { type: String, default: '-' },
    carbs: { type: String, default: '-' },
    fat: { type: String, default: '-' },
  },
  { _id: false }
);

const recipeSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    title: { type: String, required: true },
    description: { type: String, default: '' },
    difficulty: { type: String, enum: ['Mudah', 'Sedang', 'Sulit'], default: 'Mudah' },
    time: { type: String, default: '-' },
    servings: { type: String, default: '-' },
    tags: { type: [String], default: [] },
    matchPercent: { type: Number, default: 90 },

    ingredientsOwned: { type: [ingredientSchema], default: [] },
    ingredientsToBuy: { type: [ingredientSchema], default: [] },
    steps: { type: [String], default: [] },
    nutrition: { type: nutritionSchema, default: () => ({}) },
    aiTips: { type: [String], default: [] },
    healthWarning: { type: String, default: null },
    imageQuery: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Recipe', recipeSchema);
