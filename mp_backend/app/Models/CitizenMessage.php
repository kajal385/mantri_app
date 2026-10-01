<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CitizenMessage extends Model
{
    protected $table = 'citizen_messages';

    protected $fillable = [
        'userId',
        'userName',
        'userEmail',
        'phone',
        'subject',
        'body',
        'priority',
        'status',
        'is_escalated',
        'escalated_to',
        'follow_up_date',
        'reminder_date',
        'is_senior_citizen',
        'is_media_contact',
    ];

    protected $casts = [
        'is_escalated' => 'boolean',
        'follow_up_date' => 'datetime',
        'reminder_date' => 'datetime',
        'is_senior_citizen' => 'boolean',
        'is_media_contact' => 'boolean',
    ];
}
