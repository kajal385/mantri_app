<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmergencyContact;
use Illuminate\Http\Request;

class EmergencyContactController extends Controller
{
    /**
     * GET /api/emergency-contacts
     * Public: return only active contacts.
     */
    public function index()
    {
        $contacts = EmergencyContact::where('status', true)
            ->orderBy('name')
            ->get();

        return $this->successResponse($contacts, 'Active emergency contacts fetched successfully');
    }

    /**
     * GET /api/emergency-contacts/all
     * Admin/PA: return all contacts including inactive.
     */
    public function all()
    {
        $contacts = EmergencyContact::orderBy('name')->get();
        return $this->successResponse($contacts, 'All emergency contacts fetched successfully');
    }

    /**
     * POST /api/emergency-contacts
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'department'  => 'nullable|string|max:255',
            'phone'       => 'required|string|max:30',
            'description' => 'nullable|string',
            'status'      => 'boolean',
        ]);

        $contact = EmergencyContact::create($validated);
        return $this->successResponse($contact, 'Emergency contact created successfully', 201);
    }

    /**
     * PUT /api/emergency-contacts/{id}
     */
    public function update(Request $request, $id)
    {
        $contact = EmergencyContact::findOrFail($id);

        $validated = $request->validate([
            'name'        => 'sometimes|string|max:255',
            'department'  => 'nullable|string|max:255',
            'phone'       => 'sometimes|string|max:30',
            'description' => 'nullable|string',
            'status'      => 'boolean',
        ]);

        $contact->update($validated);
        return $this->successResponse($contact, 'Emergency contact updated successfully');
    }

    /**
     * DELETE /api/emergency-contacts/{id}
     */
    public function destroy($id)
    {
        $contact = EmergencyContact::findOrFail($id);
        $contact->delete();
        return $this->successResponse(null, 'Contact deleted successfully');
    }
}
