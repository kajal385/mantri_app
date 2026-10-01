<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaProfile extends Model
{
    protected $fillable = [
        'firebase_id',
        'name',
        'email',
        'phone',
        'role',
        'designation',
        'employeeId',
        'idProofType',
        'idProofNumber',
        'education',
        'address',
        'officeLocation',
        'assignedTo',
        'joiningDate',
        'status',
        'profileImageUrl',
        'createdAt',
    ];

    protected $casts = [
        'joiningDate' => 'datetime',
        'createdAt' => 'datetime',
    ];
}
