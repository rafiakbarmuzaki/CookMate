const ChatMessage = require('../models/ChatMessage');

// POST /api/chat  -> simpan pesan dari CookMate Bot (user & bot)
exports.saveMessage = async (req, res) => {
  try {
    const { role, text } = req.body;
    if (!role || !text) {
      return res.status(400).json({ message: 'role dan text wajib diisi.' });
    }

    const message = await ChatMessage.create({ userId: req.userId, role, text });
    res.status(201).json(message);
  } catch (error) {
    res.status(400).json({ message: 'Gagal menyimpan pesan.', error: error.message });
  }
};

// GET /api/chat/history  -> riwayat chat untuk ditampilkan lagi di FAB Chat
exports.getHistory = async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 50, 200);
  const messages = await ChatMessage.find({ userId: req.userId })
    .sort({ timestamp: 1 })
    .limit(limit);
  res.json(messages);
};

// DELETE /api/chat/history
exports.clearHistory = async (req, res) => {
  await ChatMessage.deleteMany({ userId: req.userId });
  res.json({ message: 'Riwayat chat dihapus.' });
};
