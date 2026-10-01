<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Donation extends Model
{
    protected $fillable = [
        'firebase_id',
        'userId',
        'userEmail',
        'donorName',
        'phone',
        'donationDate',
        'purpose',
        'paymentMode',
        'amount',
        'transactionId',
        'status',
        'createdAt',
    ];

    protected $casts = [
        'createdAt' => 'datetime',
        'donationDate' => 'date',
        'amount' => 'decimal:2',
    ];
}
