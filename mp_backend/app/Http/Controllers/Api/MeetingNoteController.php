<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MeetingNote;
use Illuminate\Http\Request;

class MeetingNoteController extends Controller
{
    public function index(Request $request)
    {
        $query = MeetingNote::orderBy('meeting_date', 'desc');

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where(function($q) use ($search) {
                $q->where('meeting_title', 'like', "%{$search}%")
                  ->orWhere('participants', 'like', "%{$search}%")
                  ->orWhere('discussion_points', 'like', "%{$search}%")
                  ->orWhere('decisions', 'like', "%{$search}%")
                  ->orWhere('action_items', 'like', "%{$search}%");
            });
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'appointment_id'    => 'nullable|integer',
            'meeting_title'     => 'required|string',
            'meeting_date'      => 'required|date',
            'participants'      => 'required|string',
            'discussion_points' => 'required|string',
            'decisions'         => 'required|string',
            'action_items'      => 'required|string',
            'follow_up_date'    => 'nullable|date',
        ]);

        $note = MeetingNote::create($validated);

        return response()->json($note, 201);
    }

    public function showByAppointment($appointmentId)
    {
        $notes = MeetingNote::where('appointment_id', $appointmentId)
            ->orderBy('meeting_date', 'desc')
            ->get();

        return response()->json($notes);
    }
}
