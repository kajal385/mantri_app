<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaProfile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        // Explicitly handle empty email strings before validation
        if ($request->has('email') && (is_null($request->email) || trim($request->email) === '')) {
            $request->merge(['email' => null]);
        }

        $rules = [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'password' => 'required|string|min:6',
            'role' => 'required|string',
            'state' => 'required|string|max:255',
            'city' => 'required|string|max:255',
            'ward' => 'required|string|max:255',
            'village' => 'required|string|max:255',
        ];

        // Only validate email if it's actually provided
        if ($request->filled('email')) {
            $rules['email'] = 'string|email|max:255|unique:users';
        }

        $request->validate($rules);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'role'     => $request->role,
            'phone'    => $request->phone,
            'state'    => $request->state,
            'city'     => $request->city,
            'area'     => $request->area,
            'ward'     => $request->ward,
            'village'  => $request->village,
        ]);

        if ($request->role === 'pa') {
            $this->createPaProfileForUser($user, $request);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    /**
     * Admin-only: create a PA user + staff profile without replacing the admin session.
     */
    public function registerPa(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'phone' => 'nullable|string|max:20',
            'employeeId' => 'nullable|string|max:255',
            'education' => 'nullable|string|max:255',
            'designation' => 'nullable|string|max:255',
            'assignedTo' => 'nullable|string|max:255',
            'officeLocation' => 'nullable|string|max:255',
            'address' => 'nullable|string|max:500',
            'idProofType' => 'nullable|string|max:255',
            'idProofNumber' => 'nullable|string|max:255',
            'joiningDate' => 'nullable|date',
            'status' => 'nullable|string|max:50',
            'profileImageUrl' => 'nullable|string|max:500',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'role'     => 'pa',
            'phone'    => $request->phone,
        ]);

        $profile = $this->createPaProfileForUser($user, $request);

        return response()->json([
            'message' => 'PA account created successfully',
            'user' => $user,
            'profile' => $profile,
        ], 201);
    }

    private function createPaProfileForUser(User $user, Request $request): PaProfile
    {
        return PaProfile::updateOrCreate(
            ['email' => $user->email],
            [
                'firebase_id' => (string) $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $request->phone ?? $user->phone,
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
                'createdAt' => now(),
            ]
        );
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string',
            'password' => 'required|string',
        ]);

        $loginInput = $request->email;
        $user = User::where('email', $loginInput)
                    ->orWhere('phone', $loginInput)
                    ->first();

        // For testing/migration: If user exists but has no password set (imported from JSON),
        // we might want a special handling or just fail.
        // Let's assume standard Laravel Auth for now.
        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully']);
    }

    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|string|email|max:255|unique:users,email,' . $user->id,
            'phone' => 'nullable|string|max:20',
            'state' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:255',
            'area' => 'nullable|string|max:255',
            'ward' => 'nullable|string|max:255',
            'village' => 'nullable|string|max:255',
            'profile_image_url' => 'nullable|string|max:500',
            'dob' => 'nullable|string|max:50',
            'birth_place' => 'nullable|string|max:255',
            'education' => 'nullable|string|max:255',
            'occupation' => 'nullable|string|max:255',
            'spouse' => 'nullable|string|max:255',
            'parents' => 'nullable|string|max:255',
            'vision' => 'nullable|string',
            'mission' => 'nullable|string',
            'political_journey' => 'nullable|string',
            'achievements' => 'nullable|string',
        ]);

        $user->update($validated);

        if ($user->role === 'pa') {
            $paProfile = PaProfile::where('firebase_id', (string) $user->id)
                ->orWhere('email', $user->email)
                ->first();
            if ($paProfile) {
                $paProfile->update(array_filter([
                    'name' => $request->name,
                    'phone' => $request->phone,
                    'email' => $request->email,
                    'profileImageUrl' => $request->profile_image_url,
                ], fn($v) => !is_null($v)));
            }
        }

        // Reload fresh from DB to include all columns
        $user->refresh();

        return response()->json($user);
    }

    public function mpProfile()
    {
        $admin = User::where('role', 'admin')->first();
        if (!$admin) {
            return response()->json(['error' => 'No admin/MP found'], 404);
        }
        return response()->json($admin);
    }
}
