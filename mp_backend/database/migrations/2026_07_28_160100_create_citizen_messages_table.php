<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('citizen_messages', function (Blueprint $table) {
            $table->id();
            $table->string('userId')->nullable();
            $table->string('userName');
            $table->string('userEmail');
            $table->string('phone')->nullable();
            $table->string('subject');
            $table->text('body');
            $table->string('priority')->default('Medium');
            $table->string('status')->default('Pending');
            $table->boolean('is_escalated')->default(false);
            $table->string('escalated_to')->nullable();
            $table->timestamp('follow_up_date')->nullable();
            $table->timestamp('reminder_date')->nullable();
            $table->boolean('is_senior_citizen')->default(false);
            $table->boolean('is_media_contact')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('citizen_messages');
    }
};
