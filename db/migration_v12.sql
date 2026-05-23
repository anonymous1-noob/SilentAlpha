-- Ensure the avatars storage bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing avatar storage policies to recreate cleanly
DROP POLICY IF EXISTS "avatars: public read"  ON storage.objects;
DROP POLICY IF EXISTS "avatars: owner upload" ON storage.objects;
DROP POLICY IF EXISTS "avatars: owner update" ON storage.objects;
DROP POLICY IF EXISTS "avatars: owner delete" ON storage.objects;

-- Anyone can view avatars (public bucket)
CREATE POLICY "avatars: public read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- Authenticated users can upload their own avatar
CREATE POLICY "avatars: owner upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid() IS NOT NULL AND
    (storage.foldername(name))[1] = auth.uid()::text OR
    starts_with(name, auth.uid()::text)
  );

-- Authenticated users can update/replace their own avatar
CREATE POLICY "avatars: owner update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND
    starts_with(name, auth.uid()::text)
  );

-- Authenticated users can delete their own avatar
CREATE POLICY "avatars: owner delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND
    starts_with(name, auth.uid()::text)
  );
