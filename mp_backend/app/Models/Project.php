<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    protected $fillable = [
        'firebase_id',
        'title',
        'description',
        'budget',
        'timeline',
        'location',
        'status',
        'beforeImageUrl',
        'afterImageUrl',
        'createdAt',
    ];

    protected $casts = [
        'createdAt' => 'datetime',
    ];
}
