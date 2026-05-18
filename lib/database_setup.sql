-- =============================================
-- i-EMS Supabase SQL Setup
-- Supabase Dashboard > SQL Editor এ run করো
-- =============================================

-- 1. profiles table (Auth এর সাথে linked)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  username TEXT UNIQUE,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'Student', -- 'Admin', 'Student', 'Teacher'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. students table
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  username TEXT,
  full_name TEXT,
  email TEXT,
  student_uid TEXT,
  date_of_birth DATE,
  department TEXT,
  blood TEXT,
  father_name TEXT,
  father_phone TEXT,
  mother_name TEXT,
  mother_phone TEXT,
  nid_number TEXT,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing student columns to existing databases
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS student_uid TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS department TEXT,
  ADD COLUMN IF NOT EXISTS blood TEXT,
  ADD COLUMN IF NOT EXISTS father_name TEXT,
  ADD COLUMN IF NOT EXISTS father_phone TEXT,
  ADD COLUMN IF NOT EXISTS mother_name TEXT,
  ADD COLUMN IF NOT EXISTS mother_phone TEXT,
  ADD COLUMN IF NOT EXISTS nid_number TEXT;

-- 3. teachers table
CREATE TABLE IF NOT EXISTS public.teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  username TEXT,
  email TEXT,
  employee_id TEXT,
  subject TEXT,
  qualification TEXT,
  experience_years INTEGER DEFAULT 0,
  department TEXT,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- RLS (Row Level Security) Policies
-- =============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

-- profiles: authenticated user রা সব দেখতে পারবে
CREATE POLICY "Allow authenticated read profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- Allow public read on profiles so the client can lookup username/email
-- during login (before the user is authenticated). Adjust if you
-- prefer stricter rules or to expose fewer columns.
CREATE POLICY "Allow public read profiles"
  ON public.profiles FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Allow authenticated insert profiles"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated delete profiles"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (true);

-- students table policies
CREATE POLICY "Allow authenticated read students"
  ON public.students FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated insert students"
  ON public.students FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update students"
  ON public.students FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated delete students"
  ON public.students FOR DELETE
  TO authenticated
  USING (true);

-- teachers table policies
CREATE POLICY "Allow authenticated read teachers"
  ON public.teachers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated insert teachers"
  ON public.teachers FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update teachers"
  ON public.teachers FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated delete teachers"
  ON public.teachers FOR DELETE
  TO authenticated
  USING (true);

