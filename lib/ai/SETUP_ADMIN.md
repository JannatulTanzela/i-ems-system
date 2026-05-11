# ADMIN PANEL সেটআপ - Quick Guide

## 🚀 দ্রুত শুরু (3 ধাপ):

### ধাপ 1: SQL Tables Create করো

Supabase Dashboard → SQL Editor এ paste করো:

```sql
-- 1. Profiles Table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  username TEXT UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('Admin', 'Student', 'Teacher')),
  full_name TEXT NOT NULL,
  phone TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Students Table
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  registration_number TEXT UNIQUE NOT NULL,
  roll_number TEXT,
  class TEXT,
  date_of_birth DATE,
  guardian_name TEXT,
  guardian_phone TEXT,
  address TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Teachers Table
CREATE TABLE teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  employee_id TEXT UNIQUE NOT NULL,
  subject TEXT,
  qualification TEXT,
  experience_years INTEGER,
  department TEXT,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Classes Table
CREATE TABLE classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_name TEXT NOT NULL UNIQUE,
  section TEXT,
  teacher_id UUID REFERENCES teachers(id),
  total_students INTEGER DEFAULT 0,
  room_number TEXT,
  timing TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
```

---

### ধাপ 2: Admin User Create করো

1. Supabase Dashboard
2. **Authentication** → **Users** → **Add user**
3. এই তথ্য দাও:
   - Email: `admin@iems.local`
   - Password: `admin1234`
4. **Create user** করো
5. User ID **copy করো**

---

### ধাপ 3: Admin Profile Insert করো

SQL Editor এ (User ID replace করে):

```sql
INSERT INTO profiles (id, email, username, role, full_name, phone, is_active) 
VALUES (
  'PASTE_USER_ID_HERE',
  'admin@iems.local',
  'admin',
  'Admin',
  'System Administrator',
  '01700000000',
  true
);
```

---

## 🔐 Login করো:

```
Username: admin
Password: admin1234
Role: Admin
```

✅ Admin Panel দেখবে!

---

## 🎮 Admin Panel এ করার কাজ:

1. **Dashboard Tab**: Stats দেখো
2. **Students Tab**: 
   - "Add Student" button
   - Form fill করো
   - Save করো
3. **Teachers Tab**:
   - "Add Teacher" button
   - Form fill করো
   - Save করো

---

## 📁 Project Files:

```
lib/
├── main.dart ✅ (admin route)
├── auth_service.dart ✅
└── pages/
    ├── login_page.dart ✅ (forgot password removed)
    ├── admin_home_page.dart ✅
    ├── admin_students_page.dart ✅
    ├── admin_teachers_page.dart ✅
    └── home_page.dart ✅
```

---

## 🧪 Test করো:

```bash
cd d:\Flutter\Project\i-ems-system
flutter pub get
flutter run
```

---

## ✅ সবকিছু Ready!

- ✅ Code complete
- ✅ Documentation complete
- ✅ SQL ready
- ✅ Setup guide ready

**এখন Admin Panel সম্পূর্ণভাবে কাজ করবে!** 🎉

---

*For detailed docs: আগের documentation files দেখো*
