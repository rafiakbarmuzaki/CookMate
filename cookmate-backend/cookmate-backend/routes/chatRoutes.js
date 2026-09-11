const express = require('express');
const router = express.Router();
const protect = require('../middleware/auth');
const { saveMessage, getHistory, clearHistory } = require('../controllers/chatController');

router.use(protect);

router.post('/', saveMessage);
router.get('/history', getHistory);
router.delete('/history', clearHistory);

module.exports = router;
