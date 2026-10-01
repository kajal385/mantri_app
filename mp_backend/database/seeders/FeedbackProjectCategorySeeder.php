<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class FeedbackProjectCategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $projects = [
            'Road Development Project', 'Water Supply Project', 'Drainage & Sewerage Project',
            'Street Light Project', 'Road Repair Project', 'Smart City Project',
            'Cleanliness & Sanitation Project', 'Waste Management Project', 'Public Garden Development',
            'School Development Project', 'Healthcare Development Project', 'Housing Development Project',
            'Employment & Skill Development Project', 'Digital Services Project', 'Public Transport Project',
            'Electricity Infrastructure Project', 'Community Hall Development', 'Women & Child Welfare Project',
            'Senior Citizen Welfare Project', 'Other Project'
        ];

        foreach ($projects as $project) {
            \App\Models\FeedbackProjectCategory::firstOrCreate(['name' => $project]);
        }
    }
}
