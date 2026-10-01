<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SocialLink;
use Illuminate\Http\Request;

class SocialLinkController extends Controller
{
    public function index()
    {
        $links = SocialLink::first();
        if (!$links) {
            $links = SocialLink::create([
                'facebook_url' => '',
                'instagram_url' => '',
                'x_url' => ''
            ]);
        }
        return $this->successResponse($links, 'Social links fetched successfully');
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'facebook_url' => 'nullable|string|max:500',
            'instagram_url' => 'nullable|string|max:500',
            'x_url' => 'nullable|string|max:500',
        ]);

        $links = SocialLink::first();
        if (!$links) {
            $links = SocialLink::create($validated);
        } else {
            $links->update($validated);
        }

        return $this->successResponse($links, 'Social links updated successfully');
    }
}
