import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx")
para = doc.paragraphs[3610]

text = para.text
print("Original:")
print(repr(text))

replacements = [
    ("[INSERT]", "Allowed"), ("[PASS/FAIL]", "PASS"),
    ("[INSERT]", "Blocked"), ("[PASS/FAIL]", "PASS")
]

for idx, (old, new) in enumerate(replacements):
    text = text.replace(old, new, 1)
    print(f"\nAfter Step {idx+1} ({old} -> {new}):")
    print(repr(text))
