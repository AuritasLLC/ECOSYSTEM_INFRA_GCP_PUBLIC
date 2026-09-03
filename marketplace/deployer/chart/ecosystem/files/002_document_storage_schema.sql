-- Minimal base schema required by ASM+ document/folder migrations.
-- This file is intentionally additive:
-- - creates tables only when they do not exist
-- - adds columns only when they do not exist
-- - adds constraints/indexes only when missing
-- - does not drop, truncate, rename, or delete anything

BEGIN;

SELECT pg_advisory_xact_lock(20260803, 4402);

CREATE TABLE IF NOT EXISTS folders (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  parent_folder_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'folder',
  status TEXT NOT NULL DEFAULT 'active',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT,
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS files (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  folder_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
  comp_id TEXT NOT NULL,
  version TEXT NOT NULL DEFAULT '_',
  contrep TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT,
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE folders
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS parent_folder_id INTEGER,
  ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'folder',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_by TEXT,
  ADD COLUMN IF NOT EXISTS updated_by TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE files
  ADD COLUMN IF NOT EXISTS id SERIAL,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS folder_id INTEGER,
  ADD COLUMN IF NOT EXISTS comp_id TEXT,
  ADD COLUMN IF NOT EXISTS version TEXT NOT NULL DEFAULT '_',
  ADD COLUMN IF NOT EXISTS contrep TEXT,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_by TEXT,
  ADD COLUMN IF NOT EXISTS updated_by TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE folders
  ALTER COLUMN type SET DEFAULT 'folder',
  ALTER COLUMN status SET DEFAULT 'active',
  ALTER COLUMN metadata SET DEFAULT '{}'::jsonb,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET DEFAULT NOW();

ALTER TABLE files
  ALTER COLUMN version SET DEFAULT '_',
  ALTER COLUMN status SET DEFAULT 'active',
  ALTER COLUMN metadata SET DEFAULT '{}'::jsonb,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'folders'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE folders
      ADD CONSTRAINT folders_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'folders'::regclass
      AND conname = 'folders_parent_folder_id_fkey'
  ) THEN
    ALTER TABLE folders
      ADD CONSTRAINT folders_parent_folder_id_fkey
      FOREIGN KEY (parent_folder_id) REFERENCES folders(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'files'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE files
      ADD CONSTRAINT files_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'files'::regclass
      AND conname = 'files_folder_id_fkey'
  ) THEN
    ALTER TABLE files
      ADD CONSTRAINT files_folder_id_fkey
      FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_document_folders_lookup
  ON folders (name, type, parent_folder_id, status);

CREATE INDEX IF NOT EXISTS idx_document_files_lookup
  ON files (name, comp_id, folder_id, status);

-- Keep SERIAL sequences aligned with existing rows.
DO $$
DECLARE
  table_name TEXT;
  sequence_name TEXT;
  max_id BIGINT;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'folders',
    'files'
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
