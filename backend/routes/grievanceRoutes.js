const express = require('express');
const router = express.Router();
const grievanceController = require('../controllers/grievanceController');

router.post('/', grievanceController.createGrievance);
router.get('/', grievanceController.getGrievances);
router.get('/:id', grievanceController.getGrievanceById);
router.put('/:id', grievanceController.updateGrievance);
router.delete('/:id', grievanceController.deleteGrievance);

module.exports = router;
