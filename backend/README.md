# RRGroups — PHP + MySQL Backend

This backend replaces the previous Supabase backend. It is a small, dependency-free
PHP API (served by XAMPP's Apache) talking to your **MySQL 8** server (the one MySQL
Workbench connects to).

```
frontend (Vite/React, :5173)
        │  fetch + JWT
        ▼
backend/ (PHP, Apache :80)  ──►  MySQL 8  (database: rrgroups)
```

## Architecture (MVC)

The backend follows a lightweight, framework-free **MVC** structure. Requests enter
through thin front-controller scripts that delegate to controllers, which use models
for all data access.

```
Request → auth.php / rest.php / users.php   (entry points)
            → Controller (AuthController / ResourceController / UserController)
              → Model (Profile, Customer, Loan, …)  ── SQL ──►  MySQL
```

| Path | Purpose |
|------|---------|
| `bootstrap.php` | Loads config, registers the class autoloader, defines HTTP helpers (CORS, JSON, JWT header, UUID). Every entry point requires it. |
| `core/Database.php` | PDO connection singleton. |
| `core/Jwt.php` | HS256 encode/decode. |
| `core/Model.php` | Base model: schema introspection, numeric casting, hidden-column stripping, and CRUD builders (`select`, `insertRows`, `updateWhere`, `deleteWhere`). Holds the table→model registry. |
| `core/QueryParser.php` | Turns PostgREST-lite query params into SQL WHERE / ORDER / LIMIT. |
| `core/Controller.php` | Base controller: request body + `requireAuth()` / `requireAdmin()` guards. |
| `models/*.php` | One class per table (`Profile`, `Customer`, `Loan`, `RepaymentSchedule`, `Collection`, `ChitGroup`, `ChitMember`, `Notification`, `Setting`, `PushSubscription`). `Profile` hides `password_hash`. |
| `controllers/AuthController.php` | `login` (email/password → JWT) and `me`. |
| `controllers/ResourceController.php` | Generic JWT-protected CRUD for any whitelisted table. |
| `controllers/UserController.php` | Admin-only create/update of login accounts (bcrypt hashing). |

### Entry points (unchanged URLs)

| File | Purpose |
|------|---------|
| `auth.php`  | `POST ?action=login` → JWT; `GET ?action=me`. → `AuthController` |
| `rest.php`  | Generic CRUD for `?table=<name>` (PostgREST-lite), JWT-protected. → `ResourceController` |
| `users.php` | Admin-only user create/update with passwords. → `UserController` |

### Utility scripts

| File | Purpose |
|------|---------|
| `schema.sql` | Creates the `rrgroups` database, the `rrgroups_app` user, all tables, and seed accounts. Run once. |
| `migrate.php` | Idempotent migrations for existing databases (customer role, KYC columns). |
| `seed.php` | Sets bcrypt passwords for demo accounts + seeds sample business data. |
| `config.php` | DB credentials, JWT secret, CORS origins. |

### Adding a new table

1. Create the table in `schema.sql`.
2. Add `models/Thing.php` (`class Thing extends Model { protected static string $table = 'things'; }`).
3. Register it in the `REGISTRY` array in `core/Model.php`.

It is now fully available at `rest.php?table=things` with filters, ordering, paging, insert/update/delete — no other code needed.

## One-time setup

### 1. Create the database (in MySQL Workbench)

1. Open **MySQL Workbench** and connect to your local MySQL 8 server (as `root`).
2. **File ▸ Open SQL Script…** → choose `backend/schema.sql`.
3. Click the **⚡ Execute** (lightning) button to run the whole script.

This creates the `rrgroups` database, all tables, and a limited application user
`rrgroups_app` (password `Rr#app_2026local`) that the PHP app uses — so the app never
runs as `root`.

> Prefer the command line? From this folder:
> `"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < schema.sql`

### 2. Set the demo passwords

```
cd d:\xampp\htdocs\RRGroups\backend
"D:\xampp\php\php.exe" seed.php
```

Seeded logins:

| Email                 | Password  | Role  |
|-----------------------|-----------|-------|
| `owner@fincollect.in` | `owner123`| admin |
| `admin@fincollect.in` | `admin123`| admin |
| `agent@fincollect.in` | `agent123`| agent |

### 3. Make sure Apache is running

Start **Apache** in the XAMPP Control Panel (it serves this folder at
`http://localhost/RRGroups/backend`). MySQL 8 runs as its own Windows service, so you do
**not** need to start XAMPP's MySQL.

### 4. Run the frontend

```
cd d:\xampp\htdocs\RRGroups\frontend
npm run dev
```

Open http://localhost:5173 and log in with one of the accounts above.

## Configuration notes

- **Change the app-user password** for anything beyond local dev: update it in both
  `schema.sql` (the `CREATE USER` lines) and `config.php`.
- **Change the JWT secret** (`jwt_secret` in `config.php`) to a long random string.
- **CORS**: `config.php` allows `http://localhost:5173`. Add your production origin there.
- Images (avatars, proofs, signatures) are stored as base64 data URLs in `LONGTEXT`
  columns — no file storage service required.

## API quick reference

```
POST  /backend/auth.php?action=login      { email, password } → { token, user, profile }
GET   /backend/auth.php?action=me          (Bearer token)      → { user, profile }

GET   /backend/rest.php?table=loans&status=eq.active&order=created_at.desc&limit=10
POST  /backend/rest.php?table=loans        body: object | array
PATCH /backend/rest.php?table=loans&id=eq.<uuid>   body: fields to update
DELETE/backend/rest.php?table=loans&id=eq.<uuid>
```

Filters use `column=<op>.<value>` where `op` ∈ `eq, neq, gt, gte, lt, lte, like, in, is`.
All `rest.php` requests require a valid `Authorization: Bearer <jwt>` header.
