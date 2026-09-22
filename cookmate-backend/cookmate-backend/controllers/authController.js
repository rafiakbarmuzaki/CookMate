const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

function signToken(userId) {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email dan password wajib diisi.' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ message: 'Email sudah terdaftar.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, passwordHash });

    res.status(201).json({
      token: signToken(user._id),
      user: { id: user._id, name: user.name, email: user.email },
    });
  } catch (error) {
    res.status(500).json({ message: 'Gagal mendaftar.', error: error.message });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: (email || '').toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Email atau password salah.' });
    }

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) {
      return res.status(401).json({ message: 'Email atau password salah.' });
    }

    res.json({
      token: signToken(user._id),
      user: { id: user._id, name: user.name, email: user.email },
    });
  } catch (error) {
    res.status(500).json({ message: 'Gagal login.', error: error.message });
  }
};

// GET /api/auth/me
exports.getProfile = async (req, res) => {
  const user = await User.findById(req.userId).select('-passwordHash');
  if (!user) return res.status(404).json({ message: 'Pengguna tidak ditemukan.' });
  res.json(user);
};

// PUT /api/auth/me  (update profil kesehatan, dsb - lihat UserProfile.copyWith di Flutter)
exports.updateProfile = async (req, res) => {
  const allowedFields = [
    'name',
    'gender',
    'age',
    'customMedicalCondition',
    'customAllergy',
    'dietGoal',
    'medicalConditions',
    'foodAllergies',
    'dietGoals',
  ];

  const updates = {};
  for (const field of allowedFields) {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  }

  const user = await User.findByIdAndUpdate(req.userId, updates, {
    new: true,
    runValidators: true,
  }).select('-passwordHash');

  res.json(user);
};
