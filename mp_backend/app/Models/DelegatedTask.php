<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DelegatedTask extends Model
{
    protected $table = 'delegated_tasks';

    protected $fillable = [
        'title',
        'description',
        'assignee',
        'deadline',
        'priority',
        'status',
        'is_escalated',
        'escalated_to',
        'follow_up_date',
        'reminder_date',
    ];

    protected $casts = [
        'deadline' => 'date',
        'is_escalated' => 'boolean',
        'follow_up_date' => 'datetime',
        'reminder_date' => 'datetime',
    ];
}
