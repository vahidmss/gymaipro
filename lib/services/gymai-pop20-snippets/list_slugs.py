# -*- coding: utf-8 -*-
import re
import glob
import os

BASE = os.path.dirname(os.path.abspath(__file__))
slugs = set()
for f in glob.glob(os.path.join(BASE, "pop20-batch*.php")):
    t = open(f, encoding="utf-8").read()
    for m in re.finditer(r"'slug' => '([^']+)'", t):
        slugs.add(m.group(1))

BLOCKLIST = {
    'دیپ-پارالل', 'هایپراکستنشن-فیله-کمر', 'پلانک-plank', 'پلانک', 'پرس-پا-دستگاه',
    'جلوبازو-دمبل-نشسته', 'زیربغل-سیمکش-دست-باز', 'ددلیفت-رومانیایی', 'زیربغل-هالتر-خمیده',
    'پرس-سینه-دستگاه', 'پشت-پا-دستگاه', 'پشت-بازو-سیمکش', 'نشر-جانب-دمبل', 'اسکات-هالتر',
    'پرس-سرشانه-دستگاه',
}
all_taken = slugs | BLOCKLIST
print("existing", len(slugs), "blocklist", len(BLOCKLIST), "total", len(all_taken))
with open(os.path.join(BASE, "existing_slugs.txt"), "w", encoding="utf-8") as wf:
    wf.write("\n".join(sorted(all_taken)))
