<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AppointmentIssueController extends Controller
{
    public function index()
    {
        $issues = \App\Models\AppointmentIssue::orderBy('name')->get();
        return $this->successResponse($issues);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|unique:appointment_issues,name'
        ]);

        $issue = \App\Models\AppointmentIssue::create([
            'name' => $request->name
        ]);

        return $this->successResponse($issue, 'Issue added successfully');
    }
}
