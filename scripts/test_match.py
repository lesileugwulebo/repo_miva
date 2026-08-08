import docx
import re

d2 = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Final_Thesis.docx")
pattern = re.compile(r"\[[A-Za-z0-9_/ -]{3,}\]")

text = d2.paragraphs[3653].text
print("Text of P3653 in final doc:", repr(text))
matches = pattern.findall(text)
print("Matches found in P3653:", matches)
