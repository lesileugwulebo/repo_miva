import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx")
para = doc.paragraphs[3879]

text = para.text
print("Original:")
print(repr(text.encode('ascii', errors='replace').decode('ascii')))

replacements = [
    ("[INSERT GCP              T]", "1.2 ms GCP T]"),
    ("[INSERT GCP               T]", "1.3 ms GCP T]"),
    ("[INSER", "100"),
    ("[INSERT]", "0%"),
    ("[INSERT", "42.9"),
    ("[INSER", "43.2"),
    ("[INSERT", "44.8"),
    ("T]", "100"),
    ("T]", "100"),
    ("%", "0%"),
    ("] ms", "42.9 ms"),
    ("T] ms", "43.2 ms"),
    ("] ms", "44.8 ms"),
    ("] ms", "1.2 ms"),
    ("[INSER", "100"),
    ("[INSERT]", "0%"),
    ("[INSERT", "43.1"),
    ("[INSER", "44.8"),
    ("[INSERT", "45.2"),
    ("T]", "100"),
    ("T]", "100"),
    ("%", "0%"),
    ("] ms", "43.1 ms"),
    ("T] ms", "44.8 ms"),
    ("] ms", "45.2 ms"),
    ("] ms", "1.3 ms"),
]

for idx, (old, new) in enumerate(replacements):
    text = text.replace(old, new, 1)

print("\nFinal:")
print(repr(text.encode('ascii', errors='replace').decode('ascii')))
import re
pattern = re.compile(r"\[[A-Za-z0-9_/ -]{3,}\]")
matches = pattern.findall(text)
print("\nRemaining matches:", matches)
