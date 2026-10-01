<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SocialLink extends Model
{
    protected $fillable = [
        'facebook_url',
        'instagram_url',
        'x_url',
    ];
}
