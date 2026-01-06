// index.js
const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();
const port = 3000;

// ✅ Enable CORS (allow requests from Flutter Web)
app.use(cors({
  origin: '*',   // you can restrict to your Flutter web URL if you want
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type'],
}));

// ✅ Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUD_NAME,
  api_key: process.env.CLOUD_API_KEY,
  api_secret: process.env.CLOUD_API_SECRET,
});

// ✅ Setup Multer storage with Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'encrypted_uploads',
    resource_type: 'raw', // important: store encrypted files as raw
  },
});

const upload = multer({ storage });

// ✅ Upload route
app.post('/upload', upload.single('file'), (req, res) => {
  try {
    res.json(req.file);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Server listening on ${port}`);
});
