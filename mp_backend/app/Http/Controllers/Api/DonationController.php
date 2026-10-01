<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Donation;
use Illuminate\Http\Request;

class DonationController extends Controller
{
    public function index(Request $request)
    {
        $query = Donation::orderBy('donationDate', 'desc')->orderBy('created_at', 'desc');

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where(function($q) use ($search) {
                $q->where('donorName', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('userEmail', 'like', "%{$search}%")
                  ->orWhere('purpose', 'like', "%{$search}%")
                  ->orWhere('transactionId', 'like', "%{$search}%");
            });
        }

        if ($request->has('purpose') && $request->query('purpose') !== 'all') {
            $query->where('purpose', $request->query('purpose'));
        }

        if ($request->has('status') && $request->query('status') !== 'all') {
            $query->where('status', $request->query('status'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'userId'        => 'nullable|string',
            'userEmail'     => 'nullable|email',
            'donorName'     => 'required|string',
            'phone'         => 'required|string',
            'amount'        => 'required|numeric|min:1',
            'donationDate'  => 'required|date',
            'purpose'       => 'required|string',
            'paymentMode'   => 'required|string',
            'transactionId' => 'nullable|string',
            'status'        => 'nullable|string',
        ]);

        $donation = Donation::create([
            'userId'        => $validated['userId'] ?? null,
            'userEmail'     => $validated['userEmail'] ?? null,
            'donorName'     => $validated['donorName'],
            'phone'         => $validated['phone'],
            'amount'        => $validated['amount'],
            'donationDate'  => $validated['donationDate'],
            'purpose'       => $validated['purpose'],
            'paymentMode'   => $validated['paymentMode'],
            'transactionId' => $validated['transactionId'] ?? ('TXN-' . time() . '-' . rand(100, 999)),
            'status'        => $validated['status'] ?? 'Completed',
            'createdAt'     => now(),
        ]);

        return response()->json($donation, 201);
    }

    public function summary()
    {
        $total = Donation::where('status', 'Completed')->sum('amount');
        $count = Donation::count();
        $recent = Donation::orderBy('created_at', 'desc')->limit(5)->get();

        return response()->json([
            'totalAmount' => (double) $total,
            'donationCount' => $count,
            'recentDonations' => $recent
        ]);
    }
}
