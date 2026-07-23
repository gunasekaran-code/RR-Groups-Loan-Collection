<?php
// Profiles (users, incl. agents) reached through rest.php?table=profiles.
//   - Read:   any authenticated user — the frontend needs the agent list for
//             assignment dropdowns, the field map, dashboards, etc. Hidden columns
//             (password_hash, reset_otp_*) are stripped by the Profile model.
//   - Create / Update / Delete: admin only.
//     Regular user creation goes through users.php (UserController, which hashes
//     passwords) and self-service edits through auth.php?action=update_profile;
//     so any write that reaches rest.php here is an admin management action.

class AgentController extends ResourceController
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        if (in_array($method, ['POST', 'PATCH', 'PUT', 'DELETE'], true) && $role !== 'admin') {
            json_error('Only admins can manage user accounts', 403);
        }

        parent::handle();
    }
}
