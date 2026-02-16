python -c 'import sys; print("".join([chr(ord(c) - i) for i, c in enumerate(open("token").read().strip())]))'
