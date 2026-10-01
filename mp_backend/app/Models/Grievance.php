<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Grievance extends Model
{
    protected $fillable = [
        'firebase_id',
        'userId',
        'category',
        'description',
        'address',
        'mediaUrl',
        'status',
        'createdAt',
    ];

    protected $casts = [
        'createdAt' => 'datetime',
    ];
}
