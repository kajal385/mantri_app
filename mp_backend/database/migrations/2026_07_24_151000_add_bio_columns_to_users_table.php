<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'dob')) {
                $table->string('dob')->nullable();
            }
            if (!Schema::hasColumn('users', 'birth_place')) {
                $table->string('birth_place')->nullable();
            }
            if (!Schema::hasColumn('users', 'education')) {
                $table->string('education')->nullable();
            }
            if (!Schema::hasColumn('users', 'occupation')) {
                $table->string('occupation')->nullable();
            }
            if (!Schema::hasColumn('users', 'spouse')) {
                $table->string('spouse')->nullable();
            }
            if (!Schema::hasColumn('users', 'parents')) {
                $table->string('parents')->nullable();
            }
            if (!Schema::hasColumn('users', 'vision')) {
                $table->text('vision')->nullable();
            }
            if (!Schema::hasColumn('users', 'mission')) {
                $table->text('mission')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['dob', 'birth_place', 'education', 'occupation', 'spouse', 'parents', 'vision', 'mission']);
        });
    }
};
