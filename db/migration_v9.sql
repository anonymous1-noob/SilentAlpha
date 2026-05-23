-- SilentAlpha Migration v9
-- Raise post content character limit from 500 to 2000

ALTER TABLE posts DROP CONSTRAINT posts_content_check;
ALTER TABLE posts ADD CONSTRAINT posts_content_check CHECK (char_length(content) <= 2000);
