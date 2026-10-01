<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaProfile;
use App\Models\User;
use Illuminate\Http\Request;

class PaProfileController extends Controller
{
    public function index()
    {
        $this->syncPaUsersWithoutProfiles();

        return response()->json(
            PaProfile::orderByDesc('createdAt')->orderByDesc('id')->get()
        );
    }

    public function show($uid)
    {
        $profile = PaProfile::where('firebase_id', $uid)
            ->orWhere('id', $uid)
            ->first();

        // Fallback: build/sync from users table when only the login account exists
        if (!$profile) {
            $user = User::where('role', 'pa')
                ->where(function ($q) use ($uid) {
                    $q->where('id', $uid)->orWhere('email', $uid);
                })
                ->first();

            if ($user) {
                $profile = $this->ensureProfileForUser($user);
            }
        }

        if (!$profile) {
            return response()->json(['message' => 'PA profile not found'], 404);
        }

        return response()->json($profile);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'nullable|string|max:20',
        ]);

        $profile = PaProfile::updateOrCreate(
            ['email' => $request->email],
            [
                'firebase_id' => $request->firebase_id,
                'name' => $request->name,
                'email' => $request->email,
                'phone' => $request->phone,
                'role' => 'pa',
                'designation' => $request->designation ?? 'Personal Assistant',
                'employeeId' => $request->employeeId,
                'idProofType' => $request->idProofType,
                'idProofNumber' => $request->idProofNumber,
                'education' => $request->education,
                'address' => $request->address,
                'officeLocation' => $request->officeLocation,
                'assignedTo' => $request->assignedTo ?? 'Anup Dhotre (MP)',
                'joiningDate' => $request->joiningDate ?? now(),
                'status' => $request->status ?? 'active',
                'profileImageUrl' => $request->profileImageUrl,
                'createdAt' => $request->createdAt ?? now(),
            ]
        );

        return response()->json($profile, 201);
    }

    public function update(Request $request, $uid)
    {
        $profile = PaProfile::where('firebase_id', $uid)
            ->orWhere('id', $uid)
            ->firstOrFail();

        $profile->update(array_filter([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'designation' => $request->designation,
            'employeeId' => $request->employeeId,
            'idProofType' => $request->idProofType,
            'idProofNumber' => $request->idProofNumber,
            'education' => $request->education,
            'address' => $request->address,
            'officeLocation' => $request->officeLocation,
            'assignedTo' => $request->assignedTo,
            'status' => $request->status,
        ], fn($v) => !is_null($v)));

        // Sync with users table
        User::where('role', 'pa')
            ->where(function ($q) use ($profile, $uid) {
                $q->where('email', $profile->email)->orWhere('id', $uid);
            })
            ->update(array_filter([
                'name' => $request->name,
                'email' => $request->email,
                'phone' => $request->phone,
            ], fn($v) => !is_null($v)));

        return response()->json($profile->fresh());
    }

    public function updateStatus(Request $request, $uid)
    {
        $request->validate(['status' => 'required|string']);
        $profile = PaProfile::where('firebase_id', $uid)
            ->orWhere('id', $uid)
            ->firstOrFail();
        $profile->update(['status' => $request->status]);
        return response()->json($profile);
    }

    public function destroy($uid)
    {
        $profile = PaProfile::where('firebase_id', $uid)
            ->orWhere('id', $uid)
            ->firstOrFail();

        // Also remove the login account when linked by email / firebase_id
        User::where('role', 'pa')
            ->where(function ($q) use ($profile) {
                $q->where('email', $profile->email);
                if ($profile->firebase_id) {
                    $q->orWhere('id', $profile->firebase_id);
                }
            })
            ->delete();

        $profile->delete();
        return response()->json(['message' => 'PA Profile deleted successfully']);
    }

    /**
     * Ensure every users.role=pa row has a matching pa_profiles row for staff list + PA panel.
     */
    private function syncPaUsersWithoutProfiles(): void
    {
        $paUsers = User::where('role', 'pa')->get();

        foreach ($paUsers as $user) {
            $this->ensureProfileForUser($user);
        }
    }

    private function ensureProfileForUser(User $user): PaProfile
    {
        $profile = PaProfile::where('email', $user->email)->first();

        if ($profile) {
            // Link old Firebase-imported rows to the Laravel user id used by the app
            if ($profile->firebase_id !== (string) $user->id) {
                $profile->update([
                    'firebase_id' => (string) $user->id,
                    'name' => $profile->name ?: $user->name,
                    'phone' => $profile->phone ?: $user->phone,
                ]);
            }
            return $profile->fresh();
        }

        return PaProfile::create([
            'firebase_id' => (string) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => 'pa',
            'designation' => 'Personal Assistant',
            'assignedTo' => 'Anup Dhotre (MP)',
            'status' => 'active',
            'joiningDate' => $user->created_at ?? now(),
            'createdAt' => $user->created_at ?? now(),
        ]);
    }
}
