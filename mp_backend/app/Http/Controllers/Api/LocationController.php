<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomCity;
use App\Models\CustomVillage;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function index()
    {
        return response()->json([
            'cities' => CustomCity::all(),
            'villages' => CustomVillage::all(),
        ]);
    }

    public function storeCity(Request $request)
    {
        if ($request->user()->role !== 'pa' && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $request->validate([
            'state' => 'required|string|max:255',
            'name' => 'required|string|max:255',
            'name_mr' => 'nullable|string|max:255',
            'name_hi' => 'nullable|string|max:255',
        ]);

        $exists = CustomCity::where('state', $request->state)
                            ->where('name', $request->name)
                            ->exists();
        if ($exists) {
            return response()->json(['message' => 'City already exists.'], 422);
        }

        $city = CustomCity::create($request->all());
        return response()->json($city, 201);
    }

    public function storeVillage(Request $request)
    {
        if ($request->user()->role !== 'pa' && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $request->validate([
            'city' => 'required|string|max:255',
            'name' => 'required|string|max:255',
            'name_mr' => 'nullable|string|max:255',
            'name_hi' => 'nullable|string|max:255',
        ]);

        $exists = CustomVillage::where('city', $request->city)
                             ->where('name', $request->name)
                             ->exists();
        if ($exists) {
            return response()->json(['message' => 'Village already exists.'], 422);
        }

        $village = CustomVillage::create($request->all());
        return response()->json($village, 201);
    }
}
