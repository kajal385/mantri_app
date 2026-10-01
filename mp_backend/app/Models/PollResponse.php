<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PollResponse extends Model
{
    protected $fillable = [
        'firebase_id',
        'userId',
        'pollId',
        'choice',
        'createdAt',
    ];

    protected $casts = [
        'createdAt' => 'datetime',
    ];
}
