-- 1. Tablolara erişim yetkilerini (SELECT, INSERT, UPDATE, DELETE) tanımlıyoruz
grant select, insert, update, delete on public.profiles to authenticated, anon, service_role;
grant select, insert, update, delete on public.bolus_listings to authenticated, anon, service_role;

-- 2. Fotoğrafların yükleneceği 'avatars' Storage klasörünü (Bucket) oluşturuyoruz
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 3. Çelişen eski depolama politikaları varsa kaldırıyoruz
drop policy if exists "Allow authenticated uploads to avatars" on storage.objects;
drop policy if exists "Allow public read access to avatars" on storage.objects;

-- 4. Oturum açmış kullanıcıların avatar yüklemesine izin veren politikayı yazıyoruz
create policy "Allow authenticated uploads to avatars"
on storage.objects for insert with check (
  bucket_id = 'avatars' and auth.role() = 'authenticated'
);

-- 5. Yüklenen fotoğrafların herkes tarafından görüntülenebilmesini sağlayan politikayı yazıyoruz
create policy "Allow public read access to avatars"
on storage.objects for select using (
  bucket_id = 'avatars'
);