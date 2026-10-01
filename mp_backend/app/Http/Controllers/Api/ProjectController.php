<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\Request;

class ProjectController extends Controller
{
    public function index(Request $request)
    {
        $query = Project::orderBy('createdAt', 'desc');
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        return $this->successResponse($query->get(), 'Projects fetched successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'description' => 'required|string',
            'budget' => 'nullable|string',
            'timeline' => 'nullable|string',
            'location' => 'nullable|string',
            'status' => 'required|string',
            'beforeImageUrl' => 'nullable|string',
            'afterImageUrl' => 'nullable|string',
        ]);

        $project = Project::create(array_merge($validated, ['createdAt' => now()]));

        return $this->successResponse($project, 'Project created successfully', 201);
    }

    public function destroy($id)
    {
        $project = Project::findOrFail($id);
        $project->delete();
        return $this->successResponse(null, 'Project deleted successfully');
    }
}
