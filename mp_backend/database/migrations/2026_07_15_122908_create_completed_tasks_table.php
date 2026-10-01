<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('completed_tasks', function (Blueprint $table) {
            $table->id();
            $table->string('firebase_id')->unique()->nullable();
            $table->string('userId')->nullable();
            $table->string('taskName')->nullable();
            $table->text('description')->nullable();
            $table->string('role')->nullable();
            $table->string('area')->nullable();
            $table->string('proofUrl')->nullable();
            $table->timestamp('completedAt')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('completed_tasks');
    }
};
