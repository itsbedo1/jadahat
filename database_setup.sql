-- ═══════════════════════════════════════════════
-- سوق أهلنا — إعداد قاعدة البيانات في Supabase
-- انسخ هذا الكود والصقه في: SQL Editor في Supabase Dashboard
-- ═══════════════════════════════════════════════

-- 1. جدول المحلات
CREATE TABLE IF NOT EXISTS stores (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  category        TEXT,
  governorate     TEXT,
  area            TEXT,
  address         TEXT,
  phone           TEXT,
  whatsapp        TEXT,
  instagram       TEXT,
  description     TEXT,
  working_hours   TEXT,
  plan            TEXT DEFAULT 'basic' CHECK (plan IN ('basic','pro','premium')),
  logo_url        TEXT,
  lat             DECIMAL(10,8),
  lng             DECIMAL(11,8),
  active          BOOLEAN DEFAULT true,
  verified        BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. جدول المنتجات
CREATE TABLE IF NOT EXISTS products (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id      UUID REFERENCES stores(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  category      TEXT,
  description   TEXT,
  price         DECIMAL(12,2) NOT NULL DEFAULT 0,
  quantity      INTEGER DEFAULT 1,
  images        TEXT[],
  active        BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. جدول زيارات المحلات
CREATE TABLE IF NOT EXISTS store_views (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id      UUID REFERENCES stores(id) ON DELETE CASCADE,
  visitor_ip    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 4. جدول التقييمات
CREATE TABLE IF NOT EXISTS reviews (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id        UUID REFERENCES stores(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES auth.users(id),
  reviewer_name   TEXT,
  rating          INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment         TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ═══ تفعيل صلاحيات الأمان (RLS) ═══

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- سياسات المحلات
CREATE POLICY "المحلات النشطة مرئية للجميع"
  ON stores FOR SELECT USING (active = true);

CREATE POLICY "التاجر يدير محله"
  ON stores FOR ALL USING (auth.uid() = user_id);

-- سياسات المنتجات
CREATE POLICY "المنتجات النشطة مرئية"
  ON products FOR SELECT USING (active = true);

CREATE POLICY "التاجر يدير منتجاته"
  ON products FOR ALL USING (
    store_id IN (SELECT id FROM stores WHERE user_id = auth.uid())
  );

-- سياسات الزيارات
CREATE POLICY "تسجيل الزيارات"
  ON store_views FOR INSERT WITH CHECK (true);

CREATE POLICY "التاجر يرى زياراته"
  ON store_views FOR SELECT USING (
    store_id IN (SELECT id FROM stores WHERE user_id = auth.uid())
  );

-- سياسات التقييمات
CREATE POLICY "التقييمات مرئية للجميع"
  ON reviews FOR SELECT USING (true);

CREATE POLICY "المستخدم يضيف تقييم"
  ON reviews FOR INSERT WITH CHECK (true);

-- ═══ فهارس للأداء ═══
CREATE INDEX IF NOT EXISTS idx_stores_gov ON stores(governorate);
CREATE INDEX IF NOT EXISTS idx_stores_cat ON stores(category);
CREATE INDEX IF NOT EXISTS idx_stores_active ON stores(active);
CREATE INDEX IF NOT EXISTS idx_stores_user ON stores(user_id);
CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(active);
CREATE INDEX IF NOT EXISTS idx_views_store ON store_views(store_id);
CREATE INDEX IF NOT EXISTS idx_reviews_store ON reviews(store_id);
