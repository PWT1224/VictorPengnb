import json
from django.core.management import call_command
from io import StringIO

# 执行 dumpdata 并捕获输出
output = StringIO()
call_command('dumpdata', stdout=output)

# 以无 BOM 的 UTF-8 编码保存文件
with open('data.json', 'w', encoding='utf-8') as f:
    f.write(output.getvalue())
    