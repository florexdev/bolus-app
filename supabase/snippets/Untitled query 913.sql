-- Authenticated (giriş yapmış) kullanıcılara ilan tablosu için tam yetki veriyoruz
GRANT ALL PRIVILEGES ON public.bolus_listings TO authenticated;

-- Eğer ileride ID serilerinde (Sequence) sıkışma olmaması için seri yetkisini de açıyoruz
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;