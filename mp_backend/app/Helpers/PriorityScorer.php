<?php

namespace App\Helpers;

use App\Models\Appointment;
use App\Models\Complaint;
use App\Models\CitizenMessage;
use App\Models\User;
use Carbon\Carbon;

class PriorityScorer
{
    public static function calculateScore($userId, $phone, $text, $isSenior = false, $isMedia = false, $userEmail = null)
    {
        $score = 0;

        // 1. Repeat Visitor Check
        $visitCount = 0;
        if ($userId) {
            $visitCount += Appointment::where('userId', $userId)->count();
            $visitCount += Complaint::where('userId', $userId)->count();
            $visitCount += CitizenMessage::where('userId', $userId)->count();
        } elseif ($phone) {
            $visitCount += Appointment::where('phone', $phone)->count();
            $visitCount += CitizenMessage::where('phone', $phone)->count();
        }

        if ($visitCount >= 2) {
            $score += 2;
        }

        // 2. Urgent Keywords Check
        $urgentKeywords = ['urgent', 'emergency', 'critical', 'immediate', 'medical', 'danger', 'hazard', 'severe', 'accident', 'immediate help', 'immediate action'];
        $textLower = strtolower($text);
        foreach ($urgentKeywords as $keyword) {
            if (strpos($textLower, $keyword) !== false) {
                $score += 3;
                break;
            }
        }

        // 3. Senior Citizen Check
        if ($isSenior) {
            $score += 2;
        } elseif ($userId) {
            $user = User::find($userId);
            if ($user && $user->dob) {
                try {
                    $dob = Carbon::parse($user->dob);
                    if (Carbon::now()->diffInYears($dob) >= 60) {
                        $score += 2;
                    }
                } catch (\Exception $e) {
                    // Ignore date parsing errors
                }
            }
        }

        // 4. Important/Media Contact Check
        if ($isMedia) {
            $score += 3;
        } elseif ($userEmail) {
            $emailLower = strtolower($userEmail);
            $mediaKeywords = ['press', 'media', 'news', 'reporter', 'journal', 'tv', 'radio'];
            foreach ($mediaKeywords as $keyword) {
                if (strpos($emailLower, $keyword) !== false) {
                    $score += 3;
                    break;
                }
            }
        }

        // Map to Priority Category
        if ($score >= 5) {
            return 'High';
        } elseif ($score >= 2) {
            return 'Medium';
        } else {
            return 'Low';
        }
    }
}
