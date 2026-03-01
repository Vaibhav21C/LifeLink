with open('Lifelink_spec.txt', 'rb') as f:
    text = f.read().decode('utf-8', 'replace')
    for line in text.splitlines():
        print(repr(line))
