import { type MigrationInterface, type QueryRunner } from 'typeorm';
import { createHash } from 'node:crypto';

const UNIVERSITY_SEEDS = [
  { nameTh: "จุฬาลงกรณ์มหาวิทยาลัย", aliases: ["จุฬา","CU","Chulalongkorn University"] },
  { nameTh: "มหาวิทยาลัยกรุงเทพ", aliases: [] },
  { nameTh: "มหาวิทยาลัยกรุงเทพธนบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยกรุงเทพสุวรรณภูมิ", aliases: [] },
  { nameTh: "มหาวิทยาลัยการกีฬาแห่งชาติ", aliases: [] },
  { nameTh: "มหาวิทยาลัยการจัดการและเทคโนโลยีอีสเทิร์น", aliases: [] },
  { nameTh: "มหาวิทยาลัยกาฬสินธุ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยเกริก", aliases: [] },
  { nameTh: "มหาวิทยาลัยเกษตรศาสตร์", aliases: ["มก.","KU","Kasetsart University"] },
  { nameTh: "มหาวิทยาลัยเกษมบัณฑิต", aliases: [] },
  { nameTh: "มหาวิทยาลัยขอนแก่น", aliases: ["มข.","KKU","Khon Kaen University"] },
  { nameTh: "มหาวิทยาลัยคริสเตียน", aliases: [] },
  { nameTh: "มหาวิทยาลัยเจ้าพระยา", aliases: [] },
  { nameTh: "มหาวิทยาลัยเฉลิมกาญจนา", aliases: [] },
  { nameTh: "มหาวิทยาลัยชินวัตร", aliases: [] },
  { nameTh: "มหาวิทยาลัยเชียงใหม่", aliases: ["มช.","CMU","Chiang Mai University"] },
  { nameTh: "มหาวิทยาลัยเซนต์จอห์น", aliases: [] },
  { nameTh: "มหาวิทยาลัยตาปี", aliases: [] },
  { nameTh: "มหาวิทยาลัยทักษิณ", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าธนบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีมหานคร", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลกรุงเทพ", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลตะวันออก", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลธัญบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลพระนคร", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลรัตนโกสินทร์", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา เชียงราย", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา ตาก", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา น่าน", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา พิษณุโลก", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา ลำปาง", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลล้านนา สถาบันวิจัยและฝึกอบรมการเกษตรลำปาง", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลศรีวิชัย", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลสุวรรณภูมิ", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลอีสาน", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีราชมงคลอีสาน นครราชสีมา", aliases: [] },
  { nameTh: "มหาวิทยาลัยเทคโนโลยีสุรนารี", aliases: [] },
  { nameTh: "มหาวิทยาลัยธนบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยธรรมศาสตร์", aliases: ["มธ.","TU","Thammasat University"] },
  { nameTh: "มหาวิทยาลัยธุรกิจบัณฑิตย์", aliases: [] },
  { nameTh: "มหาวิทยาลัยนครพนม", aliases: [] },
  { nameTh: "มหาวิทยาลัยนราธิวาสราชนครินทร์", aliases: [] },
  { nameTh: "มหาวิทยาลัยนเรศวร", aliases: [] },
  { nameTh: "มหาวิทยาลัยนวมินทราธิราช", aliases: [] },
  { nameTh: "มหาวิทยาลัยนอร์ท-เชียงใหม่", aliases: [] },
  { nameTh: "มหาวิทยาลัยนอร์ทกรุงเทพ", aliases: [] },
  { nameTh: "มหาวิทยาลัยนานาชาติแสตมฟอร์ด", aliases: [] },
  { nameTh: "มหาวิทยาลัยนานาชาติเอเชีย-แปซิฟิก", aliases: [] },
  { nameTh: "มหาวิทยาลัยเนชั่น", aliases: [] },
  { nameTh: "มหาวิทยาลัยบูรพา", aliases: ["มบ.","BUU","Burapha University"] },
  { nameTh: "มหาวิทยาลัยปทุมธานี", aliases: [] },
  { nameTh: "มหาวิทยาลัยพะเยา", aliases: [] },
  { nameTh: "มหาวิทยาลัยพายัพ", aliases: [] },
  { nameTh: "มหาวิทยาลัยพิษณุโลก", aliases: [] },
  { nameTh: "มหาวิทยาลัยฟาฏอนี", aliases: [] },
  { nameTh: "มหาวิทยาลัยฟาร์อีสเทอร์น", aliases: [] },
  { nameTh: "มหาวิทยาลัยภาคกลาง", aliases: [] },
  { nameTh: "มหาวิทยาลัยภาคตะวันออกเฉียงเหนือ", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหาจุฬาลงกรณราชวิทยาลัย", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหาจุฬาลงกรณราชวิทยาลัย วิทยาลัยดองกุก ชอนบอบ", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหามกุฏราชวิทยาลัย", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหามกุฏราชวิทยาลัย มหาปชาบดีเถรีวิทยาลัย ในพระสังฆราชูปถัมภ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหามกุฏราชวิทยาลัย วิทยาลัยศาสนศาสตร์เฉลิมพระเกียรติกาฬสินธุ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหามกุฏราชวิทยาลัย วิทยาลัยศาสนศาสตร์ยโสธร", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหาสารคาม", aliases: [] },
  { nameTh: "มหาวิทยาลัยมหิดล", aliases: ["มม.","MU","Mahidol University"] },
  { nameTh: "มหาวิทยาลัยแม่โจ้", aliases: [] },
  { nameTh: "มหาวิทยาลัยแม่ฟ้าหลวง", aliases: [] },
  { nameTh: "มหาวิทยาลัยรังสิต", aliases: [] },
  { nameTh: "มหาวิทยาลัยรัตนบัณฑิต", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชธานี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชพฤกษ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏกาญจนบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏกำแพงเพชร", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏจันทรเกษม", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏชัยภูมิ", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏเชียงราย", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏเชียงใหม่", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏเทพสตรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏธนบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏนครปฐม", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏนครราชสีมา", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏนครศรีธรรมราช", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏนครสวรรค์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏบ้านสมเด็จเจ้าพระยา", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏบุรีรัมย์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏพระนคร", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏพระนครศรีอยุธยา", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏพิบูลสงคราม", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏเพชรบุรี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏเพชรบูรณ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏภูเก็ต", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏมหาสารคาม", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏยะลา", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏร้อยเอ็ด", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏราชนครินทร์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏรำไพพรรณี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏลำปาง", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏเลย", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏวไลยอลงกรณ์ ในพระบรมราชูปถัมภ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏศรีสะเกษ", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏสกลนคร", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏสงขลา", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏสวนสุนันทา", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏสุราษฎร์ธานี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏสุรินทร์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏหมู่บ้านจอมบึง", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏอุดรธานี", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏอุตรดิตถ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยราชภัฏอุบลราชธานี", aliases: [] },
  { nameTh: "มหาวิทยาลัยรามคำแหง", aliases: [] },
  { nameTh: "มหาวิทยาลัยวงษ์ชวลิตกุล", aliases: [] },
  { nameTh: "มหาวิทยาลัยวลัยลักษณ์", aliases: [] },
  { nameTh: "มหาวิทยาลัยเว็บสเตอร์ (ประเทศไทย)", aliases: [] },
  { nameTh: "มหาวิทยาลัยเวสเทิร์น", aliases: [] },
  { nameTh: "มหาวิทยาลัยศรีนครินทรวิโรฒ", aliases: ["มศว","SWU","Srinakharinwirot University"] },
  { nameTh: "มหาวิทยาลัยศรีปทุม", aliases: [] },
  { nameTh: "มหาวิทยาลัยศิลปากร", aliases: ["มศก.","SU","Silpakorn University"] },
  { nameTh: "มหาวิทยาลัยสงขลานครินทร์", aliases: ["ม.อ.","PSU","Prince of Songkla University"] },
  { nameTh: "มหาวิทยาลัยสยาม", aliases: [] },
  { nameTh: "มหาวิทยาลัยสวนดุสิต", aliases: [] },
  { nameTh: "มหาวิทยาลัยสุโขทัยธรรมาธิราช", aliases: [] },
  { nameTh: "มหาวิทยาลัยหอการค้าไทย", aliases: [] },
  { nameTh: "มหาวิทยาลัยหัวเฉียวเฉลิมพระเกียรติ", aliases: [] },
  { nameTh: "มหาวิทยาลัยหาดใหญ่", aliases: [] },
  { nameTh: "มหาวิทยาลัยอัสสัมชัญ", aliases: [] },
  { nameTh: "มหาวิทยาลัยอีสเทิร์นเอเชีย", aliases: [] },
  { nameTh: "มหาวิทยาลัยอุบลราชธานี", aliases: [] },
  { nameTh: "มหาวิทยาลัยเอเชียอาคเนย์", aliases: [] },
  { nameTh: "ราชวิทยาลัยจุฬาภรณ์", aliases: [] },
  { nameTh: "โรงเรียนนายร้อยตำรวจ", aliases: [] },
  { nameTh: "โรงเรียนนายร้อยพระจุลจอมเกล้า", aliases: [] },
  { nameTh: "โรงเรียนนายเรือ", aliases: [] },
  { nameTh: "โรงเรียนนายเรืออากาศ", aliases: [] },
  { nameTh: "โรงเรียนเสนาธิการทหารบก", aliases: [] },
  { nameTh: "วิทยาลัยการชลประทาน", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร ขอนแก่น", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร ชลบุรี", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร ตรัง", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร พิษณุโลก", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร ยะลา", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร สุพรรณบุรี", aliases: [] },
  { nameTh: "วิทยาลัยการสาธารณสุขสิรินธร อุบลราชธานี", aliases: [] },
  { nameTh: "วิทยาลัยเฉลิมกาญจนา", aliases: [] },
  { nameTh: "วิทยาลัยเฉลิมกาญจนาระยอง", aliases: [] },
  { nameTh: "วิทยาลัยชุมขนสระแก้ว", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนตราด", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนตาก", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนนราธิวาส", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนน่าน", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนบุรีรัมย์", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนปัตตานี", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนพังงา", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนพิจิตร", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนแพร่", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนมุกดาหาร", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนแม่ฮ่องสอน", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนยโสธร", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนยะลา", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนระนอง", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนสงขลา", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนสตูล", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนสมุทรสาคร", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนหนองบัวลำภู", aliases: [] },
  { nameTh: "วิทยาลัยชุมชนอุทัยธานี", aliases: [] },
  { nameTh: "วิทยาลัยเชียงราย", aliases: [] },
  { nameTh: "วิทยาลัยเซนต์หลุยส์", aliases: [] },
  { nameTh: "วิทยาลัยเซาธ์อีสท์บางกอก", aliases: [] },
  { nameTh: "วิทยาลัยดุสิตธานี", aliases: [] },
  { nameTh: "วิทยาลัยทองสุข", aliases: [] },
  { nameTh: "วิทยาลัยเทคโนโลยีจิตรลดา", aliases: [] },
  { nameTh: "วิทยาลัยเทคโนโลยีทางการแพทย์และสาธารณสุข กาญจนาภิเษก", aliases: [] },
  { nameTh: "วิทยาลัยเทคโนโลยีพนมวันท์", aliases: [] },
  { nameTh: "วิทยาลัยเทคโนโลยีภาคใต้", aliases: [] },
  { nameTh: "วิทยาลัยเทคโนโลยีสยาม", aliases: [] },
  { nameTh: "วิทยาลัยนครราชสีมา", aliases: [] },
  { nameTh: "วิทยาลัยนอร์ทเทิร์น", aliases: [] },
  { nameTh: "วิทยาลัยนานาชาติเซนต์เทเรซา", aliases: [] },
  { nameTh: "วิทยาลัยนานาชาติราฟเฟิลส์", aliases: [] },
  { nameTh: "วิทยาลัยบัณฑิตเอเชีย", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลกองทัพบก", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลกองทัพเรือ", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลเกื้อการุณย์", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลตำรวจ", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลทหารอากาศ", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี กรุงเทพ", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี ขอนแก่น", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี จักรีรัช", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี ชลบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี ชัยนาท", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี เชียงใหม่", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี ตรัง", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี นครราชสีมา", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี นครลำปาง", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี นครศรีธรรมราช", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี นนทบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี นพรัตน์วชิระ", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี พระพุทธบาท", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี พะเยา", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี พุทธชินราช", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี แพร่", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี ยะลา", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี ราชบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สงขลา", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สรรพสิทธิประสงค์ อุบลราชธานี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สระบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สวรรค์ประชารักษ์", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สุพรรณบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สุราษฎร์ธานี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี สุรินทร์", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี อุดรธานี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลบรมราชชนนี อุตรดิตถ์", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลพระจอมเกล้า เพชรบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลพระปกเกล้า จันทบุรี", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลศรีมหาสารคาม", aliases: [] },
  { nameTh: "วิทยาลัยพยาบาลสรรพสิทธิประสงค์ อุบลราชธานี", aliases: [] },
  { nameTh: "วิทยาลัยพิชญบัณฑิต", aliases: [] },
  { nameTh: "วิทยาลัยพุทธศาสนานานาชาติ", aliases: [] },
  { nameTh: "วิทยาลัยแพทยศาสตร์กรุงเทพมหานครและวชิรพยาบาล", aliases: [] },
  { nameTh: "วิทยาลัยแพทยศาสตร์พระมงกุฎเกล้า", aliases: [] },
  { nameTh: "วิทยาลัยสันตพล", aliases: [] },
  { nameTh: "วิทยาลัยแสงธรรม", aliases: [] },
  { nameTh: "วิทยาลัยอินเตอร์เทคลำปาง", aliases: [] },
  { nameTh: "ศูนย์การศึกษามหาวิทยาลัยธนบุรี วิทยาลัยเทคโนโลยีหมู่บ้านครูภาคเหนือ จังหวัดลำพูน", aliases: [] },
  { nameTh: "ศูนย์ฝึกพาณิชย์นาวี", aliases: [] },
  { nameTh: "สถาบันกันตนา", aliases: [] },
  { nameTh: "สถาบันการจัดการปัญญาภิวัฒน์", aliases: [] },
  { nameTh: "สถาบันการบินพลเรือน", aliases: [] },
  { nameTh: "สถาบันการพยาบาลศรีสวรินทิรา สภากาชาดไทย", aliases: [] },
  { nameTh: "สถาบันการเรียนรู้เพื่อปวงชน", aliases: [] },
  { nameTh: "สถาบันดนตรีกัลยาณิวัฒนา", aliases: [] },
  { nameTh: "สถาบันเทคโนโลยีไทย-ญี่ปุ่น", aliases: [] },
  { nameTh: "สถาบันเทคโนโลยีปทุมวัน", aliases: [] },
  { nameTh: "สถาบันเทคโนโลยีพระจอมเกล้าเจ้าคุณหทารลาดกระบัง", aliases: [] },
  { nameTh: "สถาบันเทคโนโลยียานยนต์มหาชัย", aliases: [] },
  { nameTh: "สถาบันเทคโนโลยีแห่งสุวรรณภูมิ", aliases: [] },
  { nameTh: "สถาบันบัณฑิตพัฒนบริหารศาสตร์", aliases: [] },
  { nameTh: "สถาบันบัณฑิตพัฒนศิลป์", aliases: [] },
  { nameTh: "สถาบันพระบรมราชชนก", aliases: [] },
  { nameTh: "สถาบันรัชต์ภาคย์", aliases: [] },
  { nameTh: "สถาบันวิทยสิริเมธี", aliases: [] },
  { nameTh: "สถาบันวิทยาการจัดการแห่งแปซิฟิค", aliases: [] },
  { nameTh: "สถาบันวิทยาการประกอบการแห่งอโยธยา", aliases: [] },
  { nameTh: "สถาบันวิทยาลัยชุมชน", aliases: [] },
  { nameTh: "สถาบันอาศรมศิลป์", aliases: [] },
];

function universityId(nameTh: string): string {
  const bytes = createHash('sha256').update(`internfinder:university:${nameTh}`).digest().subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export class AddStudentUniversityMaster1791244800000 implements MigrationInterface {
  name = 'AddStudentUniversityMaster1791244800000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "universities" (
        "id" uuid PRIMARY KEY,
        "name_th" varchar(255) NOT NULL UNIQUE,
        "aliases" text[] NOT NULL DEFAULT '{}'
      )
    `);
    for (const university of UNIVERSITY_SEEDS) {
      await queryRunner.query(
        'INSERT INTO "universities" ("id", "name_th", "aliases") VALUES ($1, $2, $3)',
        [universityId(university.nameTh), university.nameTh, university.aliases],
      );
    }

    await queryRunner.query('ALTER TABLE "student_profiles" ADD COLUMN "university_id" uuid');
    await queryRunner.query('ALTER TABLE "student_profiles" ADD COLUMN "custom_university_name" varchar(255)');
    await queryRunner.query(`
      ALTER TABLE "student_profiles"
      ADD CONSTRAINT "FK_student_profiles_university"
      FOREIGN KEY ("university_id") REFERENCES "universities" ("id") ON DELETE RESTRICT
    `);
    await queryRunner.query(`
      ALTER TABLE "student_profiles"
      ADD CONSTRAINT "CHK_student_profiles_university_choice"
      CHECK ("university_id" IS NULL OR "custom_university_name" IS NULL)
    `);
    await queryRunner.query('CREATE INDEX "IDX_student_profiles_university_id" ON "student_profiles" ("university_id")');

    await queryRunner.query(`
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM "student_profiles" WHERE length(btrim("university")) > 255) THEN
          RAISE EXCEPTION 'Cannot migrate student university values longer than 255 characters';
        END IF;
      END $$
    `);
    await queryRunner.query(`
      WITH normalized AS (
        SELECT profile."id" AS profile_id,
               regexp_replace(lower(btrim(profile."university")), '[[:space:].]+', '', 'g') AS value
        FROM "student_profiles" AS profile
      ), matches AS (
        SELECT normalized.profile_id, min(university."id"::text)::uuid AS university_id, count(DISTINCT university."id") AS match_count
        FROM normalized
        JOIN "universities" AS university
          ON regexp_replace(lower(university."name_th"), '[[:space:].]+', '', 'g') = normalized.value
          OR EXISTS (
            SELECT 1 FROM unnest(university."aliases") alias
            WHERE regexp_replace(lower(alias), '[[:space:].]+', '', 'g') = normalized.value
          )
        WHERE normalized.value <> ''
        GROUP BY normalized.profile_id
      )
      UPDATE "student_profiles" profile
      SET "university_id" = CASE WHEN matches.match_count = 1 THEN matches.university_id ELSE NULL END,
          "custom_university_name" = CASE
            WHEN btrim(profile."university") = '' THEN NULL
            WHEN matches.match_count = 1 THEN NULL
            ELSE btrim(profile."university")
          END
      FROM normalized
      LEFT JOIN matches ON matches.profile_id = normalized.profile_id
      WHERE profile."id" = normalized.profile_id
    `);
    await queryRunner.query('ALTER TABLE "student_profiles" DROP COLUMN "university"');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "student_profiles" ADD COLUMN "university" varchar(255) NOT NULL DEFAULT \'\'');
    await queryRunner.query(`
      UPDATE "student_profiles" profile
      SET "university" = COALESCE(university."name_th", profile."custom_university_name", '')
      FROM "universities" university
      WHERE profile."university_id" = university."id"
    `);
    await queryRunner.query(`
      UPDATE "student_profiles"
      SET "university" = COALESCE("custom_university_name", '')
      WHERE "university_id" IS NULL
    `);
    await queryRunner.query('ALTER TABLE "student_profiles" DROP CONSTRAINT "CHK_student_profiles_university_choice"');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP CONSTRAINT "FK_student_profiles_university"');
    await queryRunner.query('DROP INDEX "IDX_student_profiles_university_id"');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP COLUMN "custom_university_name"');
    await queryRunner.query('ALTER TABLE "student_profiles" DROP COLUMN "university_id"');
    await queryRunner.query('DROP TABLE "universities"');
  }
}
