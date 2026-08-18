/// ชื่อวันและเดือนภาษาไทย
///
/// ปีใช้คริสต์ศักราชตามโปรโตไทป์ ไม่ใช่พุทธศักราช — ผลิตภัณฑ์ตั้งใจขยายออก
/// ต่างประเทศตั้งแต่แรก และวันที่ในชื่อไฟล์ก็เป็น ค.ศ. อยู่แล้ว
/// การให้หน้าจอกับไฟล์ตรงกันสำคัญกว่าความคุ้นเคยในประเทศเดียว
library;

const _monthsFull = [
  'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

const _monthsShort = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

const _weekdays = [
  'อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์',
];

/// ตัวพิมพ์เล็กทั้งหมดตามกฎน้ำเสียงใน CLAUDE.md
///
/// ภาษาอังกฤษปกติเขียนชื่อเดือนกับวันด้วยตัวใหญ่ แต่กฎของโปรเจกต์นี้
/// บอกให้ใช้ตัวเล็กกับข้อความอังกฤษทั้งหมด และการยกเว้นตรงนี้จะทำให้
/// หัววันดังกว่าทุกอย่างอื่นบนจอในแอปที่ทั้งตัวพยายามเงียบ
const _monthsFullEn = [
  'january', 'february', 'march', 'april', 'may', 'june',
  'july', 'august', 'september', 'october', 'november', 'december',
];

const _monthsShortEn = [
  'jan', 'feb', 'mar', 'apr', 'may', 'jun',
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
];

const _weekdaysEn = [
  'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday',
];

/// `18 สิงหาคม` หรือ `18 August` — บรรทัดหลักของหัววัน ไม่มีปี
String dayAndMonth(DateTime d, {required bool thai}) =>
    '${d.day} ${(thai ? _monthsFull : _monthsFullEn)[d.month - 1]}';

/// `ส.ค.` หรือ `Aug` — ป้ายเดือนบนกำแพง
String monthShort(int month, {required bool thai}) =>
    (thai ? _monthsShort : _monthsShortEn)[month - 1];

/// `อังคาร · 2026` หรือ `Tuesday · 2026` — บรรทัดรองของหัววัน
String weekdayAndYear(DateTime d, {required bool thai}) =>
    '${(thai ? _weekdays : _weekdaysEn)[sundayFirstWeekday(d)]} · ${d.year}';

/// `18 สิงหาคม` — บรรทัดหลักของหัววัน ไม่มีปี
String thaiDayAndMonth(DateTime d) => '${d.day} ${_monthsFull[d.month - 1]}';

/// `ส.ค.` — ป้ายเดือนบนกำแพง
String thaiMonthShort(int month) => _monthsShort[month - 1];

/// `อังคาร` — ชื่อวันในสัปดาห์
///
/// `DateTime.weekday` ให้จันทร์=1 ถึงอาทิตย์=7 แต่กำแพงเริ่มจากวันอาทิตย์
/// จึงแปลงเป็นอาทิตย์=0 ให้ตรงกันทั้งแอป
String thaiWeekday(DateTime d) => _weekdays[sundayFirstWeekday(d)];

/// อาทิตย์=0 ถึงเสาร์=6 — ดัชนีแถวของกำแพง (§4.4)
int sundayFirstWeekday(DateTime d) => d.weekday % 7;

/// `อังคาร · 2026` — บรรทัดรองของหัววัน
String thaiWeekdayAndYear(DateTime d) => '${thaiWeekday(d)} · ${d.year}';
