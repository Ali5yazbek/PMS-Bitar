import re
import sys

def parse_jsx(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the start of the return block
    match = re.search(r'return\s*\(', content)
    if not match:
        print("No return block found.")
        return

    jsx_content = content[match.end():]
    
    # We will use a simple stack to track tags
    stack = []
    
    # Regex to match tags
    tag_pattern = re.compile(r'<\/?([a-zA-Z0-9_]+)(?:[^>]*?\/)?>')
    
    lines = content.splitlines()
    for i, line in enumerate(lines):
        for m in tag_pattern.finditer(line):
            tag_text = m.group(0)
            tag_name = m.group(1)
            
            # Skip self-closing tags and br/hr/input/img
            if tag_text.endswith('/>') or tag_name.lower() in ['br', 'hr', 'input', 'img']:
                continue
                
            if tag_text.startswith('</'):
                # Closing tag
                if not stack:
                    print(f"Line {i+1}: Found closing tag </{tag_name}> but stack is empty!")
                    continue
                    
                top = stack.pop()
                if top[0] != tag_name:
                    print(f"Line {i+1}: Expected </{top[0]}> (opened at {top[1]}), but found </{tag_name}>!")
                    stack.append(top) # Put it back
            else:
                # Opening tag
                if not tag_text.startswith('</'):
                    stack.append((tag_name, i+1))
                    
    print("\nUnclosed tags remaining in stack:")
    for tag, line in stack:
        print(f"<{tag}> opened at line {line}")

parse_jsx(sys.argv[1])
