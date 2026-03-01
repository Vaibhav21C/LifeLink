with open('Lifelink_spec.txt', 'rb') as f:
    text = f.read().decode('utf-8', 'replace').replace('\r', '\n')
    print(text)
