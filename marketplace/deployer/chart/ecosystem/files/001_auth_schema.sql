-- from Ecosystem\ECOSYSTEM_API_AUTH\db\migrations\..here the sql file
-- Minimal schema required by ECOSYSTEM_API_AUTH.
-- This file is intentionally additive:
-- - creates tables only when they do not exist
-- - adds columns only when they do not exist
-- - adds constraints/indexes only when missing
-- - does not drop, truncate, rename, or delete anything

BEGIN;

SELECT pg_advisory_xact_lock(20260803, 4402);

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS applications (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  redirect_link TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS redirect_link TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'applications'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE applications
      ADD CONSTRAINT applications_pkey PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS applications_name_uq
  ON applications (LOWER(name));

CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  application_id INTEGER REFERENCES applications(id) ON DELETE CASCADE
);

ALTER TABLE roles
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS application_id INTEGER;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'roles'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE roles
      ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'roles'::regclass
      AND conname = 'roles_application_id_fkey'
  ) THEN
    ALTER TABLE roles
      ADD CONSTRAINT roles_application_id_fkey
      FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS roles_name_global_uq
  ON roles (LOWER(name))
  WHERE application_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS roles_name_per_application_uq
  ON roles (application_id, LOWER(name))
  WHERE application_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  username TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role_id INTEGER REFERENCES roles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS password_hash TEXT,
  ADD COLUMN IF NOT EXISTS role_id INTEGER,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS auth_provider TEXT NOT NULL DEFAULT 'local',
  ADD COLUMN IF NOT EXISTS entra_tenant_id TEXT,
  ADD COLUMN IF NOT EXISTS entra_object_id TEXT,
  ADD COLUMN IF NOT EXISTS saml_name_id TEXT,
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS service_connection_id UUID;

ALTER TABLE users
  ALTER COLUMN password_hash DROP NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'users'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'users'::regclass
      AND conname = 'users_role_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS users_username_uq
  ON users (username);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_uq
  ON users (email);

CREATE UNIQUE INDEX IF NOT EXISTS users_entra_identity_uq
  ON users (entra_tenant_id, entra_object_id)
  WHERE entra_tenant_id IS NOT NULL
    AND entra_object_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS users_saml_identity_uq
  ON users (saml_name_id)
  WHERE auth_provider = 'saml'
    AND saml_name_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_role_id
  ON users (role_id);

CREATE TABLE IF NOT EXISTS client_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  client_key_hash TEXT NOT NULL,
  client_key_prefix TEXT NOT NULL,
  service_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  allowed_origins TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  allowed_ips TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  enabled BOOLEAN NOT NULL DEFAULT true,
  system_managed BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  last_used_at TIMESTAMPTZ
);

ALTER TABLE client_connections
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS client_key_hash TEXT,
  ADD COLUMN IF NOT EXISTS client_key_prefix TEXT,
  ADD COLUMN IF NOT EXISTS service_user_id UUID,
  ADD COLUMN IF NOT EXISTS allowed_origins TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS allowed_ips TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS system_managed BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS created_by UUID,
  ADD COLUMN IF NOT EXISTS updated_by UUID,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'client_connections'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE client_connections
      ADD CONSTRAINT client_connections_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'client_connections'::regclass
      AND conname = 'client_connections_service_user_id_fkey'
  ) THEN
    ALTER TABLE client_connections
      ADD CONSTRAINT client_connections_service_user_id_fkey
      FOREIGN KEY (service_user_id) REFERENCES users(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'users'::regclass
      AND conname = 'users_service_connection_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_service_connection_id_fkey
      FOREIGN KEY (service_connection_id) REFERENCES client_connections(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS client_connections_name_uq
  ON client_connections (LOWER(name));

CREATE UNIQUE INDEX IF NOT EXISTS client_connections_client_key_hash_uq
  ON client_connections (client_key_hash);

CREATE INDEX IF NOT EXISTS idx_client_connections_service_user_id
  ON client_connections (service_user_id);

CREATE INDEX IF NOT EXISTS idx_users_service_connection_id
  ON users (service_connection_id);

CREATE TABLE IF NOT EXISTS sso_configurations (
  provider TEXT PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT false,
  display_name TEXT NOT NULL,
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT sso_configurations_provider_check CHECK (provider IN ('saml', 'microsoft'))
);

ALTER TABLE sso_configurations
  ADD COLUMN IF NOT EXISTS provider TEXT,
  ADD COLUMN IF NOT EXISTS enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS display_name TEXT NOT NULL DEFAULT 'SAML',
  ADD COLUMN IF NOT EXISTS settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'sso_configurations'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE sso_configurations
      ADD CONSTRAINT sso_configurations_pkey PRIMARY KEY (provider);
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'sso_configurations'::regclass
      AND conname = 'sso_configurations_provider_check'
  ) THEN
    ALTER TABLE sso_configurations
      DROP CONSTRAINT sso_configurations_provider_check;
  END IF;

  ALTER TABLE sso_configurations
    ADD CONSTRAINT sso_configurations_provider_check
    CHECK (provider IN ('saml', 'microsoft'));
END $$;

CREATE TABLE IF NOT EXISTS sso_identity_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_type TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT false,
  display_name TEXT NOT NULL,
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT sso_identity_providers_type_check CHECK (provider_type IN ('microsoft', 'saml'))
);

