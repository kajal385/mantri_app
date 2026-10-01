<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('memberships', function (Blueprint $table) {
            $table->id();
            $table->string('firebase_id')->unique()->nullable();
            $table->string('userId')->nullable();
            $table->string('fullName')->nullable();
            $table->string('digitalId')->nullable();
            $table->string('role')->nullable();
            $table->string('area')->nullable();
            $table->string('status')->nullable();
            $table->boolean('taskCompleted')->default(false);
            $table->timestamp('createdAt')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('memberships');
    }
};
