import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx")

print("Searching for Figure 5 headings or anchors...")
for i, para in enumerate(doc.paragraphs):
    if "Figure 5." in para.text or "figure 5." in para.text or "Figure 5-" in para.text:
        print(f"P{i}: {para.text}")
