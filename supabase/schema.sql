-- โครงฐานข้อมูลของ Lapse
--
-- วางทั้งไฟล์นี้ใน SQL Editor ของ Supabase แล้วกด Run ครั้งเดียว
-- รันซ้ำได้โดยไม่พัง ทุกคำสั่งเป็น idempotent
--
-- หลักการที่โครงนี้ยึด
--
-- §2.6 บอกว่า "เมตาที่แชร์กับเพื่อนคือนาทีต่อวันเท่านั้น เนื้อหาในไฟล์ไม่เคยถูกแชร์"
-- เราจึงแยกเป็นสองตารางแทนที่จะใช้ตารางเดียวแล้วคุมด้วยนโยบาย
-- ถ้าเขียนนโยบายผิดบรรทัดเดียวบนตารางเดียว เนื้อหาของผู้ใช้จะรั่วทันที
-- แยกตารางแล้วเนื้อหาไม่ได้อยู่ในที่ที่เพื่อนอ่านได้ตั้งแต่ต้น
-- ความปลอดภัยมาจากโครงสร้าง ไม่ใช่จากความระมัดระวัง

-- ---------------------------------------------------------------- profiles

create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  handle     text unique not null check (handle ~ '^@[a-z0-9_]{2,20}$'),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- ต้องค้น handle ของคนอื่นได้ ไม่งั้นเพิ่มเพื่อนไม่ได้
-- โปรไฟล์มีแค่ handle ไม่มีอย่างอื่นให้รั่ว
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_write_own on public.profiles;
create policy profiles_write_own on public.profiles
  for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ------------------------------------------------------------------- days
-- เนื้อหาไฟล์รายวัน · เจ้าของเท่านั้นที่แตะได้ ไม่มีข้อยกเว้น

create table if not exists public.days (
  user_id    uuid not null references auth.users on delete cascade,
  day        date not null,
  content    text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

alter table public.days enable row level security;

drop policy if exists days_own_only on public.days;
create policy days_own_only on public.days
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------- friends
-- เส้นทางเดียว · ฉันเพิ่มเขา ไม่ได้แปลว่าเขาเพิ่มฉัน
-- ไม่มีการขออนุญาต ไม่มีการตอบรับ เพราะสิ่งที่เห็นได้คือเวลาเท่านั้น

create table if not exists public.friends (
  user_id    uuid not null references auth.users on delete cascade,
  friend_id  uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  constraint friends_not_self check (user_id <> friend_id)
);

alter table public.friends enable row level security;

drop policy if exists friends_own_only on public.friends;
create policy friends_own_only on public.friends
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- §4.4 จำกัดเพื่อนที่ 30 คน · ความหายากทำให้มันเป็นวงเพื่อนจริง ไม่ใช่ผู้ติดตาม
-- บังคับที่ฐานข้อมูล ไม่ใช่ที่แอป เพราะแอปแก้ได้แต่ฐานข้อมูลแก้ไม่ได้
create or replace function public.enforce_friend_limit()
returns trigger language plpgsql security definer as $$
begin
  if (select count(*) from public.friends where user_id = new.user_id) >= 30 then
    raise exception 'เพิ่มเพื่อนได้สูงสุด 30 คน';
  end if;
  return new;
end $$;

drop trigger if exists friends_limit on public.friends;
create trigger friends_limit
  before insert on public.friends
  for each row execute function public.enforce_friend_limit();

-- ------------------------------------------------------------- day_totals
-- วินาทีต่อวัน · นี่คือสิ่งเดียวที่เพื่อนเห็น

create table if not exists public.day_totals (
  user_id uuid not null references auth.users on delete cascade,
  day     date not null,
  seconds integer not null default 0 check (seconds >= 0),
  primary key (user_id, day)
);

alter table public.day_totals enable row level security;

drop policy if exists day_totals_write_own on public.day_totals;
create policy day_totals_write_own on public.day_totals
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- อ่านของตัวเองได้ และอ่านของคนที่ตัวเองเพิ่มเป็นเพื่อนไว้ได้
drop policy if exists day_totals_read_friends on public.day_totals;
create policy day_totals_read_friends on public.day_totals
  for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.friends f
      where f.user_id = auth.uid() and f.friend_id = day_totals.user_id
    )
  );

-- ------------------------------------------------------------ อัปเดตเวลา
-- ตัวซิงก์ใช้ updated_at ตัดสินว่าชนกันหรือเปล่า จึงต้องเชื่อถือได้
-- ปล่อยให้ไคลเอนต์ส่งมาเองไม่ได้ นาฬิกาของเครื่องเดินไม่ตรงกัน

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists days_touch on public.days;
create trigger days_touch
  before insert or update on public.days
  for each row execute function public.touch_updated_at();
