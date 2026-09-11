const express = require('express');
const router = express.Router();
const protect = require('../middleware/auth');
const {
  createRecipe,
  getMyRecipes,
  getRecipeById,
  deleteRecipe,
  addFavorite,
  removeFavorite,
  getFavorites,
} = require('../controllers/recipeController');

router.use(protect);

router.get('/favorites/list', getFavorites);
router.post('/', createRecipe);
router.get('/', getMyRecipes);
router.get('/:id', getRecipeById);
router.delete('/:id', deleteRecipe);
router.post('/:id/favorite', addFavorite);
router.delete('/:id/favorite', removeFavorite);

module.exports = router;
