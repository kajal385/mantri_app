<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\User;
use App\Helpers\PriorityScorer;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AppointmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Appointment::orderBy('date', 'desc')->orderBy('time', 'asc');

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        return $this->successResponse($query->get(), 'Appointments fetched successfully');
    }

    public function userAppointments(Request $request)
    {
        $userId = (string) $request->user()->id;

        $appointments = Appointment::where('userId', $userId)
            ->orderBy('date', 'desc')
            ->get();

        return $this->successResponse($appointments, 'User appointments fetched successfully');
    }

    public function citizenAppointments(Request $request)
    {
        $userId = $request->query('userId');

        if (!$userId) {
            return response()->json(['error' => 'userId is required'], 422);
        }

        $appointments = Appointment::where('userId', $userId)
            ->orderBy('date', 'desc')
            ->get();

        return $this->successResponse($appointments, 'Citizen appointments fetched successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'userId' => 'required|string',
            'userName' => 'required|string',
            'issue' => 'required|string',
            'date' => 'required|date',
            'time' => 'required|string',
            'phone' => 'nullable|string',
            'priority' => 'nullable|string',
            'is_senior_citizen' => 'nullable|boolean',
            'is_media_contact' => 'nullable|boolean',
        ]);

        $existing = Appointment::where('date', $validated['date'])
            ->where('time', $validated['time'])
            ->whereNotIn('status', ['rejected', 'cancelled'])
            ->exists();

        if ($existing) {
            return $this->errorResponse('This slot is already booked.', 409);
        }

        $userId = $validated['userId'];
        $user = User::find($userId);
        $email = $user ? $user->email : null;
        $isSenior = $request->boolean('is_senior_citizen');
        $isMedia = $request->boolean('is_media_contact');

        if ($user && $user->dob) {
            try {
                if (Carbon::parse($user->dob)->diffInYears() >= 60) {
                    $isSenior = true;
                }
            } catch (\Exception $e) {}
        }

        $priority = $validated['priority'] ?? PriorityScorer::calculateScore(
            $userId,
            $validated['phone'] ?? null,
            $validated['issue'],
            $isSenior,
            $isMedia,
            $email
        );

        $appointment = Appointment::create([
            'userId' => $userId,
            'userName' => $validated['userName'],
            'issue' => $validated['issue'],
            'date' => $validated['date'],
            'time' => $validated['time'],
            'phone' => $validated['phone'],
            'status' => 'pending',
            'priority' => $priority,
            'is_senior_citizen' => $isSenior,
            'is_media_contact' => $isMedia,
        ]);

        return $this->successResponse($appointment, 'Appointment created successfully', 201);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);

        $appointment = Appointment::findOrFail($id);

        $data = ['status' => $request->status];

        if ($request->status === 'approved' && empty($appointment->token)) {
            // Generate token series: MP-AD-01, MP-AD-02...
            $approvedCount = Appointment::whereNotNull('token')
                ->where('token', 'like', 'MP-AD-%')
                ->count();
            $nextNum = sprintf("%02d", $approvedCount + 1);
            $data['token'] = "MP-AD-$nextNum";
        }

        $appointment->update($data);

        return $this->successResponse($appointment, 'Appointment status updated successfully');
    }

    public function updatePriority(Request $request, $id)
    {
        $request->validate(['priority' => 'required|string']);
        $appointment = Appointment::findOrFail($id);
        $appointment->update(['priority' => $request->priority]);
        return $this->successResponse($appointment, 'Appointment priority updated successfully');
    }

    public function updateFollowUp(Request $request, $id)
    {
        $validated = $request->validate([
            'follow_up_date' => 'nullable|date',
            'reminder_date'  => 'nullable|date',
            'status'         => 'nullable|string',
            'is_escalated'   => 'nullable|boolean',
            'escalated_to'   => 'nullable|string',
        ]);

        $appointment = Appointment::findOrFail($id);
        $appointment->update($validated);
        return $this->successResponse($appointment, 'Appointment follow up updated successfully');
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'userId' => 'required|string',
            'userName' => 'required|string',
            'issue' => 'required|string',
            'date' => 'required|date',
            'time' => 'required|string',
            'phone' => 'nullable|string',
        ]);

        $appointment = Appointment::findOrFail($id);

        $existing = Appointment::where('date', $validated['date'])
            ->where('time', $validated['time'])
            ->where('id', '!=', $id)
            ->whereNotIn('status', ['rejected', 'cancelled'])
            ->exists();

        if ($existing) {
            return $this->errorResponse('This slot is already booked.', 409);
        }

        $appointment->update($validated);

        return $this->successResponse($appointment, 'Appointment updated successfully');
    }

    public function destroy($id)
    {
        $appointment = Appointment::findOrFail($id);
        $appointment->delete();

        return $this->successResponse(null, 'Appointment deleted successfully');
    }
}
