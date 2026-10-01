<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('news_posts', function (Blueprint $table) {
            $table->foreignId('category_id')->nullable()->constrained('news_categories')->onDelete('set null');
            $table->timestamp('event_date')->nullable();
            $table->string('location')->nullable();
            $table->integer('likes_count')->default(0);
            $table->integer('comments_count')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('news_posts', function (Blueprint $table) {
            $table->dropForeign(['category_id']);
            $table->dropColumn(['category_id', 'event_date', 'location', 'likes_count', 'comments_count']);
        });
    }
};
