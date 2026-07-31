<?php
// Entry point → BiometricController. WebAuthn / passkey enrolment for the
// biometric login configured under Settings ▸ Biometric Login.
//   GET    /backend/biometric.php            → caller's biometric status
//   POST   /backend/biometric.php {register} → enrol this device
//   POST   /backend/biometric.php {resolve}  → credential id → owner (sign-in)
//   DELETE /backend/biometric.php?id=<id>    → remove a credential
require_once __DIR__ . '/bootstrap.php';
send_cors();

(new BiometricController())->handle();
