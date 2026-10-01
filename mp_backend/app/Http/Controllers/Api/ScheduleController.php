<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    public function index(Request $request)
    {
        $query = \App\Models\Schedule::orderBy('date', 'asc');

        if ($request->has('start') && $request->has('end')) {
            $start = \Carbon\Carbon::parse($request->query('start'))->startOfDay();
            $end = \Carbon\Carbon::parse($request->query('end'))->endOfDay();
            $query->whereBetween('date', [$start, $end]);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'type' => 'required|string',
            'time' => 'required|string',
            'date' => 'required|date',
            'description' => 'required|string',
            'organizerName' => 'nullable|string',
            'organizerContact' => 'nullable|string',
            'imageUrl' => 'nullable|string',
            'location' => 'nullable|string',
            'mapUrl' => 'nullable|string',
            'status' => 'nullable|string',
        ]);

        $date = \Carbon\Carbon::parse($validated['date']);
        $timeStr = $validated['time'];
        try {
            $dateTime = \Carbon\Carbon::parse($date->format('Y-m-d') . ' ' . $timeStr);
            if ($dateTime->isPast()) {
                return response()->json(['message' => 'Please select today\'s or a future date and time.'], 422);
            }
        } catch (\Exception $e) {
            // Ignore parse errors here if format is completely custom, though standard format is handled well by Carbon
        }

        $schedule = \App\Models\Schedule::create([
            'title' => $validated['title'],
            'type' => $validated['type'],
            'time' => $validated['time'],
            'date' => \Carbon\Carbon::parse($validated['date']),
            'description' => $validated['description'],
            'organizerName' => $validated['organizerName'] ?? null,
            'organizerContact' => $validated['organizerContact'] ?? null,
            'imageUrl' => $validated['imageUrl'] ?? null,
            'location' => $validated['location'] ?? null,
            'mapUrl' => $validated['mapUrl'] ?? null,
            'status' => $validated['status'] ?? 'pending',
        ]);

        return response()->json($schedule, 201);
    }

    public function updateStatus($id, Request $request)
    {
        $schedule = \App\Models\Schedule::findOrFail($id);
        $schedule->status = $request->input('status', 'pending');
        $schedule->save();

        return response()->json($schedule);
    }

    public function destroy($id)
    {
        $schedule = \App\Models\Schedule::findOrFail($id);
        $schedule->delete();

        return response()->json(['message' => 'Schedule item deleted successfully']);
    }
}
