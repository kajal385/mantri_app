<?php

namespace App\Traits;

trait ApiResponse
{
    /**
     * Send a standard success response.
     */
    protected function successResponse($data = [], $message = 'Data fetched successfully', $code = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], $code);
    }

    /**
     * Send a standard error response.
     */
    protected function errorResponse($message = 'An error occurred', $code = 400, $data = [])
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'data'    => $data,
        ], $code);
    }
}
