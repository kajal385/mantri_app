<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class SliderController extends Controller
{
    public function index()
    {
        return response()->json(\App\Models\SliderImage::orderBy('created_at', 'desc')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'url' => 'required|string',
        ]);

        $sliderImage = \App\Models\SliderImage::create([
            'url' => $validated['url'],
        ]);

        return response()->json($sliderImage, 201);
    }

    public function destroy(Request $request)
    {
        $query = \App\Models\SliderImage::query();
        if ($request->has('url')) {
            $query->where('url', $request->query('url'));
        } elseif ($request->has('id')) {
            $query->where('id', $request->query('id'));
        } else {
            return response()->json(['error' => 'url or id parameter is required'], 422);
        }

        $query->delete();
        return response()->json(['message' => 'Slider image deleted successfully']);
    }
}
