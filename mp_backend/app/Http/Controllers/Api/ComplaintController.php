<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\User;
use App\Helpers\PriorityScorer;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ComplaintController extends Controller
{
    public function index(Request $request)
    {
        $query = Complaint::orderBy('createdAt', 'desc');

        if ($request->has('userId')) {
            $query->where('userId', $request->query('userId'));
        }

        if ($request->has('status') && $request->query('status') !== 'all') {
            $query->where('status', $request->query('status'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'userId'      => 'required|string',
            'userName'    => 'required|string',
            'category'    => 'required|string',
            'description' => 'required|string',
            'location'    => 'required|string',
            'imageUrl'    => 'nullable|string',
            'priority'    => 'nullable|string',
            'is_senior_citizen' => 'nullable|boolean',
            'is_media_contact' => 'nullable|boolean',
        ]);

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
            null, // phone not in complaint form directly
            $validated['category'] . ' ' . $validated['description'],
            $isSenior,
            $isMedia,
            $email
        );

        $complaint = Complaint::create([
            'userId'      => $userId,
            'userName'    => $validated['userName'],
            'category'    => $validated['category'],
            'description' => $validated['description'],
            'location'    => $validated['location'],
            'status'      => 'pending',
            'createdAt'   => now(),
            'imageUrl'    => $validated['imageUrl'] ?? null,
            'priority'    => $priority,
            'is_senior_citizen' => $isSenior,
            'is_media_contact'  => $isMedia,
        ]);

        return response()->json($complaint, 201);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);
        $complaint = Complaint::findOrFail($id);
        $complaint->update(['status' => $request->status]);
        return response()->json($complaint);
    }

    public function updatePriority(Request $request, $id)
    {
        $request->validate(['priority' => 'required|string']);
        $complaint = Complaint::findOrFail($id);
        $complaint->update(['priority' => $request->priority]);
        return response()->json($complaint);
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

        $complaint = Complaint::findOrFail($id);
        $complaint->update($validated);
        return response()->json($complaint);
    }

    public function destroy($id)
    {
        $complaint = Complaint::findOrFail($id);
        $complaint->delete();
        return response()->json(['message' => 'Complaint deleted successfully']);
    }
}
