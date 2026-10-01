<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->string('priority')->default('Medium')->after('status');
            $table->boolean('is_escalated')->default(false)->after('priority');
            $table->string('escalated_to')->nullable()->after('is_escalated');
            $table->timestamp('follow_up_date')->nullable()->after('escalated_to');
            $table->timestamp('reminder_date')->nullable()->after('follow_up_date');
            $table->boolean('is_senior_citizen')->default(false)->after('reminder_date');
            $table->boolean('is_media_contact')->default(false)->after('is_senior_citizen');
        });

        Schema::table('complaints', function (Blueprint $table) {
            $table->string('priority')->default('Medium')->after('status');
            $table->boolean('is_escalated')->default(false)->after('priority');
            $table->string('escalated_to')->nullable()->after('is_escalated');
            $table->timestamp('follow_up_date')->nullable()->after('escalated_to');
            $table->timestamp('reminder_date')->nullable()->after('follow_up_date');
            $table->boolean('is_senior_citizen')->default(false)->after('reminder_date');
            $table->boolean('is_media_contact')->default(false)->after('is_senior_citizen');
        });
    }

    public function down(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->dropColumn(['priority', 'is_escalated', 'escalated_to', 'follow_up_date', 'reminder_date', 'is_senior_citizen', 'is_media_contact']);
        });

        Schema::table('complaints', function (Blueprint $table) {
            $table->dropColumn(['priority', 'is_escalated', 'escalated_to', 'follow_up_date', 'reminder_date', 'is_senior_citizen', 'is_media_contact']);
        });
    }
};
