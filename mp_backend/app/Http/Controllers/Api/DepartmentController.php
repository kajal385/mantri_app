<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use Illuminate\Http\Request;

class DepartmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Department::query();
        if ($request->has('status')) {
            $query->where('status', clone $request->boolean('status'));
        }
        $departments = $query->orderBy('name')->get();
        return $this->successResponse($departments, 'Departments fetched successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'status' => 'boolean',
        ]);

        $department = Department::create($validated);
        return $this->successResponse($department, 'Department created successfully', 201);
    }

    public function update(Request $request, $id)
    {
        $department = Department::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'status' => 'boolean',
        ]);

        $department->update($validated);
        return $this->successResponse($department, 'Department updated successfully');
    }

    public function destroy($id)
    {
        $department = Department::findOrFail($id);
        $department->delete();
        return $this->successResponse(null, 'Department deleted successfully');
    }
}
