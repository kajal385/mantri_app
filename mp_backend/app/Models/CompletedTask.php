<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CompletedTask extends Model
{
    protected $fillable = [
        'firebase_id',
        'userId',
        'taskName',
        'description',
        'role',
        'area',
        'proofUrl',
        'completedAt',
    ];

    protected $casts = [
        'completedAt' => 'datetime',
    ];
}
