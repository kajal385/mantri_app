<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class TestController extends Controller
{
    public function index()
    {
        return response()->json([
            'message' => 'Database connection successful!',
            'user_count' => User::count(),
            'latest_users' => User::latest()->take(5)->get()
        ]);
    }
}
