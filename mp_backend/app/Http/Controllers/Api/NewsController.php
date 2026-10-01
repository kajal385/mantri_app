<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\News;
use Illuminate\Http\Request;

class NewsController extends Controller
{
    public function index()
    {
        return response()->json(News::orderBy('createdAt', 'desc')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'description' => 'required|string',
            'imageUrl' => 'nullable|string',
            'isLive' => 'boolean',
        ]);

        $news = News::create([
            'title' => $validated['title'],
            'description' => $validated['description'],
            'imageUrl' => $validated['imageUrl'],
            'isLive' => $validated['isLive'] ?? false,
            'createdAt' => now(),
        ]);

        return response()->json($news, 201);
    }

    public function destroy($id)
    {
        $news = News::findOrFail($id);
        $news->delete();
        return response()->json(['message' => 'News deleted successfully']);
    }
}