ALTER TABLE sso_identity_providers
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS provider_type TEXT,
  ADD COLUMN IF NOT EXISTS enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS display_name TEXT NOT NULL DEFAULT 'SSO Provider',
  ADD COLUMN IF NOT EXISTS settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'sso_identity_providers'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE sso_identity_providers
      ADD CONSTRAINT sso_identity_providers_pkey PRIMARY KEY (id);
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'sso_identity_providers'::regclass
      AND conname = 'sso_identity_providers_type_check'
  ) THEN
    ALTER TABLE sso_identity_providers
      DROP CONSTRAINT sso_identity_providers_type_check;
  END IF;

  ALTER TABLE sso_identity_providers
    ADD CONSTRAINT sso_identity_providers_type_check
    CHECK (provider_type IN ('microsoft', 'saml'));
END $$;

CREATE INDEX IF NOT EXISTS idx_sso_identity_providers_type
  ON sso_identity_providers (provider_type);

CREATE INDEX IF NOT EXISTS idx_sso_identity_providers_enabled
  ON sso_identity_providers (enabled);

INSERT INTO sso_identity_providers (provider_type, enabled, display_name, settings)
SELECT provider, enabled, display_name, settings
FROM sso_configurations source
WHERE provider IN ('microsoft', 'saml')
  AND NOT EXISTS (
    SELECT 1
    FROM sso_identity_providers target
    WHERE target.provider_type = source.provider
  );

CREATE TABLE IF NOT EXISTS structures (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL
);

ALTER TABLE structures
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS application_id INTEGER;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'structures'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE structures
      ADD CONSTRAINT structures_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'structures'::regclass
      AND conname = 'structures_application_id_fkey'
  ) THEN
    ALTER TABLE structures
      ADD CONSTRAINT structures_application_id_fkey
      FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_structures_application_id
  ON structures (application_id);

CREATE TABLE IF NOT EXISTS user_application_access (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  application_id INTEGER NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_application_access_user_application_uq UNIQUE (user_id, application_id),
  CONSTRAINT user_application_access_role_check CHECK (role IN ('admin', 'editor', 'viewer', 'user'))
);

