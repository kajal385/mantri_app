<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Schedule extends Model
{
    protected $fillable = [
        'firebase_id',
        'title',
        'description',
        'type',
        'time',
        'date',
        'organizerName',
        'organizerContact',
        'location',
        'mapUrl',
        'imageUrl',
        'status',
    ];

    protected $casts = [
        'date' => 'datetime',
    ];
}
