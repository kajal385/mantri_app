<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaAvailability extends Model
{
    protected $fillable = [
        'date',
        'is_available',
        'start_time',
        'end_time',
    ];

    protected $casts = [
        'date' => 'date',
        'is_available' => 'boolean',
    ];
}
