import docx
import sys

sys.stdout.reconfigure(encoding='utf-8')
doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Final_Thesis.docx")

print("Searching for code listing headers...")
for i, para in enumerate(doc.paragraphs):
    text = para.text.strip()
    if text.startswith("File:") or text.startswith("4.") or "resource " in text or "backend " in text:
        if len(text) < 100:
            print(f"P{i}: {repr(text)}")
