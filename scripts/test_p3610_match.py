import docx

doc = docx.Document("../Ugwulebo_Lesile_Ngozi_MIT_AWS_GCP_Updated_Network(3).docx")
para = doc.paragraphs[3610]
clean_text = " ".join(para.text.split())

print("Clean text of P3610:")
print(repr(clean_text))

print("\nEvaluating checks:")
print("- 'ST-' in clean_text:", "ST-" in clean_text)
print("- '08' in clean_text:", "08" in clean_text)
print("- '09' in clean_text:", "09" in clean_text)
print("- '08' in clean_text and '09' in clean_text:", "08" in clean_text and "09" in clean_text)
