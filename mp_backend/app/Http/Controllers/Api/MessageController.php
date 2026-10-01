<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CitizenMessage;
use App\Helpers\PriorityScorer;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function index(Request $request)
    {
        $query = CitizenMessage::orderBy('created_at', 'desc');

        if ($request->has('userId')) {
            $query->where('userId', $request->query('userId'));
        }

        if ($request->has('status') && $request->query('status') !== 'all') {
            $query->where('status', $request->query('status'));
        }

        if ($request->has('priority') && $request->query('priority') !== 'all') {
            $query->where('priority', $request->query('priority'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'userId'            => 'nullable|string',
            'userName'          => 'required|string',
            'userEmail'         => 'required|email',
            'phone'             => 'nullable|string',
            'subject'           => 'required|string',
            'body'              => 'required|string',
            'priority'          => 'nullable|string',
            'status'            => 'nullable|string',
            'is_senior_citizen' => 'nullable|boolean',
            'is_media_contact'  => 'nullable|boolean',
            'follow_up_date'    => 'nullable|date',
            'reminder_date'     => 'nullable|date',
        ]);

        $isSenior = $request->boolean('is_senior_citizen');
        $isMedia = $request->boolean('is_media_contact');

        // Automatically calculate priority if not provided
        $priority = $validated['priority'] ?? PriorityScorer::calculateScore(
            $validated['userId'] ?? null,
            $validated['phone'] ?? null,
            $validated['subject'] . ' ' . $validated['body'],
            $isSenior,
            $isMedia,
            $validated['userEmail']
        );

        $message = CitizenMessage::create([
            'userId'            => $validated['userId'] ?? null,
            'userName'          => $validated['userName'],
            'userEmail'         => $validated['userEmail'],
            'phone'             => $validated['phone'] ?? null,
            'subject'           => $validated['subject'],
            'body'              => $validated['body'],
            'priority'          => $priority,
            'status'            => $validated['status'] ?? 'Pending',
            'is_senior_citizen' => $isSenior,
            'is_media_contact'  => $isMedia,
            'follow_up_date'    => $validated['follow_up_date'] ?? null,
            'reminder_date'     => $validated['reminder_date'] ?? null,
        ]);

        return response()->json($message, 201);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);
        $message = CitizenMessage::findOrFail($id);
        $message->update(['status' => $request->status]);
        return response()->json($message);
    }

    public function updatePriority(Request $request, $id)
    {
        $request->validate(['priority' => 'required|string']);
        $message = CitizenMessage::findOrFail($id);
        $message->update(['priority' => $request->priority]);
        return response()->json($message);
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

        $message = CitizenMessage::findOrFail($id);
        $message->update($validated);
        return response()->json($message);
    }

    public function destroy($id)
    {
        $message = CitizenMessage::findOrFail($id);
        $message->delete();
        return response()->json(['message' => 'Message deleted successfully']);
    }
}
