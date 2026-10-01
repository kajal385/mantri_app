# Make Email Optional in Citizen Registration

The goal is to allow citizens to register without an email address. While the Flutter UI has been updated to make the field optional, the Laravel backend is still returning a validation error stating that the email is required.

## Proposed Changes

### [Backend - Laravel]

#### [MODIFY] [AuthController.php](file:///C:/CODEXXA_PROJECT/mantri_app/mp_backend/app/Http/Controllers/Api/AuthController.php)
- Update the `register` method to ensure the `email` field is truly treated as optional by the validator.
- Although it already has `nullable`, I will double-check for any conflicting rules or logic that might trigger the `required` error.
- I will also ensure that if an empty string is sent, it is explicitly converted to `null` before validation to avoid "invalid email format" or "unique" conflicts.

## Verification Plan

### Manual Verification
- Attempt to register a new citizen account using the Flutter app without entering an email.
- Verify that the registration succeeds and the user is redirected to the home screen.
- Verify that the record in the `users` table has a `NULL` value for the `email` column.
