<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Complaint extends Model
{
    protected $fillable = [
        'firebase_id',
        'userId',
        'userName',
        'category',
        'description',
        'location',
        'status',
        'createdAt',
        'imageUrl',
        'priority',
        'is_escalated',
        'escalated_to',
        'follow_up_date',
        'reminder_date',
        'is_senior_citizen',
        'is_media_contact',
    ];

    protected $casts = [
        'createdAt' => 'datetime',
        'is_escalated' => 'boolean',
        'follow_up_date' => 'datetime',
        'reminder_date' => 'datetime',
        'is_senior_citizen' => 'boolean',
        'is_media_contact' => 'boolean',
    ];
}
