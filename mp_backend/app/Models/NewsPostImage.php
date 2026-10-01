<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NewsPostImage extends Model
{
    protected $fillable = ['news_post_id', 'image_url', 'sort_order'];

    public function post()
    {
        return $this->belongsTo(NewsPost::class, 'news_post_id');
    }
}