ALTER TABLE user_application_access
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS application_id INTEGER,
  ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'admin',
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_application_access'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE user_application_access
      ADD CONSTRAINT user_application_access_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_application_access'::regclass
      AND conname = 'user_application_access_user_id_fkey'
  ) THEN
    ALTER TABLE user_application_access
      ADD CONSTRAINT user_application_access_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_application_access'::regclass
      AND conname = 'user_application_access_application_id_fkey'
  ) THEN
    ALTER TABLE user_application_access
      ADD CONSTRAINT user_application_access_application_id_fkey
      FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_application_access'::regclass
      AND conname = 'user_application_access_role_check'
  ) THEN
    ALTER TABLE user_application_access
      ADD CONSTRAINT user_application_access_role_check
      CHECK (role IN ('admin', 'editor', 'viewer', 'user'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_application_access'::regclass
      AND conname = 'user_application_access_user_application_uq'
  ) THEN
    ALTER TABLE user_application_access
      ADD CONSTRAINT user_application_access_user_application_uq
      UNIQUE (user_id, application_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_application_access_user_id
  ON user_application_access (user_id);

CREATE INDEX IF NOT EXISTS idx_user_application_access_application_id
  ON user_application_access (application_id);

CREATE TABLE IF NOT EXISTS generic_access (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  application_id INTEGER NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  role_id INTEGER NOT NULL REFERENCES roles(id),
  role TEXT NOT NULL,
  structure INTEGER REFERENCES structures(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT generic_access_user_application_structure_uq UNIQUE (user_id, application_id, structure)
);

ALTER TABLE generic_access
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS application_id INTEGER,
  ADD COLUMN IF NOT EXISTS role_id INTEGER,
  ADD COLUMN IF NOT EXISTS role TEXT,
  ADD COLUMN IF NOT EXISTS structure INTEGER,
  ADD COLUMN IF NOT EXISTS created_by UUID,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND conname = 'generic_access_user_id_fkey'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND conname = 'generic_access_application_id_fkey'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_application_id_fkey
      FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND conname = 'generic_access_role_id_fkey'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES roles(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND conname = 'generic_access_structure_fkey'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_structure_fkey
      FOREIGN KEY (structure) REFERENCES structures(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND conname = 'generic_access_created_by_fkey'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_created_by_fkey
      FOREIGN KEY (created_by) REFERENCES users(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'generic_access'::regclass
      AND conname = 'generic_access_user_application_structure_uq'
  ) THEN
    ALTER TABLE generic_access
      ADD CONSTRAINT generic_access_user_application_structure_uq
      UNIQUE (user_id, application_id, structure);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS generic_access_user_app_global_uq
  ON generic_access (user_id, application_id)
  WHERE structure IS NULL;

CREATE INDEX IF NOT EXISTS idx_generic_access_user_id
  ON generic_access (user_id);

CREATE INDEX IF NOT EXISTS idx_generic_access_application_id
  ON generic_access (application_id);

CREATE INDEX IF NOT EXISTS idx_generic_access_role_id
  ON generic_access (role_id);

CREATE INDEX IF NOT EXISTS idx_generic_access_structure
  ON generic_access (structure);

INSERT INTO roles (name, description, application_id)
SELECT 'super_admin', 'Ecosystem super administrator', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM roles
  WHERE LOWER(name) = LOWER('super_admin')
    AND application_id IS NULL
);

INSERT INTO roles (name, description, application_id)
SELECT 'admin', 'Application administrator', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM roles
  WHERE LOWER(name) = LOWER('admin')
    AND application_id IS NULL
);

INSERT INTO roles (name, description, application_id)
SELECT 'editor', 'Application editor', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM roles
  WHERE LOWER(name) = LOWER('editor')
    AND application_id IS NULL
);

INSERT INTO roles (name, description, application_id)
SELECT 'viewer', 'Application viewer', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM roles
  WHERE LOWER(name) = LOWER('viewer')
    AND application_id IS NULL
);

INSERT INTO applications (id, name, description)
VALUES (1, 'ASM+', 'Main ASM application')
ON CONFLICT DO NOTHING;

-- Keep SERIAL sequences aligned with existing rows.
-- This prevents the next generated id from colliding with rows inserted
-- manually or imported from another service.
DO $$
DECLARE
  table_name TEXT;
  sequence_name TEXT;
  max_id BIGINT;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'applications',
    'roles',
    'structures',
    'user_application_access',
    'generic_access'
  ]
  LOOP
    sequence_name := pg_get_serial_sequence(table_name, 'id');

    IF sequence_name IS NOT NULL THEN
      EXECUTE format('SELECT MAX(id) FROM %I', table_name)
        INTO max_id;

      EXECUTE format(
        'SELECT setval(%L::regclass, %s, %L)',
        sequence_name,
        COALESCE(max_id, 1),
        max_id IS NOT NULL
      );
    END IF;
  END LOOP;
END $$;

COMMIT;
