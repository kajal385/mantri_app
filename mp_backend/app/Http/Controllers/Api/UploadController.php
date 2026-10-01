<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class UploadController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'file' => 'required|image|mimes:jpeg,png,jpg,gif|max:5120',
            'path' => 'nullable|string',
        ]);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $filename = time() . '_' . \Illuminate\Support\Str::random(8) . '.' . $file->getClientOriginalExtension();

            // Move to public/uploads directory
            $destinationPath = public_path('uploads');
            $file->move($destinationPath, $filename);

            return response()->json([
                'url' => asset('uploads/' . $filename),
                'name' => $filename,
            ]);
        }

        return response()->json(['error' => 'No file uploaded'], 400);
    }

    public function storeVideo(Request $request)
    {
        // Increase memory limit for video processing
        ini_set('memory_limit', '256M');

        $request->validate([
            'video' => 'required|file|mimes:mp4,mov,avi,wmv|max:51200', // 50MB limit
            'folder' => 'nullable|string',
        ]);

        if ($request->hasFile('video')) {
            $file = $request->file('video');
            $filename = time() . '_' . \Illuminate\Support\Str::random(8) . '.' . $file->getClientOriginalExtension();

            // Use specific folder if provided, else default to 'uploads/videos'
            $folder = $request->input('folder', 'news_videos');
            $destinationPath = public_path('uploads/' . $folder);

            if (!file_exists($destinationPath)) {
                mkdir($destinationPath, 0755, true);
            }

            $file->move($destinationPath, $filename);

            return response()->json([
                'url' => asset('uploads/' . $folder . '/' . $filename),
                'name' => $filename,
            ]);
        }

        return response()->json(['error' => 'No video file uploaded'], 400);
    }
}
