<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MeetingNote extends Model
{
    protected $table = 'meeting_notes';

    protected $fillable = [
        'appointment_id',
        'meeting_title',
        'meeting_date',
        'participants',
        'discussion_points',
        'decisions',
        'action_items',
        'follow_up_date',
    ];

    protected $casts = [
        'meeting_date' => 'datetime',
        'follow_up_date' => 'date',
    ];

    public function appointment()
    {
        return $this->belongsTo(Appointment::class, 'appointment_id');
    }
}
