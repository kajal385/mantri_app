<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EventReminder extends Model
{
    protected $fillable = [
        'firebase_id',
        'eventId',
        'eventTitle',
        'userId',
        'userEmail',
        'requestedAt',
    ];

    protected $casts = [
        'requestedAt' => 'datetime',
    ];
}
