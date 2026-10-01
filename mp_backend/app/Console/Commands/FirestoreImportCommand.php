<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Complaint;
use App\Models\CompletedTask;
use App\Models\Donation;
use App\Models\EventReminder;
use App\Models\Event;
use App\Models\Feedback;
use App\Models\Grievance;
use App\Models\Membership;
use App\Models\MpApp;
use App\Models\PaProfile;
use App\Models\PollResponse;
use App\Models\Project;
use App\Models\Schedule;
use App\Models\Appointment;

class FirestoreImportCommand extends Command
{
    protected $signature = 'firestore:import';
    protected $description = 'Import Firestore JSON into MySQL';

    public function handle()
    {
        $this->importUsers();
        $this->importComplaints();
        $this->importCompletedTasks();
        $this->importDonations();
        $this->importEventReminders();
        $this->importEvents();
        $this->importFeedbacks();
        $this->importGrievances();
        $this->importMemberships();
        $this->importMpApp();
        $this->importPaProfiles();
        $this->importPollResponses();
        $this->importProjects();
        $this->importSchedules();
        $this->importAppointments();

        $this->info('All Firestore data imported successfully.');
    }

    private function convertTimestamp($timestamp)
    {
        if (isset($timestamp['_seconds'])) {
            return date('Y-m-d H:i:s', $timestamp['_seconds']);
        }
        return null;
    }

