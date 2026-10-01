<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('donations', function (Blueprint $table) {
            $table->string('donorName')->nullable()->after('userEmail');
            $table->string('phone')->nullable()->after('donorName');
            $table->date('donationDate')->nullable()->after('phone');
            $table->string('purpose')->nullable()->after('donationDate');
            $table->string('paymentMode')->nullable()->after('purpose');
        });
    }

    public function down(): void
    {
        Schema::table('donations', function (Blueprint $table) {
            $table->dropColumn(['donorName', 'phone', 'donationDate', 'purpose', 'paymentMode']);
        });
    }
};
