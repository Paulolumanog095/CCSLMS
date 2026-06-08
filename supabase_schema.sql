-- ============================================================
-- Computer Laboratory Inventory System - Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =================== TABLES ===================

-- Laboratories / Rooms
CREATE TABLE IF NOT EXISTS laboratories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  room_number TEXT NOT NULL UNIQUE,
  building TEXT,
  capacity INTEGER DEFAULT 0,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Equipment Categories
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Equipment / Items
CREATE TABLE IF NOT EXISTS equipment (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  laboratory_id UUID REFERENCES laboratories(id) ON DELETE SET NULL,
  serial_number TEXT UNIQUE,
  model TEXT,
  brand TEXT,
  quantity INTEGER DEFAULT 1,
  unit_cost NUMERIC(12,2) DEFAULT 0,
  status TEXT CHECK (status IN ('active','inactive','under_repair','disposed')) DEFAULT 'active',
  condition TEXT CHECK (condition IN ('excellent','good','fair','poor')) DEFAULT 'good',
  date_acquired DATE,
  warranty_expiry DATE,
  specifications TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Borrowing / Lending Records
CREATE TABLE IF NOT EXISTS borrowing_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  equipment_id UUID REFERENCES equipment(id) ON DELETE CASCADE,
  borrower_name TEXT NOT NULL,
  borrower_email TEXT,
  borrower_id_number TEXT,
  department TEXT,
  purpose TEXT,
  quantity_borrowed INTEGER DEFAULT 1,
  borrow_date TIMESTAMPTZ DEFAULT NOW(),
  expected_return_date TIMESTAMPTZ,
  actual_return_date TIMESTAMPTZ,
  status TEXT CHECK (status IN ('borrowed','returned','overdue','lost')) DEFAULT 'borrowed',
  condition_on_return TEXT,
  approved_by TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Maintenance Records
CREATE TABLE IF NOT EXISTS maintenance_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  equipment_id UUID REFERENCES equipment(id) ON DELETE CASCADE,
  maintenance_type TEXT CHECK (maintenance_type IN ('preventive','corrective','inspection')) DEFAULT 'preventive',
  description TEXT,
  performed_by TEXT,
  cost NUMERIC(12,2) DEFAULT 0,
  maintenance_date DATE DEFAULT CURRENT_DATE,
  next_maintenance_date DATE,
  status TEXT CHECK (status IN ('scheduled','in_progress','completed','cancelled')) DEFAULT 'completed',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suppliers
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  contact_person TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================== INDEXES ===================
CREATE INDEX IF NOT EXISTS idx_equipment_laboratory ON equipment(laboratory_id);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category_id);
CREATE INDEX IF NOT EXISTS idx_equipment_status ON equipment(status);
CREATE INDEX IF NOT EXISTS idx_borrowing_equipment ON borrowing_records(equipment_id);
CREATE INDEX IF NOT EXISTS idx_borrowing_status ON borrowing_records(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_equipment ON maintenance_records(equipment_id);

-- =================== FUNCTIONS ===================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_equipment_updated_at
  BEFORE UPDATE ON equipment
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_laboratories_updated_at
  BEFORE UPDATE ON laboratories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =================== SEED DATA ===================

INSERT INTO categories (name, description) VALUES
  ('Computers', 'Desktop and laptop computers'),
  ('Monitors', 'Display monitors'),
  ('Peripherals', 'Keyboards, mice, and other peripherals'),
  ('Networking', 'Routers, switches, cables'),
  ('Printers', 'Printers and scanners'),
  ('Audio/Visual', 'Projectors, speakers, webcams'),
  ('Storage', 'External drives, USBs'),
  ('Power', 'UPS, power strips, AVRs')
ON CONFLICT DO NOTHING;

INSERT INTO laboratories (name, room_number, building, capacity, description) VALUES
  ('Computer Lab 1', 'CL-101', 'Main Building', 30, 'General purpose programming lab'),
  ('Computer Lab 2', 'CL-102', 'Main Building', 25, 'Networking and hardware lab'),
  ('Computer Lab 3', 'CL-201', 'Annex Building', 20, 'Multimedia and design lab')
ON CONFLICT DO NOTHING;

-- =================== ROW LEVEL SECURITY ===================
ALTER TABLE laboratories ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrowing_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- Allow all operations for authenticated users (adjust as needed)
CREATE POLICY "Allow all for authenticated" ON laboratories FOR ALL USING (true);
CREATE POLICY "Allow all for authenticated" ON categories FOR ALL USING (true);
CREATE POLICY "Allow all for authenticated" ON equipment FOR ALL USING (true);
CREATE POLICY "Allow all for authenticated" ON borrowing_records FOR ALL USING (true);
CREATE POLICY "Allow all for authenticated" ON maintenance_records FOR ALL USING (true);
CREATE POLICY "Allow all for authenticated" ON suppliers FOR ALL USING (true);
