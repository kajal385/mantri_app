<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DelegatedTask;
use Illuminate\Http\Request;

class DelegatedTaskController extends Controller
{
    public function index(Request $request)
    {
        $query = DelegatedTask::orderBy('deadline', 'asc');

        if ($request->has('status') && $request->query('status') !== 'all') {
            $query->where('status', $request->query('status'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title'          => 'required|string',
            'description'    => 'nullable|string',
            'assignee'       => 'required|string',
            'deadline'       => 'required|date',
            'priority'       => 'nullable|string',
            'status'         => 'nullable|string',
            'follow_up_date' => 'nullable|date',
            'reminder_date'  => 'nullable|date',
        ]);

        $task = DelegatedTask::create([
            'title'          => $validated['title'],
            'description'    => $validated['description'] ?? null,
            'assignee'       => $validated['assignee'],
            'deadline'       => $validated['deadline'],
            'priority'       => $validated['priority'] ?? 'Medium',
            'status'         => $validated['status'] ?? 'Pending',
            'follow_up_date' => $validated['follow_up_date'] ?? null,
            'reminder_date'  => $validated['reminder_date'] ?? null,
        ]);

        return response()->json($task, 201);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'title'          => 'nullable|string',
            'description'    => 'nullable|string',
            'assignee'       => 'nullable|string',
            'deadline'       => 'nullable|date',
            'priority'       => 'nullable|string',
            'status'         => 'nullable|string',
            'is_escalated'   => 'nullable|boolean',
            'escalated_to'   => 'nullable|string',
            'follow_up_date' => 'nullable|date',
            'reminder_date'  => 'nullable|date',
        ]);

        $task = DelegatedTask::findOrFail($id);
        $task->update($validated);

        return response()->json($task);
    }

    public function destroy($id)
    {
        $task = DelegatedTask::findOrFail($id);
        $task->delete();
        return response()->json(['message' => 'Task deleted successfully']);
    }
}
