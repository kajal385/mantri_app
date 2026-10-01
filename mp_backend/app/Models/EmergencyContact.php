<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmergencyContact extends Model
{
    protected $fillable = [
        'name',
        'department',
        'phone',
        'description',
        'status',
    ];

    protected $casts = [
        'status' => 'boolean',
    ];
}
