const express = require('express');
const router = express.Router();
const protect = require('../middleware/auth');
const { register, login, getProfile, updateProfile } = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getProfile);
router.put('/me', protect, updateProfile);

module.exports = router;
