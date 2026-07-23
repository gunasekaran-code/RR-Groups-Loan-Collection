<?php
// Web-push subscriptions:
//   - Any authenticated user may register (upsert), read, or remove their own
//     device subscription. There is no cross-user exposure worth restricting
//     further here — the endpoint (device token) is per-browser.

class PushSubscriptionController extends ResourceController
{
    public function handle(): void
    {
        $this->requireAuth();
        parent::handle();
    }
}
