import string
with open('Lifelink_spec.txt', 'rb') as f:
    text = f.read()

# filter out everything but printable ascii and basic newlines
out = bytearray(b for b in text if b in text and (b < 128))
with open('Lifelink_spec_clean.txt', 'wb') as f2:
    f2.write(out)
