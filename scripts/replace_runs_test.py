import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx")

# Test paragraph 3541
para = doc.paragraphs[3541]
print("Paragraph text:", para.text)
print("Runs:")
for i, run in enumerate(para.runs):
    print(f"- Run {i}: '{run.text}'")
