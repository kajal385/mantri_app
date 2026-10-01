<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class FeedbackProjectCategoryController extends Controller
{
    public function index()
    {
        $categories = \App\Models\FeedbackProjectCategory::orderBy('name')->get();
        return $this->successResponse($categories);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|unique:feedback_project_categories,name'
        ]);

        $category = \App\Models\FeedbackProjectCategory::create([
            'name' => $request->name
        ]);

        return $this->successResponse($category, 'Project category added successfully');
    }
}
