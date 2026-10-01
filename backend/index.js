const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
dotenv.config();
const app = express();

app.use(cors());
app.use(bodyParser.json());
// Database config is handled in config/firebase.js

// Routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const appointmentRoutes = require('./routes/appointmentRoutes');
const grievanceRoutes = require('./routes/grievanceRoutes');
const projectRoutes = require('./routes/projectRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/grievances', grievanceRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/notifications', notificationRoutes);

// Database check middleware (optional, to verify db connection)
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'Server is running', active: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
