-- تست تابع add_chat_message

-- ابتدا یک session ایجاد کن
INSERT INTO ai_chat_sessions (user_id, title, messages, message_count)
VALUES (
    'accb0113-33f7-43ac-a1b5-c5e03be1ed58', 
    'تست چت', 
    '[]'::jsonb, 
    0
);

-- حالا تابع add_chat_message رو تست کن
SELECT add_chat_message(
    (SELECT id FROM ai_chat_sessions WHERE title = 'تست چت' LIMIT 1),
    'سلام تست',
    'user',
    0,
    'test'
);

-- چک کن که پیام اضافه شده
SELECT messages, message_count FROM ai_chat_sessions WHERE title = 'تست چت';
