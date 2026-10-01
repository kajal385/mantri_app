<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('delegated_tasks', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('assignee');
            $table->date('deadline');
            $table->string('priority')->default('Medium');
            $table->string('status')->default('Pending');
            $table->boolean('is_escalated')->default(false);
            $table->string('escalated_to')->nullable();
            $table->timestamp('follow_up_date')->nullable();
            $table->timestamp('reminder_date')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delegated_tasks');
    }
};
