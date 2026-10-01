<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    protected $fillable = [
        'firebase_id',
        'title',
        'description',
        'location',
        'date',
        'createdBy',
        'createdAt',
    ];

    protected $casts = [
        'date' => 'datetime',
        'createdAt' => 'datetime',
    ];
}
