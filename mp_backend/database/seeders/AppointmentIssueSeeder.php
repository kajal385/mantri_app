<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class AppointmentIssueSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $issues = [
            'General Consultation', 'Public Grievance', 'Development Work',
            'Road & Transport', 'Water Supply', 'Electricity', 'Drainage & Sewerage',
            'Street Lights', 'Garbage & Cleanliness', 'Housing', 'Education',
            'Healthcare', 'Employment', 'Government Documents', 'Certificate Related',
            'Pension / Welfare Scheme', 'Financial Assistance', 'Infrastructure Related',
            'Police / Law & Order', 'Property / Land', 'Municipal Services', 'Other'
        ];

        foreach ($issues as $issue) {
            \App\Models\AppointmentIssue::firstOrCreate(['name' => $issue]);
        }
    }
}
