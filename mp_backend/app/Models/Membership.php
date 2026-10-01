<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Membership extends Model
{
    protected $fillable = [
        'firebase_id',
        'userId',
        'fullName',
        'digitalId',
        'role',
        'area',
        'status',
        'taskCompleted',
        'createdAt',
    ];

    protected $casts = [
        'taskCompleted' => 'boolean',
        'createdAt' => 'datetime',
    ];
}
