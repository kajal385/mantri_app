<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donations', function (Blueprint $table) {
            $table->id();
            $table->string('firebase_id')->unique()->nullable();
            $table->string('userId')->nullable();
            $table->string('userEmail')->nullable();
            $table->decimal('amount', 15, 2)->nullable();
            $table->string('transactionId')->nullable();
            $table->string('status')->nullable();
            $table->timestamp('createdAt')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('donations');
    }
};
