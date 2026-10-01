<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('custom_cities', function (Blueprint $table) {
            $table->id();
            $table->string('state');
            $table->string('name');
            $table->string('name_mr')->nullable();
            $table->string('name_hi')->nullable();
            $table->timestamps();
        });

        Schema::create('custom_villages', function (Blueprint $table) {
            $table->id();
            $table->string('city');
            $table->string('name');
            $table->string('name_mr')->nullable();
            $table->string('name_hi')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('custom_villages');
        Schema::dropIfExists('custom_cities');
    }
};
