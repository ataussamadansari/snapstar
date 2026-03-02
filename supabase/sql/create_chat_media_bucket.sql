-- ============================================
-- CREATE CHAT MEDIA STORAGE BUCKET
-- ============================================

-- Create the chat-media bucket for storing chat images and videos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-media',
  'chat-media',
  true,
  52428800, -- 50MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime', 'video/x-msvideo']
)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for chat-media bucket
-- Policy: Allow authenticated users to upload their own files
CREATE POLICY "Users can upload chat media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow authenticated users to read all chat media
CREATE POLICY "Users can view chat media"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'chat-media');

-- Policy: Allow users to update their own files
CREATE POLICY "Users can update their own chat media"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'chat-media' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow users to delete their own files
CREATE POLICY "Users can delete their own chat media"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat-media' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

SELECT 'Chat media bucket created successfully!' AS status;
