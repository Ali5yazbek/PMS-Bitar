import sys
data = open('src/pages/TenantDetails.jsx', encoding='utf-8').read()
start = data.find('return (')
if start == -1:
    print("No return block")
    sys.exit()

lines = data[start:].splitlines()
cb = 0
cp = 0
for i, l in enumerate(lines):
    cb += l.count('{') - l.count('}')
    cp += l.count('(') - l.count(')')
    if l.count('{') != l.count('}') or l.count('(') != l.count(')'):
        print(f"L{i+385}: cb={cb} cp={cp} | {l.strip()[:60]}")
