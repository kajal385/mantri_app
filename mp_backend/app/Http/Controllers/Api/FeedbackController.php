<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Feedback;
use Illuminate\Http\Request;

class FeedbackController extends Controller
{
    public function index()
    {
        return $this->successResponse(Feedback::orderBy('created_at', 'desc')->get(), 'Feedback fetched successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|string',
            'project_category' => 'required|string',
            'rating' => 'required|numeric|min:0|max:5',
            'comment' => 'nullable|string',
        ]);

        $feedback = Feedback::create($validated);

        return $this->successResponse($feedback, 'Feedback submitted successfully', 201);
    }

    public function destroy($id)
    {
        $feedback = Feedback::findOrFail($id);
        $feedback->delete();
        return $this->successResponse(null, 'Feedback deleted successfully');
    }
}