    private function importUsers()
    {
        $file = storage_path('app/firebase_data/users.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            User::updateOrCreate(
                ['firebase_id' => $item['id']],
                [
                    'name' => $item['name'] ?? '',
                    'email' => $item['email'] ?? '',
                    'phone' => $item['phone'] ?? null,
                    'role' => $item['role'] ?? null,
                    'area' => $item['area'] ?? null,
                    'ward' => $item['ward'] ?? null,
                    'village' => $item['village'] ?? null,
                    'password' => null,
                ]
            );
        }
        $this->info('Users imported.');
    }

    private function importComplaints()
    {
        $file = storage_path('app/firebase_data/complaints.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Complaint::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'userName' => $item['userName'] ?? null,
                'category' => $item['category'] ?? null,
                'description' => $item['description'] ?? null,
                'location' => $item['location'] ?? null,
                'status' => $item['status'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Complaints imported.');
    }

    private function importCompletedTasks()
    {
        $file = storage_path('app/firebase_data/completed_tasks.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            CompletedTask::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'taskName' => $item['taskName'] ?? null,
                'description' => $item['description'] ?? null,
                'role' => $item['role'] ?? null,
                'area' => $item['area'] ?? null,
                'proofUrl' => $item['proofUrl'] ?? null,
                'completedAt' => $this->convertTimestamp($item['completedAt'] ?? null),
            ]);
        }
        $this->info('Completed Tasks imported.');
    }

    private function importDonations()
    {
        $file = storage_path('app/firebase_data/donations.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Donation::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'userEmail' => $item['userEmail'] ?? null,
                'amount' => $item['amount'] ?? null,
                'transactionId' => $item['transactionId'] ?? null,
                'status' => $item['status'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Donations imported.');
    }

    private function importEventReminders()
    {
        $file = storage_path('app/firebase_data/event_reminders.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            EventReminder::create([
                'firebase_id' => $item['id'],
                'eventId' => $item['eventId'] ?? null,
                'eventTitle' => $item['eventTitle'] ?? null,
                'userId' => $item['userId'] ?? null,
                'userEmail' => $item['userEmail'] ?? null,
                'requestedAt' => $this->convertTimestamp($item['requestedAt'] ?? null),
            ]);
        }
        $this->info('Event Reminders imported.');
    }

    private function importEvents()
    {
        $file = storage_path('app/firebase_data/events.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Event::create([
                'firebase_id' => $item['id'],
                'title' => $item['title'] ?? null,
                'description' => $item['description'] ?? null,
                'location' => $item['location'] ?? null,
                'date' => $this->convertTimestamp($item['date'] ?? null),
                'createdBy' => $item['createdBy'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Events imported.');
    }

    private function importFeedbacks()
    {
        $file = storage_path('app/firebase_data/feedbacks.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Feedback::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'userName' => $item['userName'] ?? null,
                'projectName' => $item['projectName'] ?? null,
                'rating' => $item['rating'] ?? null,
                'comment' => $item['comment'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Feedbacks imported.');
    }

    private function importGrievances()
    {
        $file = storage_path('app/firebase_data/grievances.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Grievance::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'category' => $item['category'] ?? null,
                'description' => $item['description'] ?? null,
                'address' => $item['address'] ?? null,
                'mediaUrl' => $item['mediaUrl'] ?? null,
                'status' => $item['status'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Grievances imported.');
    }

    private function importMemberships()
    {
        $file = storage_path('app/firebase_data/memberships.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Membership::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'fullName' => $item['fullName'] ?? null,
                'digitalId' => $item['digitalId'] ?? null,
                'role' => $item['role'] ?? null,
                'area' => $item['area'] ?? null,
                'status' => $item['status'] ?? null,
                'taskCompleted' => $item['taskCompleted'] ?? false,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Memberships imported.');
    }

    private function importMpApp()
    {
        $file = storage_path('app/firebase_data/mpapp.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            MpApp::create([
                'firebase_id' => $item['id'],
                'mpapp' => $item['mpapp'] ?? null,
            ]);
        }
        $this->info('MpApp imported.');
    }

    private function importPaProfiles()
    {
        $file = storage_path('app/firebase_data/pa_profiles.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            PaProfile::create([
                'firebase_id' => $item['id'],
                'name' => $item['name'] ?? null,
                'email' => $item['email'] ?? null,
                'phone' => $item['phone'] ?? null,
                'role' => $item['role'] ?? null,
                'designation' => $item['designation'] ?? null,
                'employeeId' => $item['employeeId'] ?? null,
                'idProofType' => $item['idProofType'] ?? null,
                'idProofNumber' => $item['idProofNumber'] ?? null,
                'education' => $item['education'] ?? null,
                'address' => $item['address'] ?? null,
                'officeLocation' => $item['officeLocation'] ?? null,
                'assignedTo' => $item['assignedTo'] ?? null,
                'joiningDate' => $this->convertTimestamp($item['joiningDate'] ?? null),
                'status' => $item['status'] ?? null,
                'profileImageUrl' => $item['profileImageUrl'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Pa Profiles imported.');
    }

    private function importPollResponses()
    {
        $file = storage_path('app/firebase_data/poll_responses.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            PollResponse::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'pollId' => $item['pollId'] ?? null,
                'choice' => $item['choice'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Poll Responses imported.');
    }

    private function importProjects()
    {
        $file = storage_path('app/firebase_data/projects.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Project::create([
                'firebase_id' => $item['id'],
                'title' => $item['title'] ?? null,
                'description' => $item['description'] ?? null,
                'budget' => $item['budget'] ?? null,
                'timeline' => $item['timeline'] ?? null,
                'location' => $item['location'] ?? null,
                'status' => $item['status'] ?? null,
                'beforeImageUrl' => $item['beforeImageUrl'] ?? null,
                'afterImageUrl' => $item['afterImageUrl'] ?? null,
                'createdAt' => $this->convertTimestamp($item['createdAt'] ?? null),
            ]);
        }
        $this->info('Projects imported.');
    }

    private function importSchedules()
    {
        $file = storage_path('app/firebase_data/schedule.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Schedule::create([
                'firebase_id' => $item['id'],
                'title' => $item['title'] ?? null,
                'description' => $item['description'] ?? null,
                'type' => $item['type'] ?? null,
                'time' => $item['time'] ?? null,
                'date' => $this->convertTimestamp($item['date'] ?? null),
                'organizerName' => $item['organizerName'] ?? null,
                'organizerContact' => $item['organizerContact'] ?? null,
                'location' => $item['location'] ?? null,
                'mapUrl' => $item['mapUrl'] ?? null,
                'imageUrl' => $item['imageUrl'] ?? null,
                'status' => $item['status'] ?? null,
            ]);
        }
        $this->info('Schedules imported.');
    }

    private function importAppointments()
    {
        $file = storage_path('app/firebase_data/appointments.json');
        if (!file_exists($file)) return;
        $data = json_decode(file_get_contents($file), true);
        foreach ($data as $item) {
            Appointment::create([
                'firebase_id' => $item['id'],
                'userId' => $item['userId'] ?? null,
                'userName' => $item['userName'] ?? null,
                'phone' => $item['phone'] ?? null,
                'issue' => $item['issue'] ?? null,
                'date' => $this->convertTimestamp($item['date'] ?? null),
                'time' => $item['time'] ?? null,
                'token' => $item['token'] ?? null,
                'status' => $item['status'] ?? null,
            ]);
        }
        $this->info('Appointments imported.');
    }
}
