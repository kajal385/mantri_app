<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TestController;
use App\Http\Controllers\Api\ComplaintController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\NewsController;
use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\FeedbackController;
use App\Http\Controllers\Api\ScheduleController;
use App\Http\Controllers\Api\SliderController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\PaProfileController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\DelegatedTaskController;
use App\Http\Controllers\Api\MeetingNoteController;
use App\Http\Controllers\Api\DonationController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// ──────────────────────────────────────────────────────────────────
// Public citizen routes — no Sanctum token required
// ──────────────────────────────────────────────────────────────────
Route::get('/citizen-appointments', [AppointmentController::class, 'citizenAppointments']);
Route::get('/appointment-slots', [App\Http\Controllers\Api\PaAvailabilityController::class, 'nextAvailableSlots']);
Route::get('/appointment-issues', [App\Http\Controllers\Api\AppointmentIssueController::class, 'index']);
Route::post('/appointments', [AppointmentController::class, 'store']);
Route::get('/feedback-project-categories', [App\Http\Controllers\Api\FeedbackProjectCategoryController::class, 'index']);
Route::post('/feedback', [FeedbackController::class, 'store']);
Route::get('/complaints', [ComplaintController::class, 'index']);
Route::post('/complaints', [ComplaintController::class, 'store']);
Route::get('/events', [EventController::class, 'index']);
Route::get('/news', [App\Http\Controllers\Api\NewsPostController::class, 'index']);
Route::get('/news-categories', [App\Http\Controllers\Api\NewsCategoryController::class, 'index']);
Route::get('/news/{id}', [App\Http\Controllers\Api\NewsPostController::class, 'show']);
Route::get('/projects', [ProjectController::class, 'index']);
Route::get('/schedules', [ScheduleController::class, 'index']);
Route::get('/slider-images', [SliderController::class, 'index']);
Route::get('/mp-profile', [AuthController::class, 'mpProfile']);
Route::get('/social-links', [App\Http\Controllers\Api\SocialLinkController::class, 'index']);
Route::get('/emergency-contacts', [App\Http\Controllers\Api\EmergencyContactController::class, 'index']);
Route::get('/departments', [App\Http\Controllers\Api\DepartmentController::class, 'index']);
Route::get('/officials', [App\Http\Controllers\Api\OfficialController::class, 'index']);
Route::get('/test-connection', [TestController::class, 'index']);
Route::get('/custom-locations', [App\Http\Controllers\Api\LocationController::class, 'index']);

// Public message submission
Route::post('/messages', [MessageController::class, 'store']);

