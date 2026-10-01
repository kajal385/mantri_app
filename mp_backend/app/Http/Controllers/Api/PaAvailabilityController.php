<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaAvailability;
use App\Models\Appointment;
use Illuminate\Http\Request;
use Carbon\Carbon;

class PaAvailabilityController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $availabilities = PaAvailability::orderBy('date', 'desc')->get();
        return $this->successResponse($availabilities, 'Availabilities fetched successfully');
    }

    /**
     * Store or update availability for a specific date.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'is_available' => 'required|boolean',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after:start_time',
        ]);

        $availability = PaAvailability::updateOrCreate(
            ['date' => $validated['date']],
            [
                'is_available' => $validated['is_available'],
                'start_time' => $validated['start_time'],
                'end_time' => $validated['end_time'],
            ]
        );

        return $this->successResponse($availability, 'Availability updated successfully', 201);
    }

    /**
     * Remove the specified availability.
     */
    public function destroy($id)
    {
        $availability = PaAvailability::findOrFail($id);
        $availability->delete();

        return $this->successResponse(null, 'Availability deleted successfully');
    }

    /**
     * Get the next available date and slots for citizens to book.
     */
    public function nextAvailableSlots()
    {
        $today = Carbon::today()->toDateString();
        
        $availabilities = PaAvailability::where('date', '>=', $today)
            ->where('is_available', true)
            ->orderBy('date', 'asc')
            ->get();

        foreach ($availabilities as $availability) {
            if (!$availability->start_time || !$availability->end_time) {
                continue;
            }

            $dateString = $availability->date->toDateString();
            $startTime = Carbon::parse($availability->start_time);
            $endTime = Carbon::parse($availability->end_time);

            $slots = [];
            $currentTime = $startTime->copy();

            while ($currentTime->lt($endTime)) {
                // Ensure time string generated here matches what is stored in appointments table (e.g. 1:00 PM vs 01:00 PM)
                $slotString = $currentTime->format('g:i A'); // 1:00 PM
                $slots[] = $slotString;
                $currentTime->addMinutes(15);
            }

            $bookedAppointments = Appointment::whereDate('date', $dateString)
                ->whereNotIn('status', ['rejected', 'cancelled'])
                ->pluck('time')
                ->toArray();

            $availableSlots = array_values(array_diff($slots, $bookedAppointments));

            // If this date has at least one available slot, return it
            if (count($availableSlots) > 0) {
                return $this->successResponse([
                    'date' => $dateString,
                    'slots' => $availableSlots
                ], 'Next available slots fetched successfully');
            }
        }

        // If loop completes without returning, no dates have available slots
        return $this->successResponse([
            'date' => null,
            'slots' => []
        ], 'No availabilities found');
    }
}
