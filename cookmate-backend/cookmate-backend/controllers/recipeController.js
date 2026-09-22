const Recipe = require('../models/Recipe');
const Favorite = require('../models/Favorite');

// POST /api/recipes  -> simpan hasil generate Gemini dari HomePage/RecipeResults
exports.createRecipe = async (req, res) => {
  try {
    const recipe = await Recipe.create({ ...req.body, userId: req.userId });
    res.status(201).json(recipe);
  } catch (error) {
    res.status(400).json({ message: 'Gagal menyimpan resep.', error: error.message });
  }
};

// GET /api/recipes  -> riwayat resep milik user yang login
exports.getMyRecipes = async (req, res) => {
  const recipes = await Recipe.find({ userId: req.userId }).sort({ createdAt: -1 });
  res.json(recipes);
};

// GET /api/recipes/:id
exports.getRecipeById = async (req, res) => {
  const recipe = await Recipe.findOne({ _id: req.params.id, userId: req.userId });
  if (!recipe) return res.status(404).json({ message: 'Resep tidak ditemukan.' });
  res.json(recipe);
};

// DELETE /api/recipes/:id
exports.deleteRecipe = async (req, res) => {
  const recipe = await Recipe.findOneAndDelete({ _id: req.params.id, userId: req.userId });
  if (!recipe) return res.status(404).json({ message: 'Resep tidak ditemukan.' });
  await Favorite.deleteMany({ recipeId: recipe._id });
  res.json({ message: 'Resep dihapus.' });
};

// POST /api/recipes/:id/favorite  -> tandai favorit (isSaved di Flutter)
exports.addFavorite = async (req, res) => {
  try {
    const favorite = await Favorite.create({ userId: req.userId, recipeId: req.params.id });
    res.status(201).json(favorite);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ message: 'Resep sudah ada di favorit.' });
    }
    res.status(400).json({ message: 'Gagal menambah favorit.', error: error.message });
  }
};

// DELETE /api/recipes/:id/favorite
exports.removeFavorite = async (req, res) => {
  await Favorite.findOneAndDelete({ userId: req.userId, recipeId: req.params.id });
  res.json({ message: 'Resep dihapus dari favorit.' });
};

// GET /api/recipes/favorites/list
exports.getFavorites = async (req, res) => {
  const favorites = await Favorite.find({ userId: req.userId }).populate('recipeId');
  res.json(favorites.map((f) => f.recipeId));
};
