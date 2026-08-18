/// ที่อยู่และคีย์สาธารณะของเซิร์ฟเวอร์
///
/// คีย์นี้ตั้งใจให้เปิดเผยได้ มันฝังอยู่ในไฟล์แอปที่ส่งขึ้นสโตร์อยู่แล้ว
/// ใครแกะแอปก็เห็น การเก็บเป็นความลับจึงไม่ได้ให้ความปลอดภัยอะไรเพิ่ม
///
/// การป้องกันจริงทั้งหมดอยู่ที่ Row Level Security ฝั่งเซิร์ฟเวอร์
/// (ดู `supabase/schema.sql`) ซึ่งทดสอบแล้วว่าปฏิเสธการเขียนโดยไม่ล็อกอินจริง
///
/// สิ่งที่ห้ามอยู่ในไฟล์นี้เด็ดขาดคือ service_role หรือ secret key
/// เพราะมันข้าม RLS ได้ทุกกฎ
library;

class SupabaseConfig {
  const SupabaseConfig._();

  static const url = 'https://pquvqxqmfcgamutnqwzn.supabase.co';
  static const publishableKey =
      'sb_publishable_UYVoqoivIbUzSO1jLRIW_w_DVKc7hoV';
}
