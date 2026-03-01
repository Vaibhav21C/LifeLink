import string
with open('Lifelink_spec.txt', 'rb') as f:
    text = f.read().decode('utf-8', 'replace')
    out = "".join(c if c in string.printable and c not in "\r\n\b" else " " for c in text)
    print(out)
