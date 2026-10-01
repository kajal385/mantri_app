<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'political_journey')) {
                $table->text('political_journey')->nullable();
            }
            if (!Schema::hasColumn('users', 'achievements')) {
                $table->text('achievements')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['political_journey', 'achievements']);
        });
    }
};