// ──────────────────────────────────────────────────────────────────
// Protected routes — require Sanctum token (admin / PA)
// ──────────────────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Custom Locations
    Route::post('/custom-cities', [App\Http\Controllers\Api\LocationController::class, 'storeCity']);
    Route::post('/custom-villages', [App\Http\Controllers\Api\LocationController::class, 'storeVillage']);

    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::patch('/user/profile', [AuthController::class, 'updateProfile']);

    // File upload
    Route::post('/upload', [UploadController::class, 'store']);
    Route::post('/upload-video', [UploadController::class, 'storeVideo']);

    // PA Availability Management
    Route::get('/pa-availabilities', [App\Http\Controllers\Api\PaAvailabilityController::class, 'index']);
    Route::post('/pa-availabilities', [App\Http\Controllers\Api\PaAvailabilityController::class, 'store']);
    Route::delete('/pa-availabilities/{id}', [App\Http\Controllers\Api\PaAvailabilityController::class, 'destroy']);

    // Appointments (admin/PA management)
    Route::post('/appointment-issues', [App\Http\Controllers\Api\AppointmentIssueController::class, 'store']);
    Route::get('/appointments', [AppointmentController::class, 'index']);
    Route::get('/my-appointments', [AppointmentController::class, 'userAppointments']);
    Route::patch('/appointments/{id}/status', [AppointmentController::class, 'updateStatus']);
    Route::patch('/appointments/{id}/priority', [AppointmentController::class, 'updatePriority']);
    Route::patch('/appointments/{id}/follow-up', [AppointmentController::class, 'updateFollowUp']);
    Route::put('/appointments/{id}', [AppointmentController::class, 'update']);
    Route::delete('/appointments/{id}', [AppointmentController::class, 'destroy']);

    // Complaints (admin/PA management)
    Route::patch('/complaints/{id}/status', [ComplaintController::class, 'updateStatus']);
    Route::patch('/complaints/{id}/priority', [ComplaintController::class, 'updatePriority']);
    Route::patch('/complaints/{id}/follow-up', [ComplaintController::class, 'updateFollowUp']);
    Route::delete('/complaints/{id}', [ComplaintController::class, 'destroy']);

    // Messages management
    Route::get('/messages', [MessageController::class, 'index']);
    Route::patch('/messages/{id}/status', [MessageController::class, 'updateStatus']);
    Route::patch('/messages/{id}/priority', [MessageController::class, 'updatePriority']);
    Route::patch('/messages/{id}/follow-up', [MessageController::class, 'updateFollowUp']);
    Route::delete('/messages/{id}', [MessageController::class, 'destroy']);

    // Delegated Tasks
    Route::get('/delegated-tasks', [DelegatedTaskController::class, 'index']);
    Route::post('/delegated-tasks', [DelegatedTaskController::class, 'store']);
    Route::put('/delegated-tasks/{id}', [DelegatedTaskController::class, 'update']);
    Route::delete('/delegated-tasks/{id}', [DelegatedTaskController::class, 'destroy']);

    // Meeting Notes
    Route::get('/meeting-notes', [MeetingNoteController::class, 'index']);
    Route::post('/meeting-notes', [MeetingNoteController::class, 'store']);
    Route::get('/meeting-notes/appointment/{appointmentId}', [MeetingNoteController::class, 'showByAppointment']);

    // Donations
    Route::get('/donations', [DonationController::class, 'index']);
    Route::post('/donations', [DonationController::class, 'store']);
    Route::get('/donations/summary', [DonationController::class, 'summary']);

    // News (admin/PA only for write, citizens can rsvp)
    Route::post('/news', [App\Http\Controllers\Api\NewsPostController::class, 'store']);
    Route::put('/news/{id}', [App\Http\Controllers\Api\NewsPostController::class, 'update']);
    Route::delete('/news/{id}', [App\Http\Controllers\Api\NewsPostController::class, 'destroy']);
    Route::post('/news/{id}/rsvp', [App\Http\Controllers\Api\NewsPostController::class, 'rsvp']);
    Route::get('/news/{id}/rsvps', [App\Http\Controllers\Api\NewsPostController::class, 'getRsvps']);


    // Social Links (admin/PA only)
    Route::put('/social-links', [App\Http\Controllers\Api\SocialLinkController::class, 'update']);

    // Emergency Contacts (admin/PA only)
    Route::get('/emergency-contacts/all', [App\Http\Controllers\Api\EmergencyContactController::class, 'all']);
    Route::post('/emergency-contacts', [App\Http\Controllers\Api\EmergencyContactController::class, 'store']);
    Route::put('/emergency-contacts/{id}', [App\Http\Controllers\Api\EmergencyContactController::class, 'update']);
    Route::delete('/emergency-contacts/{id}', [App\Http\Controllers\Api\EmergencyContactController::class, 'destroy']);

    // Departments (admin/PA only for write)
    Route::post('/departments', [App\Http\Controllers\Api\DepartmentController::class, 'store']);
    Route::put('/departments/{id}', [App\Http\Controllers\Api\DepartmentController::class, 'update']);
    Route::delete('/departments/{id}', [App\Http\Controllers\Api\DepartmentController::class, 'destroy']);

    // Officials (admin/PA only for write)
    Route::post('/officials', [App\Http\Controllers\Api\OfficialController::class, 'store']);
    Route::put('/officials/{id}', [App\Http\Controllers\Api\OfficialController::class, 'update']);
    Route::delete('/officials/{id}', [App\Http\Controllers\Api\OfficialController::class, 'destroy']);

    // Events (admin/PA management)
    Route::post('/events', [EventController::class, 'store']);
    Route::delete('/events/{id}', [EventController::class, 'destroy']);

    // Projects (admin/PA only - creation and deletion)
    Route::post('/projects', [ProjectController::class, 'store']);
    Route::delete('/projects/{id}', [ProjectController::class, 'destroy']);

    // Feedback (admin/PA read and delete)
    Route::post('/feedback-project-categories', [App\Http\Controllers\Api\FeedbackProjectCategoryController::class, 'store']);
    Route::get('/feedback', [FeedbackController::class, 'index']);
    Route::delete('/feedback/{id}', [FeedbackController::class, 'destroy']);

    // Schedules (admin/PA management)
    Route::post('/schedules', [ScheduleController::class, 'store']);
    Route::delete('/schedules/{id}', [ScheduleController::class, 'destroy']);

    // Slider Images (admin/PA management)
    Route::post('/slider-images', [SliderController::class, 'store']);
    Route::delete('/slider-images', [SliderController::class, 'destroy']);

    // Schedules status update
    Route::patch('/schedules/{id}/status', [ScheduleController::class, 'updateStatus']);

    // PA staff management
    Route::post('/register-pa', [AuthController::class, 'registerPa']);
    Route::get('/pa-profiles', [PaProfileController::class, 'index']);
    Route::post('/pa-profiles', [PaProfileController::class, 'store']);
    Route::get('/pa-profiles/{uid}', [PaProfileController::class, 'show']);
    Route::put('/pa-profiles/{uid}', [PaProfileController::class, 'update']);
    Route::patch('/pa-profiles/{uid}', [PaProfileController::class, 'update']);
    Route::patch('/pa-profiles/{uid}/status', [PaProfileController::class, 'updateStatus']);
    Route::delete('/pa-profiles/{uid}', [PaProfileController::class, 'destroy']);
});
