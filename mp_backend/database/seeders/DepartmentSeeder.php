<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DepartmentSeeder extends Seeder
{
    public function run(): void
    {
        $departments = [
            ['name' => 'District Administration', 'description' => 'Handles district-level administrative functions', 'status' => true],
            ['name' => 'Municipal Administration', 'description' => 'Manages urban local body and municipal services', 'status' => true],
            ['name' => 'Police Department', 'description' => 'Law enforcement and public safety', 'status' => true],
            ['name' => 'Health Department', 'description' => 'Public health services and hospitals', 'status' => true],
            ['name' => 'Education Department', 'description' => 'Schools, colleges and educational institutions', 'status' => true],
            ['name' => 'Other Departments', 'description' => 'Other government departments and offices', 'status' => true],
        ];

        foreach ($departments as $dept) {
            // Only insert if not already present (avoid duplicates)
            $exists = DB::table('departments')->where('name', $dept['name'])->exists();
            if (!$exists) {
                DB::table('departments')->insert(array_merge($dept, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ]));
            }
        }
    }
}
