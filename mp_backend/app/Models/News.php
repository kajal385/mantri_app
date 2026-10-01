<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class News extends Model
{
    protected $fillable = [
        'firebase_id',
        'title',
        'description',
        'imageUrl',
        'isLive',
        'createdAt',
    ];

    protected $casts = [
        'isLive' => 'boolean',
        'createdAt' => 'datetime',
    ];
}
