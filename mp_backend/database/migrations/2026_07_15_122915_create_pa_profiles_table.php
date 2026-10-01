<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pa_profiles', function (Blueprint $table) {
            $table->id();
            $table->string('firebase_id')->unique()->nullable();
            $table->string('name')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('role')->nullable();
            $table->string('designation')->nullable();
            $table->string('employeeId')->nullable();
            $table->string('idProofType')->nullable();
            $table->string('idProofNumber')->nullable();
            $table->string('education')->nullable();
            $table->string('address')->nullable();
            $table->string('officeLocation')->nullable();
            $table->string('assignedTo')->nullable();
            $table->timestamp('joiningDate')->nullable();
            $table->string('status')->nullable();
            $table->string('profileImageUrl')->nullable();
            $table->timestamp('createdAt')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pa_profiles');
    }
};
