<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomCity extends Model
{
    protected $fillable = ['state', 'name', 'name_mr', 'name_hi'];
}
