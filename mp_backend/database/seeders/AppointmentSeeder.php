public function run(): void
{
    $path = storage_path('app/firebase_data/appointments.json');

    if (!file_exists($path)) {
        $this->command->error('appointments.json not found!');
        return;
    }

    $appointments = json_decode(file_get_contents($path), true);

    foreach ($appointments as $appointment) {

        DB::table('appointments')->insert([

            'firebase_id' => $appointment['id'] ?? null,

            'date' => isset($appointment['date']['_seconds'])
                ? date('Y-m-d H:i:s', $appointment['date']['_seconds'])
                : null,

            'issue' => $appointment['issue'] ?? null,
            'phone' => $appointment['phone'] ?? null,
            'status' => $appointment['status'] ?? 'pending',
            'time' => $appointment['time'] ?? null,
            'token' => $appointment['token'] ?? null,
            'userId' => $appointment['userId'] ?? null,
            'userName' => $appointment['userName'] ?? null,

            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    $this->command->info('Appointments Imported Successfully!');
}
