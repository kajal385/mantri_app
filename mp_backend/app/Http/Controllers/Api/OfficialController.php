<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Official;
use Illuminate\Http\Request;

class OfficialController extends Controller
{
    public function index(Request $request)
    {
        $query = Official::with('department');
        
        if ($request->has('department_id')) {
            $query->where('department_id', $request->department_id);
        }
        
        if ($request->has('status')) {
            $query->where('status', $request->boolean('status'));
        }
        
        $officials = $query->orderBy('name')->get();
        return $this->successResponse($officials, 'Officials fetched successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'department_id' => 'required|exists:departments,id',
            'name' => 'required|string|max:255',
            'designation' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'status' => 'boolean',
        ]);

        $official = Official::create($validated);
        return $this->successResponse($official->load('department'), 'Official created successfully', 201);
    }

    public function update(Request $request, $id)
    {
        $official = Official::findOrFail($id);

        $validated = $request->validate([
            'department_id' => 'sometimes|exists:departments,id',
            'name' => 'sometimes|string|max:255',
            'designation' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:30',
            'email' => 'nullable|email|max:255',
            'status' => 'boolean',
        ]);

        $official->update($validated);
        return $this->successResponse($official->load('department'), 'Official updated successfully');
    }

    public function destroy($id)
    {
        $official = Official::findOrFail($id);
        $official->delete();
        return $this->successResponse(null, 'Official deleted successfully');
    }
}
