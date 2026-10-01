<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NewsPost extends Model
{
    protected $table = 'news_posts';

    protected $fillable = [
        'title',
        'description',
        'image',
        'video_url',
        'thumbnail_url',
        'published_at',
        'status',
        'created_by',
        'category_id',
        'event_date',
        'location',
        'likes_count',
        'comments_count',
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'event_date' => 'datetime',
    ];

    public function category()
    {
        return $this->belongsTo(NewsCategory::class, 'category_id');
    }

    public function images()
    {
        return $this->hasMany(NewsPostImage::class, 'news_post_id')->orderBy('sort_order');
    }
}
