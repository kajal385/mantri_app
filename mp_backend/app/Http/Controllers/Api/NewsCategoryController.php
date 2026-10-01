<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NewsCategory;
use Illuminate\Http\Request;

class NewsCategoryController extends Controller
{
    public function index()
    {
        return $this->successResponse(NewsCategory::orderBy('name')->get(), 'Categories fetched successfully');
    }
}
