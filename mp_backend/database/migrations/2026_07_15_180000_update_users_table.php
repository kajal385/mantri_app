<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('firebase_id')->unique()->after('id')->nullable();
            $table->string('phone')->nullable()->after('email');
            $table->string('role')->nullable()->after('phone');
            $table->string('area')->nullable()->after('role');
            $table->string('ward')->nullable()->after('area');
            $table->string('village')->nullable()->after('ward');
            $table->string('password')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['firebase_id', 'phone', 'role', 'area', 'ward', 'village']);
            $table->string('password')->nullable(false)->change();
        });
    }
};
