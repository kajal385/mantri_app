<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NewsPost;
use Illuminate\Http\Request;

class NewsPostController extends Controller
{
    public function index(Request $request)
    {
        $query = NewsPost::with(['category', 'images'])->orderBy('created_at', 'desc');

        if ($request->has('category_id') && $request->category_id != 'all') {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('page')) {
            $posts = $query->paginate(10);
            return $this->successResponse($posts, 'News fetched successfully');
        }

        return $this->successResponse($query->get(), 'News fetched successfully');
    }

    public function show($id)
    {
        return $this->successResponse(NewsPost::with(['category', 'images'])->findOrFail($id), 'News fetched successfully');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string',
            'description' => 'nullable|string',
            'image' => 'nullable|string',
            'video_url' => 'nullable|string',
            'thumbnail_url' => 'nullable|string',
            'published_at' => 'nullable|date',
            'status' => 'nullable|string',
            'created_by' => 'nullable|string',
            'category_id' => 'nullable|exists:news_categories,id',
            'event_date' => 'nullable|date',
            'location' => 'nullable|string',
            'images' => 'nullable|array',
            'images.*' => 'string'
        ]);

        if (empty($validated['published_at'])) {
            $validated['published_at'] = now();
        }

        if (empty($validated['status'])) {
            $validated['status'] = 'published';
        }

        $newsPost = NewsPost::create($validated);

        if (!empty($validated['images'])) {
            foreach ($validated['images'] as $index => $imageUrl) {
                $newsPost->images()->create([
                    'image_url' => $imageUrl,
                    'sort_order' => $index,
                ]);
            }
        }

        return $this->successResponse($newsPost->load(['category', 'images']), 'News post created successfully', 201);
    }

    public function update(Request $request, $id)
    {
        $newsPost = NewsPost::findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|required|string',
            'description' => 'nullable|string',
            'image' => 'nullable|string',
            'video_url' => 'nullable|string',
            'thumbnail_url' => 'nullable|string',
            'published_at' => 'nullable|date',
            'status' => 'nullable|string',
            'created_by' => 'nullable|string',
            'category_id' => 'nullable|exists:news_categories,id',
            'event_date' => 'nullable|date',
            'location' => 'nullable|string',
            'images' => 'nullable|array',
            'images.*' => 'string'
        ]);

        $newsPost->update($validated);

        if (isset($validated['images'])) {
            $newsPost->images()->delete();
            foreach ($validated['images'] as $index => $imageUrl) {
                $newsPost->images()->create([
                    'image_url' => $imageUrl,
                    'sort_order' => $index,
                ]);
            }
        }

        return $this->successResponse($newsPost->load(['category', 'images']), 'News post updated successfully');
    }

    public function destroy($id)
    {
        $newsPost = NewsPost::findOrFail($id);
        $newsPost->delete();
        return $this->successResponse(null, 'News post deleted successfully');
    }

    public function rsvp(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => 'required|string',
        ]);

        $newsPost = NewsPost::findOrFail($id);
        
        $rsvp = \App\Models\Rsvp::updateOrCreate(
            ['news_post_id' => $newsPost->id, 'user_id' => $request->user()->id],
            ['status' => $validated['status']]
        );

        return $this->successResponse($rsvp, 'RSVP submitted successfully');
    }

    public function getRsvps($id)
    {
        $newsPost = NewsPost::findOrFail($id);
        $rsvps = \App\Models\Rsvp::with('user')->where('news_post_id', $newsPost->id)->get();
        return $this->successResponse($rsvps, 'RSVPs fetched successfully');
    }
}
